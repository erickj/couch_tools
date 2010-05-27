require 'ostruct'
require 'pathname'

module CouchTools
  class Document
    def initialize(url)
      @url = CouchTools::Url.parse(url)
      @ostruct = nil
      @new = nil
      self.read
    end

    def read
      begin
        json = CouchTools::HTTP.get(@url)
        @ostruct = OpenStruct.new(JSON.parse(json))
      rescue Net::HTTPServerException
        case $!.response
        when Net::HTTPNotFound
          @ostruct = OpenStruct.new({})
          self._id = @url.doc
          @new = true
        else
          raise $!
        end
      end
    end

    def save
      begin
        res = CouchTools::HTTP.put(@url,self.to_json)
        @write_dirty = false

        res = OpenStruct.new(JSON.parse(res))
        self._rev = res.rev if res.ok
      end
    end

    def delete
      delete_url = @url.to_s + "?rev=%s"%self._rev
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

    def initialize(path,url)
      super(url)
      @path = path
      import_from_path(path)
    end

    def import_from_path(path)
      path = Pathname.new(path)
      DESIGN_DOC_PATHS.each do |part|
        self[part] = self.import(path.join(part.to_s)) if part
      end
    end

    def import(path)
      return unless path
      return if path.to_s.match(/~$/)
      
      if File.directory?(path)
        ret = {}

        Dir.glob(File.join(path,"**")) do |file_name|
          next if file_name.to_s.match(/~$/)

          key = File.basename(file_name).split('.').first
          ret[key] = import(file_name)
        end
      elsif File.file?(path)
        f = File.new(path)
        ret = f.read
        f.close
      end

      ret
    end
  end

end
