# encoding: utf-8
require 'open-uri'
require 'rstore/data'
require 'rstore/file_crawler'
require 'rstore/converter'
require 'rstore/configuration'
require 'rstore/base_db'
require 'rstore/base_table'
require 'rstore/core_ext/string'


module RStore
  class CSV

    #@return [BaseDB] a subclass of {RStore::BaseDB}
    attr_reader :database
    #@return [BaseTable] a sublcass of {RStore::BaseTable}
    attr_reader :table
    #@return [Array<Data>] holds `RStore::Data` objects that are used internally to store information from a data source.
    attr_reader :data_array


    # This constructor takes a block yielding an implicit instance of _self_.
    # Within the block, the following methods need to be called:
    #
    # * {#from}
    # * {#to}
    # * {#run}
    # @example
    #  RStore::CSV.new do
    #    from '../easter/children', :recursive => true                   # select a directory or
    #    from '../christmas/children/toys.csv'                           # file, or
    #    from 'www.example.com/sweets.csv', :selector => 'pre div.line'  # URL
    #    to   'company.products'                                         # provide database and table name
    #    run                                                             # run the program
    #  end
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


    # Specify the source of the csv file(s)
    # There can be several calls to this method on given instance of `RStore::CSV`.
    # This method has to be called before {#run}.
    # @overload from(source, options)
    #  @param [String] source The relative or full path to a directory, file, or an URL
    #  @param [Hash] options The options used to customize fetching and parsing of csv data
    #  @option options [Boolean] :has_headers When set to false, the first line of a file is processed as data, otherwise it is discarded.
    #    (default: `true`)
    #  @option options [Boolean] :recursive When set to true and a directory is given, recursively search for files. Non-csv files are skipped.
    #    (default: `false`]
    #  @option options [String] :selector Mandatory css selector when fetching data from an URL. Uses the same syntax as {http://nokogiri.org/ Nokogiri}, default: `""`
    #  @option options [String] :col_sep The String placed between each field. (default: `","`)
    #  @option options [String, Symbol] :row_sep The String appended to the end of each row.
    #    (default: `:auto`)
    #  @option options [String] :quote_car The character used to quote fields.
    #    (default: `'"'`)
    #  @option options [Integer, Nil] :field_size_limit The maximum size CSV will read ahead looking for the closing quote for a field.
    #    (default: `nil`)
    #  @option options [Boolean] :skip_blanks When set to a true value, CSV will skip over any rows with no content.
    #    (default: `false`)
    #  @option options [Array] :digit_seps The *thousands separator* and *decimal mark* used for numbers in the data source
    #    (default: `[',', '.']`).
    #    Different countries use different thousands separators and decimal marks, and setting this options ensures that
    #    parsing of these numbers succeeds. Note that all numbers will still be *stored* in the format that Ruby recognizes,
    #    that is with a point (.) as the decimal mark.
    # @overload from(source)
    #  @param [String] source The relative or full path to a directory, file, or an URL. The default options will be used.
    # @return [void]
    # @example
    #  store = RStore::CSV.new
    #  # fetching data from a file
    #  store.from '../christmas/children/toys.csv'
    #  # fetching data from a directory
    #  store.from '../easter/children', :recursive => true
    #  # fetching data from an URL
    #  store.from 'www.example.com/sweets.csv', :selector => 'pre div.line'
    def from source, options={}
      crawler = FileCrawler.new(source, :csv, options)
      @data_hash.merge!(crawler.data_hash)
      @from = true
    end


    # Choose the database table to store the csv data into.
    # This method has to be called before {#run}.
    # @param [String] db_table The names of the database and table, separated by a dot, e.g. 'database.table'.
    #  The name of the database has to correspond to a subclass of `RStore::BaseDB`:
    #  CompanyDB < RStore::BaseDB -> 'company'
    #  The name of the table has to correspond to a subclass of `RStore::BaseTable`:
    #  DataTable < RStore::BaseTable -> 'data'
    # @return [void]
    # @example
    #  store = RStore::CSV.new
    #  store.to('company.products')
    def to db_table
      @database, @table = CSV.database_table(db_table)
      @to       = true
    end


    #@private
    def self.database_table db_table
      raise ArgumentError, "The name of the database and table have to be separated with a dot (.)"  unless delimiter_correct?(db_table)

      db, tb = db_table.split('.')

      database = BaseDB.db_classes[db.downcase.to_sym]
      table    = BaseTable.table_classes[tb.downcase.to_sym]

      raise Exception, "Database '#{db}' not found"  if database.nil?
      raise Exception, "Table '#{tb}' not found"     if table.nil?

      [database, table]
    end


    # Start processing the csv files, storing the data into a database table.
    # Both methods, {#from} and {#to}, have to be called before this method.
    # @return [void]
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

        prepared_data_array = @data_array.map do |data|
          data.parse_csv.convert_fields(db, name)
        end

        insert_all(prepared_data_array, db, name)

        @run = true
        message = <<-TEXT.gsub(/^\s+/, '')
        ===============================
        All data has been successfully inserted into table '#{database.name}.#{table.name}'"
        -------------------------------
        You can retrieve all table data with the following code:
        -------------------------------
        #{self.class}.query('#{database.name}.#{table.name}') do |table|
          table.all
        end
        ===============================
        TEXT
        puts message
      end
    end


    #@private
    def insert_all data_stream, database, name
      database.transaction do  # outer transaction
        data_stream.each do |data|
          data.into_db(database, name)
        end
      end
    end

    private :insert_all


    #@private
    def read_data data_object
      path    = data_object.path
      options = data_object.options

      begin
        if path.url?
          require 'nokogiri'
          doc = Nokogiri::HTML(open(path))
          selector = options[:file_options][:selector]

          content = doc.css(selector).inject("") do |result, link|
            result << link.content << "\n"
            result
          end
        else
          content = File.read(path)
        end

      raise ArgumentError, "Empty content!"  if content.empty?

      rescue Exception => e
        logger = Logger.new(data_object)
        logger.log(:fetch, e)
        logger.error
      end

      content
    end


    #@private
    def create_table db

      name = @table.name

      if @database.connection_info.is_a?(Hash)
        if @database.connection_info[:adapter] == 'mysql'
          # http://sequel.rubyforge.org/rdoc/files/doc/release_notes/2_10_0_txt.html
          Sequel::MySQL.default_engine = 'InnoDB'
          # http://stackoverflow.com/questions/1671401/unable-to-output-mysql-tables-which-involve-dates-in-sequel
          Sequel::MySQL.convert_invalid_date_time = nil
        end
      end

      unless db.table_exists?(name)
        db.create_table(name, &@table.table_info)
      end

    end


    # Easy querying by yielding a {http://sequel.rubyforge.org/rdoc/files/doc/dataset_basics_rdoc.html Sequel::Dataset} instance of your table.
    # @param [String] db_table The name of the database and table, separated by a dot.
    # @return [void]
    # @yieldparam [Sequel::Dataset] table The dataset of your table
    # @example
    #  RStore::CSV.query('company.products') do |table|    # table = Sequel::Dataset object
    #    table.all                                         # fetch everything
    #    table.all[3]                                      # fetch row number 4
    #    table.filter(:id => 2).update(:on_stock => true)  # update entry
    #    table.filter(:id => 3).delete                     # delete entry
    #  end
    def self.query db_table, &block
      database, table = database_table(db_table)
      database.connect do |db|
        block.call(db[table.name]) if block_given?  # Sequel::Dataset
      end
    end



    #@private
    def self.delimiter_correct? name
      !!(name =~ /^[^\.]+\.[^\.]+$/)
    end

    # Test if the data has been inserted into the database table.
    # @return [Boolean]
    def ran_once?
      @run == true
    end


    # Change default options recognized by {#from}
    # The new option values apply to all following instances of `RStore::CSV`
    # Options can be reset to their defaults by calling {.reset_default_options}
    # See {#from} for a list of all options and their default values.
    # @param [Hash] options Keys from default options with their respective new values.
    # @return [void]
    # @example
    #   # Search directories recursively and handle the first row of a file as data by default
    #   RStore::CSV.change_default_options(:recursive => true, :has_headers => false)
    def self.change_default_options options
      Configuration.change_default_options(options)
    end



    # Reset the options recognized by {#from} to their default values.
    # @return [void]
    # @example
    #   RStore::CSV.reset_default_options
    def self.reset_default_options
      Configuration.reset_default_options
    end


  end
end


