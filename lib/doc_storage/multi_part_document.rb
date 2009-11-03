module DocStorage
  # The +MultiPartDocument+ class represents a document consisting of several
  # simple documents (see the +SimpleDocument+ class documentation for a
  # description), loosely based on the MIME multipart message format. It is
  # suitable for storing multiple documents containing a text associated with
  # some metadata (e.g. blog comments, each with an author and a publication
  # date). The +MultiPartDocument+ class allows to create the document
  # programatically, parse it from a file, manipulate its structure and save it
  # to a file.
  #
  # == Document Format
  #
  # In serialized form, a multipart document looks like this:
  #
  #   Boundary: =====
  #
  #   --=====
  #   Author: Fan
  #   Datetime: 2009-11-01 20:07:15
  #
  #   Your article is really great!
  #   --=====
  #   Author: Critic
  #   Datetime: 2009-11-01 20:10:54
  #
  #   Your article sucks!
  #
  # The document is composed of one or more simple documents, separated by a
  # _boundary_ --  a line beginning with "--" and containing a predefined
  # <em>boundary string</em>. The first document is a _prologue_ and it defines
  # the boundary string (without the "--" prefix) in its "Boundary" header. All
  # other headers of the prologue are ignored and so is its body. Remaining
  # documents are the _parts_ of the multipart document. Documents without any
  # parts are perfectly legal, however the prologue with the boundary definition
  # must be always present.
  #
  # == Example Usage
  #
  #   require "lib/doc_storage"
  #
  #   # Create a new document with two parts
  #   document = DocStorage::MultiPartDocument.new([
  #     DocStorage::SimpleDocument.new(
  #       {
  #         "Title"    => "Finishing the documentation",
  #         "Priority" => "urgent"
  #       },
  #       "We should finish the documentation ASAP."
  #     ),
  #     DocStorage::SimpleDocument.new(
  #       {
  #         "Title"    => "Finishing the code",
  #         "Priority" => "more urgent"
  #       },
  #       "But we should finish the code first!"
  #     ),
  #   ])
  #
  #   # Parse a file
  #   document = File.open("examples/multipart.txt", "r") do |f|
  #     DocStorage::MultiPartDocument.parse(f)
  #   end
  #
  #   # Document manipulation
  #   document.parts << DocStorage::SimpleDocument.new(
  #     {
  #       "Author"   => "Middle man",
  #       "Datetime" => "2009-11-01 21:15:33",
  #     },
  #     "I think your article is neither good nor bad."
  #   )
  #
  #   # Save the modified document
  #   File.open("examples/multipart_modified.txt", "w") do |f|
  #     f.write(document)
  #   end
  class MultiPartDocument
    # document parts (+Array+ of <tt>DocStorage::SimpleDocument</tt>)
    attr_accessor :parts

    class << self
      private
        def parse_from_io(io)
          prologue = SimpleDocument.parse(io, :detect)
          boundary = prologue.headers["Boundary"]

          parts = []
          until io.eof?
            parts << SimpleDocument.parse(io, boundary)
          end

          MultiPartDocument.new(parts)
        end

      public
        # Parses a multipart document from its serialized form and returns a new
        # +MultiPartDocument+ instance.
        #
        # The +source+ can be either an +IO+-like object or a +String+. In the
        # latter case, it is assumed that the string contains a serialized
        # document (not a file name).
        #
        # If any syntax error occurs, a +SyntaxError+ exception is raised. This
        # can happen when parsing the prologue or parts and an invalid header is
        # encountered, the headers are not terminated (no empty line separating
        # headers and body is parsed before the end of file) or if no "Boundary"
        # header is found in the prologue.
        #
        # See the +MultiPartDocument+ class documentation for a detailed
        # document format description.
        def parse(source)
          parse_from_io(source.is_a?(String) ? StringIO.new(source) : source)
        end
    end

    # Creates a new +MultiPartDocument+ with given parts.
    def initialize(parts)
      @parts = parts
    end

    # Tests if two documents are equal, i.e. whether they have the same class
    # and equal parts (in the <tt>==</tt> sense).
    def ==(other)
      other.instance_of?(self.class) && @parts == other.parts
    end

    # Returns string representation of this document. The result is in format
    # described in the +MultiPartDocument+ class documentation.
    def to_s
      # The boundary is just a random string. We do not check if the boudnary
      # appears anywhere in the subdocuments, which may lead to malformed
      # document.  This is of course principially wrong, but the probability of
      # collision is so small that it does not bother me much.
      chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
      boundary = Array.new(64) { chars[rand(chars.length)] }.join("")

      SimpleDocument.new({"Boundary" => boundary}, "").to_s +
        @parts.map { |part| "--#{boundary}\n#{part.to_s}" }.join("\n")
    end
  end
end
