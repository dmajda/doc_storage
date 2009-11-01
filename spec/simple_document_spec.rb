require File.dirname(__FILE__) + "/../lib/doc_storage"

module DocStorage
  describe SimpleDocument do
    Spec::Matchers.define :parse_as_document do |document|
      match do |string|
        SimpleDocument.parse(string) == document
      end
    end

    before :each do
      @document = SimpleDocument.new({"a" => 42, "b" => 43}, "body")

      @document_without_headers_without_body = SimpleDocument.new({}, "")
      @document_without_headers_with_body = SimpleDocument.new({}, "line1\nline2")
      @document_with_headers_without_body = SimpleDocument.new(
        {"a" => "42", "b" => "43"},
        ""
      )
      @document_with_headers_with_body = SimpleDocument.new(
        {"a" => "42", "b" => "43"},
        "line1\nline2"
      )
    end

    describe "initialize" do
      it "sets attributes correctly" do
        @document.headers.should == {"a" => 42, "b" => 43}
        @document.body.should == "body"
      end
    end

    describe "==" do
      it "returns true when passed the same object" do
        @document.should == @document
      end

      it "returns true when passed a SimpleDocument initialized with the same parameters" do
        @document.should == SimpleDocument.new({"a" => 42, "b" => 43}, "body")
      end

      it "returns false when passed some random object" do
        @document.should_not == Object.new
      end

      it "returns false when passed a subclass of SimpleDocument initialized with the same parameters" do
        class SubclassedSimpleDocument < SimpleDocument
        end

        @document.should_not ==
          SubclassedSimpleDocument.new({"a" => 42, "b" => 43}, "body")
      end

      it "returns false when passed a SimpleDocument initialized with different parameters" do
        @document.should_not == SimpleDocument.new({"a" => 44, "b" => 45}, "body")
        @document.should_not == SimpleDocument.new({"a" => 42, "b" => 43}, "nobody")
      end
    end

    describe "parse" do
      it "parses document with no headers and no body" do
        "\n".should parse_as_document(@document_without_headers_without_body)
      end

      it "parses document with no headers and body" do
        "\nline1\nline2".should parse_as_document(
          @document_without_headers_with_body
        )
      end

      it "parses document with headers and no body" do
        "a: 42\nb: 43\n\n".should parse_as_document(
          @document_with_headers_without_body
        )
      end

      it "parses document with headers and body" do
        "a: 42\nb: 43\n\nline1\nline2".should parse_as_document(
          @document_with_headers_with_body
        )
      end

      it "does not parse document with invalid headers" do
        lambda {
          SimpleDocument.parse("bullshit")
        }.should raise_error(SyntaxError, "Invalid header: \"bullshit\".")
      end

      it "does not parse document with unterminated headers" do
        lambda {
          SimpleDocument.parse("a: 42\nb: 42\n")
        }.should raise_error(SyntaxError, "Unterminated headers.")
      end

      it "parses document from IO-like object" do
        StringIO.open("a: 42\nb: 43\n\nline1\nline2") do |io|
          SimpleDocument.parse(io).should == @document_with_headers_with_body
        end
      end

      it "parses document when detecting a boundary" do
        SimpleDocument.parse(
          "a: 42\nb: 43\nBoundary: =====\n\nline1\nline2\n--=====\nbullshit",
          :detect
        ).should == SimpleDocument.new(
          {"a" => "42", "b" => "43", "Boundary" => "====="},
          "line1\nline2"
        )
      end

      it "does not parse document when detecting a boundary and no boundary defined" do
        lambda {
          SimpleDocument.parse(
            "a: 42\nb: 43\n\nline1\nline2\n--=====\nbullshit",
            :detect
          )
        }.should raise_error(SyntaxError, "No boundary defined.")
      end

      it "parses document when passed a boundary" do
        SimpleDocument.parse(
          "a: 42\nb: 43\n\nline1\nline2\n--=====\nbullshit",
          "====="
        ).should == @document_with_headers_with_body
      end
    end

    describe "to_s" do
      it "serializes document with no headers and no body" do
        @document_without_headers_without_body.to_s.should == "\n"
      end

      it "serializes document with no headers and body" do
        @document_without_headers_with_body.to_s.should == "\nline1\nline2"
      end

      it "serializes document with headers and no body" do
        @document_with_headers_without_body.to_s.should == "a: 42\nb: 43\n\n"
      end

      it "serializes document with headers and body" do
        @document_with_headers_with_body.to_s.should ==
          "a: 42\nb: 43\n\nline1\nline2"
      end
    end
  end
end
