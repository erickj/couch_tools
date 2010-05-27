require 'uri'

module CouchTools
  class Url
    class << self
      def parse(url)
        return url if url.respond_to?(:db)

        obj = URI.parse(url)
        self.new(obj)
      end
    end

    def initialize(url)
      @url = url
      @path_parts = @url.path.gsub(/^\//,'').split("/")
    end

    def db
      @path_parts[0]
    end

    def doc
      ret = @path_parts[1]
      ret = [ret,@path_parts[2]].join("/") if ret && ret.match(/^_/)
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
