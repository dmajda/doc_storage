module DocStorage
  # The +SimpleDocument+ class represents a simple RFC 822-like document,
  # suitable for storing text associated with some metadata (e.g. a blog
  # article with a title and a publication date). The +SimpleDocument+ class
  # allows to create the document programatically, parse it from a file,
  # manipulate its structure and save it to a file.
  #
  # Each document consist of _headers_ and a _body_. Headers are a dictionary,
  # mapping string names to string values. Body is a free-form text. The header
  # names can contain only alphanumeric characters and a hyphen ("-") and they
  # are case sensitive. The header values can contain any text that does not
  # begin with whitespace and does not contain a CR or LF character.
  #
  # == Document Format
  #
  # In serialized form, a simple document looks like this:
  #
  #   Title: My blog article
  #   Datetime: 2009-11-01 18:03:27
  #
  #   Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vel lorem
  #   massa. Sed blandit orci id leo blandit ut fermentum lacus ullamcorper.
  #   Suspendisse metus sapien, consectetur vitae imperdiet vel, ornare a metus.
  #   In imperdiet euismod mi, nec volutpat lorem porta id.
  #
  # Headers are first, each on its own line. Header names are separated from
  # values by a colon (":") and any amount of whitespace. Duplicate headers are
  # allowed with later value overwriting the earlier one. Other than that, the
  # order of headers does not matter. The body is separated from headers by
  # empty line.
  #
  # Documents without any headers are perfectly legal and so are documents with
  # an empty body. However, the separating line must be always present. This
  # means that an empty file is not a valid document, but a file containing a
  # single newline is.
  #
  # == Example Usage
  #
  #   require "lib/doc_storage"
  #
  #   # Create a new document with headers and body
  #   document = DocStorage::SimpleDocument.new(
  #     {
  #       "Title"    => "Finishing the documentation",
  #       "Priority" => "urgent"
  #     },
  #     "We should finish the documentation ASAP."
  #   )
  #
  #   # Parse a file
  #   document = File.open("examples/simple.txt", "r") do |f|
  #     DocStorage::SimpleDocument.parse(f)
  #   end
  #
  #   # Document manipulation
  #   document.headers["Tags"] = "example"
  #   document.body += "Nulla mi dui, pellentesque et accumsan vitae, mattis et velit."
  #
  #   # Save the modified document
  #   File.open("examples/simple_modified.txt", "w") do |f|
  #     f.write(document)
  #   end
  class SimpleDocument
    # document headers (+Hash+)
    attr_accessor :headers
    # document body (+String+)
    attr_accessor :body

    class << self
      private
        def parse_headers(io, detect_boundary)
          result = {}
          headers_terminated = false

          until io.eof?
            line = io.readline
            case line
              when /^([a-zA-Z0-9-]+):\s(.*)\n$/
                result[$1] = $2
              when "\n"
                headers_terminated = true
                break
              else
                raise SyntaxError, "Invalid header: \"#{line.strip}\"."
            end
          end

          raise SyntaxError, "Unterminated headers." unless headers_terminated
          if detect_boundary && !result.has_key?("Boundary")
            raise SyntaxError, "No boundary defined."
          end

          result
        end

        def parse_body(io, boundary)
          if boundary
            result = ""
            until io.eof?
              line = io.readline
              if line == "--#{boundary}\n"
                # Trim last newline from the body as it belongs to the boudnary
                # logically. This behavior is implemented to allow bodies with
                # no trailing newline).
                return result[0..-2]
              end

              result += line
            end
            result
          else
            io.read
          end
        end

        def parse_from_io(io, boundary)
          headers = parse_headers(io, boundary == :detect)
          boundary = headers["Boundary"] if boundary == :detect
          body = parse_body(io, boundary)

          SimpleDocument.new(headers, body)
        end

      public
        # Parses a simple document from its serialized form and returns a new
        # +SimpleDocument+ instance.
        #
        # The +source+ can be either an +IO+-like object or a +String+. In the
        # latter case, it is assumed that the string contains a serialized
        # document (not a file name).
        #
        # The +boundary+ determines how the end of the document body is detected:
        #
        # * If +boundary+ is +nil+, the document is read until the end of file.
        #
        # * If +boundary+ is <tt>:detect</tt>, the document is read until the
        #   end of file or until a line containing only a <em>boundary
        #   string</em> is read. The boundary string is the value of the
        #   "Boundary" header prefixed with "--".
        #
        # * Otherwise, it is assumed that +boundary+ contains a boundary string
        #   without the "--" prefix (the "Boundary" header value is ignored for
        #   the purpose of boundary detection). The document is read until the
        #   end of file or until a line containing only the boundary string is
        #   read.
        #
        # The +boundary+ parameter is provided mainly for parsing parts of
        # multipart documents (see the +MultipartDocument+ class documentation)
        # and usually should not be used.
        #
        # If any syntax error occurs, a +SyntaxError+ exception is raised. This
        # can happen when an invalid header is encountered, headers are not
        # terminated (no empty line separating headers and body is parsed before
        # the end of file) or if no "Boundary" header is found when detecting a
        # boundary.
        #
        # See the +SimpleDocument+ class documentation for a detailed document
        # format description.
        def parse(source, boundary = nil)
          parse_from_io(
            source.is_a?(String) ? StringIO.new(source) : source,
            boundary
          )
        end
    end

    # Creates a new +SimpleDocument+ with given headers and body.
    def initialize(headers, body)
      @headers, @body = headers, body
    end

    # Tests if two documents are equal, i.e. whether they have the same class
    # and equal headers and body (in the <tt>==</tt> sense).
    def ==(other)
      other.instance_of?(self.class) &&
        @headers == other.headers &&
        @body == other.body
    end

    # Returns string representation of this document. The result is in the
    # format described in the +SimpleDocument+ class documentation.
    def to_s
      serialized_headers = @headers.keys.sort.inject("") do |acc, key|
        acc + "#{key}: #{@headers[key]}\n"
      end
      serialized_headers + "\n" + @body
    end
  end
end
