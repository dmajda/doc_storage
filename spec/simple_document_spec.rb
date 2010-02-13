require "tempfile"

require File.dirname(__FILE__) + "/../lib/doc_storage"

module DocStorage
  describe SimpleDocument do
    SIMPLE_FIXTURE_FILE = File.dirname(__FILE__) + "/fixtures/simple.txt"

    Spec::Matchers.define :load_as_document do |document|
      match do |string|
        SimpleDocument.load(string) == document
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

    describe "load" do
      it "loads document with no headers and no body" do
        "\n".should load_as_document(@document_without_headers_without_body)
      end

      it "loads document with no headers and body" do
        "\nline1\nline2".should load_as_document(
          @document_without_headers_with_body
        )
      end

      it "loads document with headers and no body" do
        "a: 42\nb: 43\n\n".should load_as_document(
          @document_with_headers_without_body
        )
      end

      it "loads document with headers and body" do
        "a: 42\nb: 43\n\nline1\nline2".should load_as_document(
          @document_with_headers_with_body
        )
      end

      it "loads document with no whitespace after the colon in headers" do
        "a:42\nb:43\n\n".should load_as_document(
          @document_with_headers_without_body
        )
      end

      it "loads document with multiple whitespace after the colon in headers" do
        "a: \t 42\nb: \t 43\n\n".should load_as_document(
          @document_with_headers_without_body
        )
      end

      it "does not load document with invalid headers" do
        lambda {
          SimpleDocument.load("bullshit")
        }.should raise_error(SyntaxError, "Invalid header: \"bullshit\".")
      end

      it "does not load document with unterminated headers" do
        lambda {
          SimpleDocument.load("a: 42\nb: 42\n")
        }.should raise_error(SyntaxError, "Unterminated headers.")
      end

      it "loads document from IO-like object" do
        StringIO.open("a: 42\nb: 43\n\nline1\nline2") do |io|
          SimpleDocument.load(io).should == @document_with_headers_with_body
        end
      end

      it "loads document when detecting a boundary" do
        SimpleDocument.load(
          "a: 42\nb: 43\nBoundary: =====\n\nline1\nline2\n--=====\nbullshit",
          :detect
        ).should == SimpleDocument.new(
          {"a" => "42", "b" => "43", "Boundary" => "====="},
          "line1\nline2"
        )
      end

      it "does not load document when detecting a boundary and no boundary defined" do
        lambda {
          SimpleDocument.load(
            "a: 42\nb: 43\n\nline1\nline2\n--=====\nbullshit",
            :detect
          )
        }.should raise_error(SyntaxError, "No boundary defined.")
      end

      it "loads document when passed a boundary" do
        SimpleDocument.load(
          "a: 42\nb: 43\n\nline1\nline2\n--=====\nbullshit",
          "====="
        ).should == @document_with_headers_with_body
      end

      it "works around the IO#readline bug" do
        File.open(SIMPLE_FIXTURE_FILE, "r") do |f|
          SimpleDocument.load(f).should == @document_with_headers_with_body
        end
      end

      it "works around the IO#read bug when passed a boundary" do
        File.open(SIMPLE_FIXTURE_FILE, "r") do |f|
          SimpleDocument.load(f, "=====").should ==
            @document_with_headers_with_body
        end
      end
    end

    describe "load_file" do
      it "loads document" do
        SimpleDocument.load_file(SIMPLE_FIXTURE_FILE).should ==
          @document_with_headers_with_body
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

    describe "save" do
      it "saves document" do
        StringIO.open("", "w") do |io|
          @document_with_headers_with_body.save(io)
          io.string.should == "a: 42\nb: 43\n\nline1\nline2"
        end
      end
    end

    describe "save_file" do
      it "saves document" do
        # The "ensure" blocks aren't really necessary -- the tempfile will be
        # closed and unlinked upon its object destruction automatically. However
        # I think that being explicit and deterministic doesn't hurt.

        begin
          tempfile = Tempfile.new("doc_storage")
          tempfile.close

          @document_with_headers_with_body.save_file(tempfile.path)

          tempfile.open
          begin
            tempfile.read.should == "a: 42\nb: 43\n\nline1\nline2"
          ensure
            tempfile.close
          end
        ensure
          tempfile.unlink
        end
      end
    end
  end
end
