require 'uri'

module CouchTools
  class Url
    class << self
      def parse(url)
        return url if url.instance_of?(self)

        obj = URI.parse(url)
        self.new(obj)
      end
    end

    def initialize(url)
      @url = url
    end

    def clone
      Url.parse(self.to_s)
    end

    def parts
      @url.path.gsub(/^\//,'').split("/")
    end

    def db
      parts.first
    end

    def doc
      ret = parts[1]
      ret = [ret,parts[2]].join("/") if ret && ret.match(/^_/)
      ret
    end

    def to_s
      @url.to_s
    end

    def method_missing(method,*args)
      @url.__send__(method,*args)
    end
  end
end
