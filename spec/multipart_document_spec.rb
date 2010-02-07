require File.dirname(__FILE__) + "/../lib/doc_storage"

module DocStorage
  describe MultipartDocument do
    Spec::Matchers.define :parse_as_multipart_document do |document|
      match do |string|
        MultipartDocument::parse(string) == document
      end
    end

    before :each do
      @document = MultipartDocument.new([:part1, :part2])

      @document_with_no_parts = MultipartDocument.new([])
      @document_with_multiple_parts = MultipartDocument.new([
        SimpleDocument.new({"a" => "42", "b" => "43"}, "line1\nline2"),
        SimpleDocument.new({"c" => "44", "d" => "45"}, "line3\nline4"),
      ])
    end

    describe "initialize" do
      it "sets attributes correctly" do
        @document.parts.should == [:part1, :part2]
      end
    end

    describe "==" do
      it "returns true when passed the same object" do
        @document.should == @document
      end

      it "returns true when passed a MultipartDocument initialized with the same parameter" do
        @document.should == MultipartDocument.new([:part1, :part2])
      end

      it "returns false when passed some random object" do
        @document.should_not == Object.new
      end

      it "returns false when passed a subclass of MultipartDocument initialized with the same parameter" do
        class SubclassedMultipartDocument < MultipartDocument
        end

        @document.should_not ==
          SubclassedMultipartDocument.new([:part1, :part2])
      end

      it "returns false when passed a MultipartDocument initialized with different parameter" do
        @document.should_not == MultipartDocument.new([:part3, :part4])
      end
    end

    describe "parse" do
      it "parses document with no parts" do
        "Boundary: =====\n\n".should parse_as_multipart_document(
          @document_with_no_parts
        )
      end

      it "parses document with multiple parts" do
        [
          "Boundary: =====",
          "",
          "--=====",
          "a: 42",
          "b: 43",
          "",
          "line1",
          "line2",
          "--=====",
          "c: 44",
          "d: 45",
          "",
          "line3",
          "line4",
        ].join("\n").should parse_as_multipart_document(
          @document_with_multiple_parts
        )
      end

      it "does not parse document with no Boundary: header" do
        lambda {
          MultipartDocument.parse("\n\n")
        }.should raise_error(SyntaxError, "No boundary defined.")
      end

      it "parses document from IO-like object" do
        StringIO.open(
          [
            "Boundary: =====",
            "",
            "--=====",
            "a: 42",
            "b: 43",
            "",
            "line1",
            "line2",
            "--=====",
            "c: 44",
            "d: 45",
            "",
            "line3",
            "line4",
          ].join("\n")
        ) do |io|
          MultipartDocument.parse(io).should == @document_with_multiple_parts
        end
      end
    end

    describe "to_s" do
      it "serializes document with no parts" do
        srand 0
        @document_with_no_parts.to_s.should ==
          "Boundary: SV1ad7dNjtvYKxgyym6bMNxUyrLznijuZqZfpVasJyXZDttoNGbj5GFk0xJlY3CI\n\n"
      end

      it "serializes document with multiple parts" do
        srand 0
        @document_with_multiple_parts.to_s.should == [
          "Boundary: SV1ad7dNjtvYKxgyym6bMNxUyrLznijuZqZfpVasJyXZDttoNGbj5GFk0xJlY3CI",
          "",
          "--SV1ad7dNjtvYKxgyym6bMNxUyrLznijuZqZfpVasJyXZDttoNGbj5GFk0xJlY3CI",
          "a: 42",
          "b: 43",
          "",
          "line1",
          "line2",
          "--SV1ad7dNjtvYKxgyym6bMNxUyrLznijuZqZfpVasJyXZDttoNGbj5GFk0xJlY3CI",
          "c: 44",
          "d: 45",
          "",
          "line3",
          "line4",
        ].join("\n")
      end
    end
  end
end
