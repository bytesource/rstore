# encoding: utf-8

module CSVStore
  class Data

    attr_reader   :path
    attr_reader   :content
    attr_reader   :type
    attr_accessor :error
    
    
    
    def initialize path, content, options = {}
      @path    = path
      @content = content
      raise ArgumentError, ":has_error=>'#{options[:has_error]}'" unless is_boolean_or_nil?(options[:has_error])
      @type    = extract_type path
      @error   = options[:has_error] || false
    end

    def extract_type path
      path, filename = File.split(path)
      filename.match(/\.(?<type>.*)$/)[:type].to_sym
    end

    def has_error?
      @error
    end

    def is_boolean_or_nil? value
      return true if value.nil?
      !!value == value
    end

  end
end
