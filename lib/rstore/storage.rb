# encoding: utf-8

require 'sequel'
require 'rstore/data'
require 'rstore/logger'

module RStore
  class Storage

    attr_accessor :data, :db, :table, :prepared_data
    


    def initialize data_object, database, table_name
      @data  = data_object.clone
      @db    = database
      @table = table_name
      @prepared_data = prepare_data
    end


    def column_names
      @db.schema(@table).map do |(k,v)|  
        k unless k == :id
      end.compact
    end


    def prepare_data
      col_names = column_names
      @data.content.map do |row|
        Hash[col_names.zip(row)]
      end
    end

 # Logger!!!!!!!!!!!!!
    def insert
      dataset = @db[@table]
      @db.transaction do
        @prepared_data.each do |row|
          dataset.insert(row)
        end
      end
    end





  end
end

 
