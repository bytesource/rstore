# encoding: utf-8

require 'rstore/core_ext/object'

module RStore
  class Data

    attr_reader   :path
    attr_reader   :content
    attr_reader   :type
    attr_accessor :error
    
    
    
    def initialize path, content, options = {}
      @path    = path
      @content = content
      raise ArgumentError, ":has_error=>'#{options[:has_error]}'" unless options[:has_error].boolean_or_nil?
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

  end
end
