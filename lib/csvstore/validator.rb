# encoding: utf-8
require 'csvstore/logger'
require 'csvstore/exceptions'

module CSVStore
  class Validator

    # @return [Hash<:verify => Array>]
    attr_accessor :error_queue
    # @ return [String] path of the given csv file
    # @return [Array<Array>] Array of array returned by CSV.parse
    attr_reader   :data
    # @return [Array<symbol>] Array of symbols representing the Ruby class set for each column
    attr_reader   :column_types
    # @return [Array<Boolean>] Array of boolean values indicating if NULL is allowed as a column value
    attr_reader   :allow_null
    attr_accessor :error

      #  Converters used to verify the field data is valid. 
      #  If a conversion fails, an exception is thrown and the processed
      #  error message (including row index and column index) is stored
      #  in @error_queue.
      #  Note: Most of these verifications are done by Sequel, too, but 
      #  result in a less meaningful error message in case of failure.

    boolean_converter = lambda do |field|
      if field.downcase == 'true' || field == '1'
        return true 
      end
      if field.downcase == 'false' || field == '0' 
        return false
      else
        raise ArgumentError, "invalid value for Boolean() '#{field}'"
      end
    end

    Converters = Hash.new {|h,k| h[k] = lambda { |field| field }}.
      merge!({string:   lambda { |field| field },
              date:     lambda { |field| Date.parse(field).to_s },
              datetime: lambda { |field| DateTime.parse(field).to_s }, 
              integer:  lambda { |field| Integer(field) },
              float:    lambda { |field| Float(field) },
              boolean:  lambda { |field| boolean_converter[field] }})


    def initialize data_object, schema
      @data   = data_object.clone
      @schema = schema
      @column_types = extract_from_schema :type
      @allow_null   = extract_from_schema :allow_null
      @error  = false
    end


    def extract_from_schema target
      # Drop first row which holds the settings for the primary key.
      hash = @schema.drop(1).inject({}) do |result, (k, v)|
        v = :datetime if v == :time # Sequel handles Time as Datetime
      result[k] = v[target]
      result
      end
      hash.map do |column_name, value|
        value
      end
    end


    # Returns @table with converted fields if no error is thrown, nil otherwise
    def validate_and_convert
      content = @data.content
      temp_data = content
      begin
        content.each_with_index do |row, row_index|
          temp_data[row_index] = validate_and_convert_row(row, row_index, 
                                                          @column_types[row_index], 
                                                          @allow_null[row_index])
        end
      rescue InvalidRowLengthError
        # Swallow this exception, then leave the begin..end block and return a new Data object
      end
      Data.new(@data.path, temp_data, has_error: @error)
    end


   
    def validate_and_convert_row row, row_index, column_type, allow_null
      # CSV.parse adjusts the size of each row to equal the size of the longest row 
      # by adding nil where necessary.
      raise InvalidRowLengthError, 
        "Row length does not match number of columns" unless row.size == @column_types.size

      @row = row.dup
      begin
        row.each_with_index do |field, field_index|
          @field = field
          @field_index = field_index

          if field.nil?
            @row[field_index] = validate_null(allow_null)
          else
            @row[field_index] = convert_type(column_type, field)
          end
        end
      rescue ArgumentError, NullNotAllowedError => e
        Logger.log(@data.path, :verify, e, value: @field, row: row_index+1, col: @field_index+1)
        @error = true
      end
      @row

    rescue InvalidRowLengthError => e
      Logger.log(@data.path, :verify, e, row: row_index+1)
      @error = true
      raise
    end



    # Helper methods ---------------------------------

    def convert_type column_type, field
      Converters[column_type][field]
    end


    def validate_null allow_null
      raise NullNotAllowedError, "NULL not allowed" unless allow_null == true
    end

  end
end


# Where Sequel's type conversion does not meet requirements
# Integer '2.3' => 2
# Integer 'xxx' => 0           # should throw exception

# Float 'xxx' => 0.0           # should throw exception

# Boolean 'xxx' => false       # should throw exception


# Where Sequel's type conversion is intelligent
# true, 'true', 'True'  => true  (note: only in Sqlite)

# How to convert
# Boolean:
# -- 'false', 'False', 0 => false
# -- 'true', 'True', 1 => true
# else: throw exception

# Integer:
# throw exception if Integer 'field' fails (do not just insert 0 as Sequel does)

# Float:
# throw exception if Float 'field' fails (do not just insert 0.0 as Sequel does)



# errors = {reading_file: [[path, 'error_message'],[...],...]
#           parsing_data: [path, 'error_message'], # FasterCSV provides line no. in error message.
#           converting_data: [path, 'error_message', row_index, field_index],
#           writing_data: [path, 'error_message', row_index]}



# Process Report
# There where errors with the following files:
# /home/sovonex/Desktop/false.csv
# http://www.sovonex.com/corrupt.csv
# /home/sovonex/me.csv
# /home/sovonex/you.csv

# The above files have NOT been written to the database yet.

# A detailed description of all errors found follows:
# /home/sovonex/Desktop/false.csv
# Verifying data:
# 1) "hello" at [row 2, field 1], ArgumentError: Error message 
# 2) "world" at [row 2, field 2], ArgumentError: Error message
# http://www.sovonex.com/corrupt.csv
# Writing data:
# 1)



# Note: The contents of the above listed files 
#       have NOT been written to the database
#       due to the following errors:

# Detailed listing of errors:
# /home/sovonex/Desktop/false.csv:     Reading file: 'original error message'
# http://www.sovonex.com/corrupt.csv   Parsing data: 'original error message'  
# /home/sovonex/me.csv                 Converting data: 'originial error message' at row x, field x # if convert error *)
#                                      Converting data: 'no of items does not match no of columns at row x   # if convert error


# /home/sovonex/you.csv                Writing data: 'original error message' 


# IDEA:
# Edit the error message right at the source of error using two methods:
# size_error_message default_size, acutal_size, row_index
# conversion_error_message original_error_message, row_index, field_index


