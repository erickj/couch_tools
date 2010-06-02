require 'ostruct'
require 'pathname'

module CouchTools
  class Document
    attr_reader :url

    include CouchTools::RestResource

    def initialize(url)
      @url = CouchTools::Url.parse(url)
      @ostruct = nil
      @new = nil
      self.read
    end

    def read
      begin
        json = CouchTools::HTTP.get(url)
        @ostruct = OpenStruct.new(JSON.parse(json))
      rescue Net::HTTPServerException
        case $!.response
        when Net::HTTPNotFound
          @ostruct = OpenStruct.new({})
          self._id = url.doc
          @new = true
        else
          raise $!
        end
      end
    end

    def save
      begin
        res = self.put(self.to_json)
        res = OpenStruct.new(JSON.parse(res))
        self._rev = res.rev if res.ok
      end
    end

    # override CouchTools::RestResource
    def delete
      delete_url = url.to_s + "?rev=%s"%self._rev
      CouchTools::HTTP.delete(delete_url)
    end

    def to_json
      @ostruct.marshal_dump.to_json
    end

    def [](*args)
      @ostruct.marshal_dump[args[0]]
    end

    def []=(*args)
      table = @ostruct.marshal_dump
      table[args[0]] = args[1]
      @ostruct.marshal_load(table)
    end

    def method_missing(method,*args)
      @ostruct.__send__(method,*args) if @ostruct
    end
  end

  class DesignDocument < Document
    DESIGN_DOC_PATHS = [
                        :validate_doc_update,
                        :views,
                        # :shows,
                        # :_attachments,
                        # :signatures,
                        # :lib,
                       ]

    def initialize(path,url,language="javascript")
      super(url)
      @path = path
      self[:language] = language
      import_from_path(path)
    end

    def import_from_path(path)
      path = Pathname.new(path)
      DESIGN_DOC_PATHS.each do |part|
        tmp_paths = [path.join(part.to_s),path.join(part.to_s + ".js")]
        res = nil

        tmp_paths.each do |tmp_path|
          res = self.import(tmp_path) unless res
        end

        self[part] = res if res
      end
    end

    def import(path)
      return unless path
      return if path.to_s.match(/~$/)
      ret = nil

      if File.directory?(path)
        ret = {}

        Dir.glob(File.join(path,"**")) do |file_name|
          next if file_name.to_s.match(/~$/)

          key = File.basename(file_name).split('.').first
          ret[key] = import(file_name)
        end
      elsif File.file?(path)
        f = File.new(path)
        ret = f.read.strip
        f.close

        ret.gsub!(/(\/\/[\s]*\!code (.*))$/) do |match|
          retSub = nil
          replacementPath = (File.dirname(path) + "/" + $2).strip

          if File.file?(replacementPath)
            fSub = File.new(replacementPath)
            retSub = fSub.read
            fSub.close
          end
          retSub
        end
      end

      ret
    end
  end

end
