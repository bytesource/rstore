# encoding: utf-8
require 'csvstore/core_ext/object'

module CSVStore
  class Configuration

    # Todo: Evaluate the correctness of values passes via file_options

    # Supported options
    KnownParseOptions   = [:row_sep, :col_sep, :quote_char, :field_size_limit, :skip_blanks].freeze
    KnownFileOptions    = [:recursive, :has_headers, :selector]

    Validations         = Hash.new { |h,k| lambda { |value| true }}.
      merge!({recursive:   lambda { |value| value.boolean_or_nil? },
              has_headers: lambda { |value| value.boolean_or_nil? },
              selector:    lambda { |value| value.is_a?(String) }})

    FileDefaults         = {recursive: false, has_headers: true}

    attr_reader :file_options, :parse_options
    attr_reader :path
    



    def initialize path, all_options
      all_options = all_options.dup
      self.parse_options = all_options
      self.file_options  = all_options
      @path = path

      raise ArgumentError, arg_error_message(@path, all_options) if all_options.size > 0
    end

    
    def parse_options= all_options
      new_settings = extract_options all_options, KnownParseOptions
      @parse_options = new_settings
    end

    # GO ON HERE AND CHECK THE INPUT VALUE!!!

   
    def file_options= all_options
      new_settings = extract_options all_options, KnownFileOptions
      @file_options = FileDefaults.merge(new_settings)
    end


    # Helper methods
    # ------------------------------------------

    def extract_options provided_options, supported_options

      provided_options_copy = provided_options.dup

      provided_options_copy.inject({}) do |extracted, (option, value)|
        if supported_options.include?(option)
          if valid_value?(option, value)
            extracted[option] = value 
            provided_options.delete(option)
          else
            raise ArgumentError, "path #{@path}: '#{value}' (#{value.class}) is not a valid value for option '#{option.to_s}'"
          end
        end
      extracted
      end
    end


    def valid_value? option, value
      Validations[option][value]
    end


    def arg_error_message path, all_options
      keys = all_options.keys.join(', ')
      "Unsupported options: #{keys} for path '#{path}'"
    end
 
  end
end

