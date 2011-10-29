# encoding: utf-8
require 'rstore/logger'
require 'bigdecimal'

module RStore
  class Converter

    # @return [Date]
    attr_reader   :data
    # @return [Array<symbol>] Array of symbols representing the Ruby class set for each table column
    attr_reader   :column_types
    # @return [Array<Boolean>] Array of boolean values indicating if NULL is allowed as a column value
    attr_reader   :allow_null
    # @return [:symbol]
    # On intitialization the only allowed value is :parsed.
    # Will be set to :converted on successfull conversion.
    attr_accessor :state

    
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

    #  Converters used to verify the field data is valid. 
    #  If a conversion fails, an exception is thrown together
    #  with a descriptive error message pointing to the field 
    #  where the error occured.
    Converters = Hash.new {|h,k| h[k] = lambda { |field| field }}.
      merge!({string:     lambda { |field| field },
              date:       lambda { |field| Date.parse(field).to_s },
              datetime:   lambda { |field| DateTime.parse(field).to_s }, 
              # Convert to DateTime, because DateTime also checks if the argument is valid
              time:       lambda { |field| DateTime.parse(field).to_s },
              integer:    lambda { |field| Integer(field) },
              float:      lambda { |field| Float(field) },
              numeric:    lambda { |field| Float(field) },  # Handle Numeric as Float
              # Check with Float first, then convert, because Float throws an error on invalid values such as 'x'.
              bigdecimal: lambda { |field| Float(field); BigDecimal.new(field)},
              boolean:    lambda { |field| boolean_converter[field] }})


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
        #type = (type == :time) ? :datetime : type
        type
      end
    end


    # Returns @table with converted fields if no error is thrown, nil otherwise
    def convert
      content = @data.content.dup

      converted = content.each_with_index.map do |row, row_index|

        convert_row(row, row_index)
      end
      @state = :converted 
      Data.new(@data.path, converted, @state, @data.options)
    end


   
    def convert_row row, row_index
      # CSV.parse adjusts the size of each row to equal the size of the longest row 
      # by adding nil where necessary.
      error_message = <<-ERROR.gsub(/^\s+/,'')
      Row length does not match number of columns. Please verify that:
      1. The database table fits the csv table data
      2. There is no primary key on a data column (you always need to 
      define a separate column for an auto-incrementing primary key)
      ERROR

      raise InvalidRowLengthError, error_message unless row.size == @column_types.size

      begin
        row.each_with_index.map do |field, field_index|
          @field_index = field_index

          if field.nil?
            validate_null(@allow_null[field_index], field)
          else
            convert_type(@column_types[field_index], field)
          end
        end
      rescue ArgumentError, NullNotAllowedError => e
        logger = Logger.new(@data)
        logger.log(:convert, e, row: row_index, col: @field_index)
        logger.error
      end

    rescue InvalidRowLengthError => e
      logger = Logger.new(@data)
      logger.log(:convert, e, row: row_index)
      logger.error
    end


    # Helper methods ---------------------------------



    def convert_type column_type, field
      Converters[column_type][field]
    end


    def validate_null allow_null, field
      raise NullNotAllowedError, "NULL value (empty field) not allowed" unless allow_null == true
      field
    end

  end
end
 
