# encoding: utf-8
require 'open-uri'
require 'nokogiri'
require 'csv'
require 'rstore/data'
require 'rstore/file_crawler'
require 'rstore/converter'
require 'rstore/base_db'
require 'rstore/base_table'

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
      @data_strem = []

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
      table    = BaseTable.table_classes[table_db]

      raise Exception, "Database '#{database}' not found"  if database.nil?
      raise Exception, "Table '#{table}' not found"        if table.nil?

      @database = database
      @table    = table
    end


    # If a block is given, it is passed the opened Database object, which is closed when the block exits. For example:
    # Sequel.connect('sqlite://blog.db'){|db| puts db[:users].count}

    def run
      raise Exception, "Please specify at least one source file using the 'from' method" if @files_and_options.empty?

      @files_with_options.each do |path, options|
        csv = CSV.read(path, options[:parse_options])
        data = Data.new(path, csv, :parsed)
        @data_stream << data
      end

      Sequel.connect(@database.connection_info) do |db|

        table_name = @table.name

        schema = db.schema(table_name)

        # Create table
        # Implement Data#convert, Data#insert

        @data_stream.each do |data|
          converter = Converter.new(data, schema)
          data = converter.conver
          storage = Storage.new(data, db, table_name)
          storage.insert
        end
      end
    end








    
    

    # After 'table create':
    # http://stackoverflow.com/questions/1671401/unable-to-output-mysql-tables-which-involve-dates-in-sequel
    # Sequel::MySQL.convert_invalid_date_time = nil  if TempDB.connection_info[:adapter] = 'mysql'
    
    def delimiter_correct? name
      !!(name =~ /^[^\.]+\.[^\.]+$/)
    end

  end
end

