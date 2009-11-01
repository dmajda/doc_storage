module DocStorage
  class MultiPartDocument
    attr_reader :parts

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
        def parse(source)
          parse_from_io(source.is_a?(String) ? StringIO.new(source) : source)
        end
    end

    def initialize(parts)
      @parts = parts
    end

    def ==(other)
      other.instance_of?(self.class) && @parts == other.parts
    end

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
