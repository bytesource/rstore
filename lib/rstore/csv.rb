# encoding: utf-8
require 'open-uri'
require 'nokogiri'
require 'csv'
require 'rstore/data'
require 'rstore/base_db'
require 'rstore/base_table'

# Options:
# Consider splitting options for CSV and RStore using 'values_at':
# h = { "cat" => "feline", "dog" => "canine", "cow" => "bovine" }
# h.values_at("cow", "cat")  #=> ["bovine", "feline"]

module RStore
  class CSV
    

    # After 'table create':
    # http://stackoverflow.com/questions/1671401/unable-to-output-mysql-tables-which-involve-dates-in-sequel
    # Sequel::MySQL.convert_invalid_date_time = nil  if TempDB.connection_info[:adapter] = 'mysql'

  end
end

