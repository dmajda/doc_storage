require File.dirname(__FILE__) + "/syntax_error"

module DocStorage
  class SimpleDocument
    attr_reader :headers, :body

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
        def parse(source, boundary = nil)
          parse_from_io(
            source.is_a?(String) ? StringIO.new(source) : source,
            boundary
          )
        end
    end

    def initialize(headers, body)
      @headers, @body = headers, body
    end

    def ==(other)
      other.instance_of?(self.class) &&
        @headers == other.headers &&
        @body == other.body
    end

    def to_s
      serialized_headers = @headers.keys.sort.inject("") do |acc, key|
        acc + "#{key}: #{@headers[key]}\n"
      end
      serialized_headers + "\n" + @body
    end
  end
end
