require 'net/http'

module CouchTools
  module RestResource
    class << self
      def included(base)
        raise NotImplementedError unless base.instance_methods.include?(:url.to_s)
        base.__send__(:include, InstanceMethods)
      end
    end

    module InstanceMethods
      def get(*params)
        CouchTools::HTTP.get(self.url,*params)
      end

      def put(data,*params)
        CouchTools::HTTP.put(self.url,data,*params)
      end

      def delete(*params)
        CouchTools::HTTP.delete(self.url,*params)
      end
    end
  end

  class HTTP
    class << self
      def get(url,*params)
        url = CouchTools::Url.parse(url)
        req = Net::HTTP::Get.new(url.to_s)
        make_request(req,url)
      end

      def put(url,data,*params)
        url = CouchTools::Url.parse(url)
        req = Net::HTTP::Put.new(url.to_s)
        req.body = data
        make_request(req,url)
      end

      def delete(url,*params)
        url = CouchTools::Url.parse(url)
        req = Net::HTTP::Delete.new(url.to_s)
        req
        make_request(req,url,*params)
      end

      def make_request(req,url,*params)
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
