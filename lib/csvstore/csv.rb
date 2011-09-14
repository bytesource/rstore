# encoding: utf-8
require 'open-uri'
require 'nokogiri'
require 'csv'
$:.unshift File.expand_path('../../../lib', __FILE__)
require 'csvstore/data'
require 'csvstore/base_db'
require 'csvstore/base_table'

# Options:
# Consider splitting options for CSV and CSVStore using 'values_at':
# h = { "cat" => "feline", "dog" => "canine", "cow" => "bovine" }
# h.values_at("cow", "cat")  #=> ["bovine", "feline"]

module CSVStore
  class CSV

    class << self
      attr_accessor :persistent_row
    end

    attr_accessor :temp_row
    

    @persistent_row = []
    @temp_row       = []


    def initialize *args
      @temp_row = args
    end

    def run
      begin
        puts "Inside 'run' doing stuff..."
        raise Exception, "shit happend"
      rescue Exception
        # $stderr.print "That's what failed: " + $!.to_s
        CSV.persistent_row += @temp_row
      end
    end

  end
end

# temp = CSVStore::CSV.new("hello", "world")
# temp.run
temp = CSVStore::CSV.new("I feel great", "you to")
temp.run
puts CSVStore::CSV.persistent_row
