# encoding: utf-8

require 'sequel'
require 'rstore/data'
require 'rstore/logger'
require 'rstore/exceptions'
require 'rstore/modules/helper_methods'

module RStore
  class Storage
    include HelperMethods

    attr_accessor :data, :db, :table, :prepared_data, :primary_key
    attr_accessor :state
    

    def initialize data_object, database, table_name
      state = data_object.state
      raise InvalidStateError, "#{state.inspect} is not a valid state on initialization for class Storage" unless state == :converted
      @state = state
      @data  = data_object.clone
      @db    = database
      @table = table_name
      @schema = @db.schema(@table)
      @primary_key = p_key @schema 
      @prepared_data = prepare_data
    end

    
    def column_names
      @schema.map do |(col_name, col_properties)|  
        col_name unless col_name == @primary_key
      end.compact
    end


    def prepare_data
      col_names = column_names
      @data.content.map do |row|
        Hash[col_names.zip(row)]
      end
    end

    
    def insert
      dataset = @db[@table]
      begin
        @db.transaction do
          @prepared_data.each_with_index do |row, row_index|
            @row_index = row_index
            dataset.insert(row)
            # Sequel often only throws an exception when retrieving an incorrect record, 
            # so we return the last record inserted to trigger any such exceptions.
            dataset.order(@primary_key).last
          end
        end
      rescue Exception => e
        logger = Logger.new(@data)
        logger.log(@data.path, :store, e, row: @row_index)
        logger.error
      
      end
      @state = :stored
      @state
    end





  end
end

 
 
