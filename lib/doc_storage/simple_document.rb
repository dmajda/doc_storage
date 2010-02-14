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
  # are case sensitive. The header values can contain any text.
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
  # values by a colon (":") and any amount of whitespace, trailing whitespace
  # after values is ignored. Values containing special characters (especially
  # newlines or leading/trailing whitepsace) must be enclosed in single or
  # double quotes. Quoted values can contain usual C-like escape sequences (e.g.
  # "\n", "\xFF", etc.). Duplicate headers are allowed with later value
  # overwriting the earlier one. Other than that, the order of headers does not
  # matter. The body is separated from headers by empty line.
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
  #   # Load from a file
  #   document = DocStorage::SimpleDocument.load_file("examples/simple.txt")
  #
  #   # Document manipulation
  #   document.headers["Tags"] = "example"
  #   document.body += "Nulla mi dui, pellentesque et accumsan vitae, mattis et velit."
  #
  #   # Save the modified document
  #   document.save_file("examples/simple_modified.txt")
  class SimpleDocument
    # document headers (+Hash+)
    attr_accessor :headers
    # document body (+String+)
    attr_accessor :body

    class << self
      private
        def parse_header_value(value)
          case value[0..0]
            when '"', "'"
              quote = value[0..0]
              if value[-1..-1] != quote
                raise SyntaxError, "Unterminated header value: #{value.inspect}."
              end

              inner_text = value[1..-2]
              if inner_text.gsub("\\" + quote, "").include?(quote)
                raise SyntaxError, "Badly quoted header value: #{value.inspect}."
              end

              inner_text = inner_text.
                gsub(/\\x([0-9a-fA-F]{2})/) { $1.to_i(16).chr }.
                gsub(/\\([0-7]{3})/) { $1.to_i(8).chr }.
                gsub("\\0", "\0").
                gsub("\\a", "\a").
                gsub("\\b", "\b").
                gsub("\\t", "\t").
                gsub("\\n", "\n").
                gsub("\\v", "\v").
                gsub("\\f", "\f").
                gsub("\\r", "\r").
                gsub("\\\"", "\"").
                gsub("\\'", "'")
              if inner_text !~ /^(\\\\|[^\\])*$/
                raise SyntaxError, "Invalid escape sequence in header value: #{value.inspect}."
              end
              inner_text.gsub("\\\\", "\\")
            else
              value
          end
        end

        def parse_headers(io, detect_boundary)
          result = {}
          headers_terminated = false

          until io.eof?
            line = io.readline
            case line
              when /^([a-zA-Z0-9-]+):(.*)\n$/
                result[$1] = parse_header_value($2.strip)
              when "\n"
                headers_terminated = true
                break
              else
                raise SyntaxError, "Invalid header: #{line.sub(/\n$/, "").inspect}."
            end
          end

          raise SyntaxError, "Unterminated headers." unless headers_terminated
          if detect_boundary && !result.has_key?("Boundary")
            raise SyntaxError, "No boundary defined."
          end

          result
        end

        def trim_last_char(s)
          s[0..-2]
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
                return trim_last_char(result)
              end

              result += line
            end

            # IO#readline always returns a newline at the end of a line, even
            # when it physically wasn't there (which can happen at the end of a
            # file). Note that only IO and its descendants behave this way (not
            # StringIO, for example).
            io.is_a?(IO) ? trim_last_char(result) : result
          else
            # IO#read always returns a newline at the end of the input, even
            # when it physically wasn't there. Note that only IO and its
            # descendants behave this way (not StringIO, for example).
            io.is_a?(IO) ? trim_last_char(io.read) : io.read
          end
        end

        def load_from_io(io, boundary)
          headers = parse_headers(io, boundary == :detect)
          boundary = headers["Boundary"] if boundary == :detect
          body = parse_body(io, boundary)

          SimpleDocument.new(headers, body)
        end

      public
        # Loads a simple document from its serialized form and returns a new
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
        def load(source, boundary = nil)
          load_from_io(
            source.is_a?(String) ? StringIO.new(source) : source,
            boundary
          )
        end

        # Loads a simple document from a file and returns a new +SimpleDocument+
        # instance. This method is just a thin wrapper around
        # SimpleDocument#load -- see its documentation for description of the
        # behavior and parameters of this method.
        #
        # See the +SimpleDocument+ class documentation for a detailed document
        # format description.
        def load_file(file, boundary = nil)
          File.open(file, "r") { |f| load(f, boundary) }
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
    #
    # Raises +SyntaxError+ if any document header has invalid name.
    def to_s
      @headers.keys.each do |name|
        if name !~ /\A[a-zA-Z0-9-]+\Z/
          raise SyntaxError, "Invalid header name: #{name.inspect}."
        end
      end

      serialized_headers = @headers.keys.sort.inject("") do |acc, key|
        value_is_simple = @headers[key] !~ /\A\s+/ &&
                          @headers[key] !~ /\s+\Z/ &&
                          @headers[key] !~ /[\n\r]/
        value = value_is_simple ? @headers[key] : @headers[key].inspect

        acc + "#{key}: #{value}\n"
      end

      serialized_headers + "\n" + @body
    end

    # Saves this document to an +IO+-like object. The result is in the format
    # described in the +SimpleDocument+ class documentation.
    #
    # Raises +SyntaxError+ if any document header has invalid name.
    def save(io)
      io.write(to_s)
    end

    # Saves this document to a file. The result is in the format described in
    # the +SimpleDocument+ class documentation.
    #
    # Raises +SyntaxError+ if any document header has invalid name.
    def save_file(file)
      File.open(file, "w") { |f| save(f) }
    end
  end
end
