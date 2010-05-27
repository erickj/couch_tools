require 'lib/http'

module CouchTools
  class Database
    RES_ALL_DBS = "/_all_dbs"
    RES_ALL_DOCS = "/_all_docs"

    attr_reader :url

    include CouchTools::RestResource

    class << self
      def get_all_dbs(url)
        url = CouchTools::Url.parse(url)
        url.path = RES_ALL_DBS
        json = CouchTools::HTTP.get(url)

        JSON.parse(json).map do |db_name|
          tmp = url.clone
          tmp.path = "/" + db_name
          self.new(tmp)
        end
      end
    end

    def initialize(url)
      @url = CouchTools::Url.parse(url)
    end

    def name
      @url.db
    end

    def get_all_docs
      tmp = url.to_s + RES_ALL_DOCS
      CouchTools::HTTP.get(tmp)
    end
  end
end
