# encoding: utf-8

require 'csvstore/configuration'
require 'uri'

module CSVStore
  class FileCrawler

    class << self
      attr_accessor :file_queue
    end

    @file_queue = Hash.new {|h,k| h[k] = Hash.new {|h,k| h[k] = nil}}

    attr_reader :file_options, :parse_options 
    attr_reader :path
    attr_reader :file_paths, :file_type
    attr_reader :config
    
    

    def initialize file_or_folder, file_type, options={}
      @path = file_or_folder
      @config = Configuration.new(file_or_folder, options)
      @file_options  = config.file_options
      @parse_options = config.parse_options
      @file_paths    = []
      @file_type     = file_type
    end

    def parse
      return @file_path << @path if @path =~ /^#{URI.regexp}$/

      dest = File.expand_path(@path)
      if File.directory?(dest)
        Dir.chdir(dest) do                           # Change current directory to 'path'.
          files = []
          if @file_options[:recursive]
            files = Dir.glob("**/*.{#{@file_type}}") # Recursively read files into array, skip files that are not of @file_type
          else
            files = Dir.glob("*.{#{@file_type}}")    # Read files of the current directory
          end
          files.each do |file|
            next if File.directory? file
            @file_paths << File.expand_path(file)
          end
        end
      else # file or wrong directory path
        file = File.expand_path(@path)
        raise ArgumentError, "'#{@path}' is not a valid path"     unless File.exists?(file)
        error_message = <<-MESSAGE
        File '#{@path}' is not a #{@file_type} file.
        NOTE: Non-#{@file_type} files in a directory path
              are silently skipped WITHOUT raising an exception
        MESSAGE
        raise ArgumentError, error_message    unless can_read?(@path)

        @file_paths << file
      end
    end

    # def parse
    #   dest = File.expand_path(@path)
    #   if File.directory?(dest)
    #     Dir.chdir(dest)                # Change current directory to 'path'.
    #     files = ''
    #     if @file_options[:recursive]
    #       files = Dir.glob("**/*.{#{@file_type}}")       # Recursively read files into array, skip files that are not of @file_type
    #     else
    #       files = Dir.glob("*.{#{@file_type}}")          # Read files of the current directory
    #     end
    #     files.each do |f|
    #       next if File.directory? f
    #       @file_paths << File.expand_path(f)
    #     end
    #   else # file or web address
    #     @file_paths << @path
    #   end
    # end

    def add
      parse
      @file_paths.each do |path|
        FileCrawler.file_queue[path][:file_options]  = @file_options
        FileCrawler.file_queue[path][:parse_options] = @parse_options
      end
    end


    def can_read? path
      !!(/.*\.#{@file_type.to_s}$/ =~ path)
    end

  end
end
