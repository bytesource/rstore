# encoding: utf-8
$:.unshift File.expand_path('../../../lib', __FILE__)
require 'csvstore/core_ext/object'

module CSVStore
  class Configuration

    # Todo: Evaluate the correctness of values passes via file_options

    # Supported options
    Parse_options   = [:row_sep, :col_sep, :quote_char]
    File_options    = [:recursive, :has_headers, :selector]

    Validation      = {recursive:   lambda { |value| value.boolean_or_nil? },
                       has_headers: lambda { |value| value.boolean_or_nil? },
                       selector:    lambda { |value| value.is_a?(Array)    }}

    attr_reader :file_options, :parse_options



    def initialize path, all_options
      self.parse_options = all_options
      self.file_options  = all_options

      raise ArgumentError, arg_error_message(path, all_options) if all_options.size > 0
    end

    
    def parse_options= all_options
      new_settings = extract_options all_options, Parse_options
      @parse_options = new_settings
    end

    # GO ON HERE AND CHECK THE INPUT VALUE!!!

    def file_options= all_options
      new_settings = extract_options all_options, File_options
      # new_settings.each_value do |value|
      @file_options = new_settings
    end


    # Helper methods
    # ------------------------------------------

    def extract_options provided_options, supported_options

      provided_options_copy = provided_options.dup

      provided_options_copy.inject({}) do |extracted, (key, value)|
        if supported_options.include?(key)
        extracted[key] = value 
        provided_options.delete(key)
        end
      extracted
      end
    end


    def arg_error_message path, all_options
      keys = all_options.keys.join(', ')
      "Unsupported options: #{keys} on path '#{path}'"
    end
 
  end
end



require 'csv'
require 'pp'

# Make constant?
Parse_options   = [:row_sep, :col_sep, :col_char]
File_options    = [:recursive, :has_headers, :selector]

options_wrong_keys = {col_sep: ";", quote_char: "'", recursive: true, converters: [1,2,3], wrong: 'xxx'}
options_correct = {col_sep: ";", quote_char: "'", recursive: true}

config = CSVStore::Configuration.new('/home/sovonex/Desktop', options_correct)
puts "parse options:"
pp config.parse_options
puts "file options:"
pp config.file_options


# values at


csv = <<-CSV.gsub(/^ +/, "")
  col1,col2,生日,col4,col5,col6,col7
  string1,,string3,string4,string5,string6,string7
CSV

content = CSV.parse(csv, :headers => true)
# puts ":headers => true"
# pp content
# #<CSV::Table mode:col_or_row row_count:2>


content = CSV.parse(csv, :headers => false)
# puts ":headers => false"
# pp content
# [["col1", "col2", "生日", "col4", "col5", "col6", "col7"],
#  ["string1", nil, "string3", "string4", "string5", "string6", "string7"]]

csv_col_sep = <<-CSV.gsub(/^ +/, "")
  col1;col2;生日;col4;col5;col6;col7
  string1;;string3;string4;string5;string6;string7
CSV

content = CSV.parse(csv_col_sep, :col_sep => ';')
# puts "col_sep: => ';'"
# pp content
# [["col1", "col2", "生日", "col4", "col5", "col6", "col7"],
#  ["string1", nil, "string3", "string4", "string5", "string6", "string7"]]


# CONFIGURATION OPTIONS TO CONSIDER:

# CSV
#

# -----------------------------

# CSVStore

# ------------------------------
# Reject or silently swallow the following CSV options:
# 
