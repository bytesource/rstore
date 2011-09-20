# encoding: utf-8

require 'csvstore/configuration'

module CSVStore
  class FileCrawler

    class << self
      attr_accessor :file_queue
    end

    @file_queue = Hash.new {|h,k| h[k] = Hash.new {|h,k| h[k] = nil}}

    attr_reader :file_options, :parse_options 
    attr_reader :path
    attr_reader :file_paths
    attr_reader :config
    
    

    def initialize file_or_folder, options
      @path = file_or_folder
      @config = Configuration.new(file_or_folder, options)
      @file_options  = config.file_options
      @parse_options = config.parse_options
      @file_paths    = []
    end

    def parse
      dest = File.expand_path(@path)
      if File.directory?(dest)
        puts "Directory"
        puts "is directory"   # Test if destination is a directory.
        Dir.chdir(dest)                # Change current directory to 'path'.
        files = ''
        if @file_options[:recursive]
          files = Dir.glob("**/*")       # Recursively read files into array.
        else
          files = Dir.glob("*")          # Read files of the current directory
        end
        files.each do |f|
          @file_paths << f
        end
      else # file or web address
        @file_paths << @path
      end
    end


    def add
      parse
      @file_paths.each do |path|
        FileCrawler.file_queue[path][:file_options]  = @file_options
        FileCrawler.file_queue[path][:parse_options] = @parse_options
      end
    end

  end
end
