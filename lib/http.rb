require 'net/http'

module CouchTools
  class HTTP
    class << self
      def get(url)
        url = CouchTools::Url.parse(url)
        req = Net::HTTP::Get.new(url.path)
        make_request(req,url)
      end

      def put(url,data)
        url = CouchTools::Url.parse(url)
        req = Net::HTTP::Put.new(url.path)
        req.body = data
        make_request(req,url)
      end

      def delete(url)
        url = CouchTools::Url.parse(url)
        req = Net::HTTP::Delete.new(url.path)
        req
        make_request(req,url)
      end

      def make_request(req,url)
        req.basic_auth(url.user,url.password) if url.user && url.password

        res = Net::HTTP.new(url.host,url.port).start do |http|
          http.request(req)
        end

        ret = nil
        case res
        when Net::HTTPSuccess
          ret = res.body && res.read_body
          ret ||= true
        when Net::HTTPRedirection
          raise NotImplementedError, "redirect not implmented"
        else
          res.error!
        end

        ret
      end
    end
  end
end
