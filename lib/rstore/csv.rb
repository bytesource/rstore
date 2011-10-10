# encoding: utf-8
require 'open-uri'
require 'nokogiri'
require 'csv'
require 'rstore/data'
require 'rstore/file_crawler'
require 'rstore/converter'
require 'rstore/base_db'
require 'rstore/base_table'
require 'rstore/core_ext/string'

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
    
    
    

    def initialize &block
      @files_with_options = {}
      @data_stream        = []
      @database           = nil
      @table              = nil
      @run                = false

      instance_eval(block) if block_given?

    end


    def from source, options={}
      crawler = FileCrawler.new(source, :csv, options)
      @files_with_options.merge!(crawler.file_options_hash)
    end



    def to db_table
      raise ArgumentError, "The name of the database and table have to be separated with a dot (.)" unless delimiter_correct?(db_table)
      database, table = db_table.split('.')

      database = BaseDB.db_classes[database.to_sym]
      table    = BaseTable.table_classes[table.to_sym]

      raise Exception, "Database '#{database}' not found"  if database.nil?
      raise Exception, "Table '#{table}' not found"        if table.nil?

      @database = database
      @table    = table
    end


    # If a block is given, it is passed the opened Database object, which is closed when the block exits. For example:
    # Sequel.connect('sqlite://blog.db'){|db| puts db[:users].count}

    def run
      raise Exception, "You can invoke the 'run' method only once on a single instance of RStore::CSV"  if @run == true
      raise Exception, "Please specify at least one source file using the 'from' method" if @files_and_options.empty?
      raise Exception, "Please specify a valid database and table name using the 'to' method" if @database.nil? || @table.nil?

      @files_with_options.each do |path, options|
        data = read_data path, options[:file_options] 
        @data_stream << Data.new(path, data, :raw, options)  
      end

      Sequel.connect(@database.connection_info) do |db|

        create_table
        name = @table.name

        @datastream.each do |data_object|
          data_object.parse_csv.convert_fields(@database, name).into_db(@database, name)
        end

        @run = true
        Logger.print
        Logger.empty_error_queue
      end
    end



    def read_data path, options
      data = ''
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
      data
    end


    def create_table

      name = @table.name

      unless @database.table.exists?(name)
        @database.create_table(name, @table.table_info)
      end

      # http://stackoverflow.com/questions/1671401/unable-to-output-mysql-tables-which-involve-dates-in-sequel
      Sequel::MySQL.convert_invalid_date_time = nil  if @database.connection_info[:adapter] = 'mysql'
    end
    
    
    def delimiter_correct? name
      !!(name =~ /^[^\.]+\.[^\.]+$/)
    end

    def run?
      @run == true
    end

  end
end

