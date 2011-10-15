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
    attr_reader :data_array
    attr_reader :errors
    

    def initialize &block
      @data_hash = {}
      @data_array        = []
      @database           = nil
      @table              = nil
      @ran_once           = false

      instance_eval(&block) if block_given?

    end


    def from source, options={}
      crawler = FileCrawler.new(source, :csv, options)
      @data_hash.merge!(crawler.data_hash)
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
      return  if ran_once?
      # raise Exception, "You can invoke the 'run' method only once on a single instance of #{self.class}"  if ran_once?
      raise Exception, "Please specify at least one source file using the 'from' method" if @data_hash.empty?
      raise Exception, "Please specify a valid database and table name using the 'to' method" if @database.nil? || @table.nil?

      # USE DATA OBJECT HASH!!!!!!!!!!!!
      @data_hash.each do |path, data|
        content = read_data(data)
        @data_array << Data.new(path, content, :raw, data.options)  
      end

      @database.connect do |db|

        create_table(db)
        name = @table.name

        @data_array.each do |data_object|
          data_object.parse_csv.convert_fields(db, name).into_db(db, name)
        end

        @ran_once = true
      end
     # Logger.print
     # @errors = Logger.error_queue
     # Logger.empty_error_queue
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
      @ran_once == true
    end

  end
end

 
