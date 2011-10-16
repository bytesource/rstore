# encoding: utf-8
require 'open-uri'
require 'nokogiri'
require 'rstore/data'
require 'rstore/file_crawler'
require 'rstore/converter'
require 'rstore/configuration'
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
    attr_reader :data_array
    attr_reader :errors
    

    def initialize &block
      @data_hash  = {}
      @data_array = []
      @database   = nil
      @table      = nil

      # Tracking method calls to #from, #to, and #run.
      @from = false
      @to   = false
      @run  = false

      instance_eval(&block) if block_given?

    end


    def from source, options={}
      crawler = FileCrawler.new(source, :csv, options)
      @data_hash.merge!(crawler.data_hash)
      @from = true
    end


    def to db_table
      raise ArgumentError, "The name of the database and table have to be separated with a dot (.)"  unless delimiter_correct?(db_table)
      raise Exception,     "At least one method 'from' has to be called before method 'to'"          unless @from == true

      db, tb = db_table.split('.')

      database = BaseDB.db_classes[db.to_sym]
      table    = BaseTable.table_classes[tb.to_sym]

      raise Exception, "Database '#{db}' not found"  if database.nil?
      raise Exception, "Table '#{tb}' not found"     if table.nil?

      @database = database
      @table    = table
      @to       = true
    end


    def run
      return  if ran_once?   # Ignore subsequent calls to #run 
      raise Exception, "At least one method 'from' has to be called before method 'run'"  unless @from == true
      raise Exception, "Method 'to' has to be called before method 'run'"                 unless @to   == true

      @data_hash.each do |path, data|
        content = read_data(data)
        @data_array << Data.new(path, content, :raw, data.options)  
      end

      @database.connect do |db|

        create_table(db)
        name = @table.name

        db.transaction do   # outer transaction
          @data_array.each do |data|
            data.parse_csv.convert_fields(db, name).into_db(db, name)
          end
        end

        @run = true
        message = <<-TEXT.gsub(/^\s+/, '')
        ===============================
        All data has been successfully inserted into table '#{database.name}.#{table.name}'"
        ===============================
        TEXT
        puts message
      end
    end


    def read_data data_object
      path    = data_object.path
      options = data_object.options
      data    = ''

      begin
        if path.url?

          doc = Nokogiri::HTML(open(path))

          selector = options[:selector]
          content = doc.css(selector).inject("") do |result, link|
            result << link.content << "\n"
            result
          end
        else
          content = File.read(path)
        end 

      raise ArgumentError "Empty content!"  if content.empty?
      rescue => e
        logger = Logger.new(@data)
        logger.log(path, :fetch, e)
        logger.error
      end
      
      content
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
      @run == true
    end


    def self.change_default_options options
      Configuration.change_default_options(options)
    end

    
    def self.reset_default_options
      Configuration.reset_default_options
    end


  end
end

 
