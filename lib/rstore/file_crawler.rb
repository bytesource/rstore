# encoding: utf-8

require 'open-uri'
require 'rstore/configuration'
require 'rstore/data'
require 'rstore/core_ext/string'

module RStore
  class FileCrawler

    #attr_reader :file_options_hash
    attr_reader :data_hash

    attr_reader :file_options, :parse_options
    attr_reader :path
    attr_reader :file_paths, :file_type
    attr_reader :config



    def initialize file_or_folder, file_type, options={}
      @path                  = file_or_folder
      @file_type             = file_type
      @config                = Configuration.new(file_or_folder, options)
      @file_options          = @config.file_options
      @parse_options         = @config.parse_options
      self.file_paths        = @path
      self.file_options_hash = @file_paths
      self.data_hash         = @file_options_hash
    end


    def file_paths= path
      return @file_paths unless @file_paths.nil?  # @file_path can only be set once on initialization

      @file_paths = []
      files       = []
      if path.url?
        return @file_paths << verify_and_format_url(path)
      elsif File.directory?(File.expand_path(path))   # Directory
        Dir.chdir(path) do                            # Change current directory to 'path'.
          parse_directory(@file_options[:recursive]).each do |f|
            files << File.expand_path(f)
          end
        end
      else                                            # Either a file or a non-existing directory path
        file = File.expand_path(path)
        raise ArgumentError, "'#{path}' is not a valid path" unless File.exists?(file) # File.exist?(“/path/to/file_or_dir”)

        error_message = <<-MESSAGE.gsub(/^\s+/,'')
                           Not a #{@file_type} file.
                           NOTE: Non-#{@file_type} files in a directory path
                                 are silently skipped WITHOUT raising an exception
                           MESSAGE

        raise ArgumentError, error_message                    unless can_read?(path)

        files << file
      end

      @file_paths = files
    rescue Exception => e
        # Dirty hack to be able to call instantiate Logger.
        data = Data.new(path, '', :raw, Configuration.default_options)

        logger = Logger.new(data)
        logger.log(:fetch, e)
        logger.error
    end


    def data_hash= options_hash
      hash = Hash[options_hash.map do |path, options|
        data = Data.new(path, '', :raw, options)
        [path, data]
      end]
      @data_hash = hash
    end


    def file_options_hash= file_paths
      hash = Hash.new {|h,k| h[k] = Hash.new {|h,k| h[k] = nil}}
      file_paths.each do |path|
        hash[path][:file_options]  = @file_options
        hash[path][:parse_options] = @parse_options
      end
      @file_options_hash = hash
    end


    def parse_directory option
      files = []
      if option
        files = Dir.glob("**/*.{#{@file_type}}") # Recursively read files into array, skip files that are not of @file_type
      else
        files = Dir.glob("*.{#{@file_type}}")    # Read files of the current directory
      end
      files.each do |file|
        next if File.directory? file
        file
      end
    end


    # Helper methods ---------------------------


    def can_read? path
      !!(/.*\.#{@file_type.to_s}$/ =~ path)
    end


    def verify_and_format_url url
      address = url
      begin # add additional 'begin' block so that we can return the original, unchanged url in the error message.
        open(address)
        address
      rescue
        case address
        when /^www/  # open-uri does not recognize URLs starting with 'www'
          address = 'http://' + address
          retry
        when /^http:/ # open-uri does not redirect from http to https on a valid https URL
          address = address.gsub(/http/,'https')
          retry
        else
          raise ArgumentError, "Could not connect to #{url}. Please check if this URL is correct."
        end
      end
    end

  end
end
