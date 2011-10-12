# encoding: utf-8
require 'open-uri'
require 'nokogiri'
require 'rstore/data'
require 'rstore/file_crawler'
require 'rstore/converter'
require 'rstore/base_db'
require 'rstore/base_table'
require 'rstore/core_ext/string'

require 'pry'

# RStore::CSV.new do
#   from '~/temp/', header: true, recursive: true
#   from 'http://www.sovonex.com/summary.csv', selector: 'pre div.line'
#   to   'plastronics.project'
#   run
# end


module RStore
  class CSV


    attr_reader :database, :table
    attr_reader :data_stream
    attr_reader :errors
    
    
    
    
    

    def initialize &block
      @files_with_options = {}
      @data_stream        = []
      @database           = nil
      @table              = nil
      @ran_once           = false
      @errors             = {}

      instance_eval(&block) if block_given?

    end


    def from source, options={}
      crawler = FileCrawler.new(source, :csv, options)
      @files_with_options.merge!(crawler.file_options_hash)
    end



    def to db_table
      raise ArgumentError, "The name of the database and table have to be separated with a dot (.)" unless delimiter_correct?(db_table)
      db, tb = db_table.split('.')

      database = BaseDB.db_classes[db.to_sym]
      table    = BaseTable.table_classes[tb.to_sym]

      raise Exception, "Database '#{db}' not found"  if database.nil?
      raise Exception, "Table '#{tb}' not found"     if table.nil?

      @database = database
      @table    = table
    end


    # If a block is given, it is passed the opened Database object, which is closed when the block exits. For example:
    # Sequel.connect('sqlite://blog.db'){|db| puts db[:users].count}

    def run
      raise Exception, "You can invoke the 'run' method only once on a single instance of #{self.class}"  if ran_once?
      raise Exception, "Please specify at least one source file using the 'from' method" if @files_with_options.empty?
      raise Exception, "Please specify a valid database and table name using the 'to' method" if @database.nil? || @table.nil?

      @files_with_options.each do |path, options|
        data = read_data path, options[:file_options]
        next  if data == ''
        @data_stream << Data.new(path, data, :raw, options)  
      end

      @database.connect do |db|

        create_table(db)
        name = @table.name

        @data_stream.each do |data_object|
          data_object.parse_csv.convert_fields(db, name).into_db(db, name)
        end

        @ran_once = true
      end
     # Logger.print
     # @errors = Logger.error_queue
     # Logger.empty_error_queue
    end


    def read_data path, options
      data = ''
      begin
        if path.url?

          doc = Nokogiri::HTML(open(path))

          selector = options[:selector]
          data = doc.css(selector).inject("") do |result, link|
            result << link.content << "\n"
            result
          end
        else
          data = File.read(path)
        end 
      rescue => e
        Logger.new(options).print(path, :fetch, e)
      end
      data
    end


    def create_table db

      name = @table.name

      unless db.table_exists?(name)
        db.create_table(name, &@table.table_info)
      end

      # http://stackoverflow.com/questions/1671401/unable-to-output-mysql-tables-which-involve-dates-in-sequel
      if @database.connection_info.is_a?(Hash)
        Sequel::MySQL.convert_invalid_date_time = nil  if @database.connection_info[:adapter] == 'mysql'
      end
    end
    
    
    def delimiter_correct? name
      !!(name =~ /^[^\.]+\.[^\.]+$/)
    end

    def ran_once?
      @ran_once == true
    end

  end
end

 
