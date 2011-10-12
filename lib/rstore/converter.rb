# encoding: utf-8
require 'rstore/logger'
require 'rstore/exceptions'

require 'pry'

module RStore
  class Converter

    # @return [Hash<:convert => Array>]
    attr_accessor :error_queue
    # @ return [String] path of the given csv file
    # @return [Array<Array>] Array of array returned by CSV.parse
    attr_reader   :data
    # @return [Array<symbol>] Array of symbols representing the Ruby class set for each column
    attr_reader   :column_types
    # @return [Array<Boolean>] Array of boolean values indicating if NULL is allowed as a column value
    attr_reader   :allow_null
    attr_accessor :state

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


    def initialize data_object, database, table_name
      state   = data_object.state
      raise InvalidStateError, "#{state.inspect} is not a valid state for class Converter" unless state == :parsed
      @data   = data_object.clone
      @state  = @data.state
      @schema = database.schema(table_name)
      @column_types = extract_from_schema :type
      @allow_null   = extract_from_schema :allow_null
      @error  = false
    end


    def extract_from_schema target

      schema = @schema.dup
     
      # Delete primary key column entry
      schema.delete_if do |(_, property_hash)|
        property_hash[:primary_key] == true
      end

      schema.map do |(_, property_hash)|
        # Sequel handles Time as Datetime:
        type = property_hash[target]
        type = (type == :time) ? :datetime : type
        type
      end

    end


    # Returns @table with converted fields if no error is thrown, nil otherwise
    def convert
      temp_data = @data.content.dup

      begin
        @data.content.each_with_index do |row, row_index|

          temp_data[row_index] = convert_row(row, row_index)
        end
      rescue InvalidRowLengthError
        # Swallow this exception, then leave the begin..end block and return a new Data object
      end
      @state = :converted unless @state == :error
      Data.new(@data.path, temp_data, @state)
    end


   
    def convert_row row, row_index
      # CSV.parse adjusts the size of each row to equal the size of the longest row 
      # by adding nil where necessary.
      error_message = %q(Row length does not match number of columns. Please verify that:
                         1. The database table fits the csv table data
                         2. There is no primary key on a data column (you always need to 
                         define a separate column for an auto-incrementing primary key))
      raise InvalidRowLengthError, error_message unless row.size == @column_types.size

      @row = row.dup
      begin
        row.each_with_index do |field, field_index|
          @field = field
          @field_index = field_index

          if field.nil?
            @row[field_index] = validate_null(@allow_null[field_index])
          else
            @row[field_index] = convert_type(@column_types[field_index], field)
          end
        end
      rescue ArgumentError, NullNotAllowedError => e
        has_headers = @data.options[:file_options][:has_headers]
        row         = has_headers ? row_index+2 : row_index+1

        # already_found = already_found_error_in_col?(@data.path, :convert, @field_index+1) 

        Logger.log(@data.path, :convert, e, value: @field, row: row, col: @field_index+1) # unless already_found
        @state = :error
      end
      @row

    rescue InvalidRowLengthError => e
      Logger.log(@data.path, :convert, e, row: row_index+1)
      @state = :error
      raise
    end

    # Helper methods ---------------------------------


  #  def already_found_error_in_col? path, state, col_index
  #    logger = Logger.error_queue[path]
  #    if logger[state]
  #      !!(logger[state][col_index] == col_index)   # wrong because of :state => Array!!!!!!!
  #    else
  #      false
  #    end
  #  end

   #   {"/home/sovonex/Desktop/my_file.csv"=>
   #         {:store=>
   #          [{:error=>Sequel::InvalidValue,
   #            :message=>"ArgumentError: invalid date",
   #            :row=>2}]}}



    def convert_type column_type, field
      Converters[column_type][field]
    end


    def validate_null allow_null
      raise NullNotAllowedError, "NULL not allowed" unless allow_null == true
    end

  end
end
 
