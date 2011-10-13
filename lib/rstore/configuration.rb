# encoding: utf-8
require 'rstore/core_ext/object'

module RStore
  class Configuration

    # Todo: Evaluate the correctness of values passes via file_options


    class << self
      attr_reader :default_file_options
      attr_reader :default_parse_options
      attr_reader :default_options
    end


    # Supported options
    @default_parse_options   = {row_sep: :auto, col_sep: ",", quote_char: '"', field_size_limit: nil, skip_blanks: false}.freeze
    @default_file_options    = {recursive: false, has_headers: true, selector: ''}
    @default_options         = {file_options: @default_file_options, parse_options: @default_parse_options}


    Validations = Hash.new { |h,k| lambda { |value| true }}.
      merge!({recursive:   lambda { |value| value.boolean_or_nil? },
              has_headers: lambda { |value| value.boolean_or_nil? },
              selector:    lambda { |value| value.is_a?(String) }})


    attr_reader   :file_options, :parse_options
    attr_reader   :path



    def initialize path, all_options
      all_options        = all_options.dup
      self.parse_options = all_options
      self.file_options  = all_options
      @path = path

      raise ArgumentError, arg_error_message(@path, all_options) if all_options.size > 0
    end


    def parse_options= all_options
      new_settings = extract_options(all_options, Configuration.default_parse_options)
      @parse_options = new_settings
    end


    def file_options= all_options
      new_settings = extract_options(all_options, Configuration.default_file_options)
      @file_options = Configuration.default_file_options.merge(new_settings)
    end


    def [] key
      target = instance_variables.find do |var|
        var.to_s.gsub(/@/,'').to_sym == key
      end
      if target
        instance_variable_get(target)
      else
        raise ArgumentError, "'#{key}' is not an instance variable"
      end
    end


    def self.update_default_file_options options
      raise ArgumentError, "#{options} must be an instance of Hash" unless options.is_a?(Hash)
      new_options = Configuration.default_file_options.merge(options)
      raise ArgumentError, "#{options} contains unknown option key" if new_options.size > Configuration.default_file_options.size
      new_options.each do |option, value|
        error_message = "'#{value}' (#{value.class}) is not a valid value for option #{option.inspect}"
        raise ArgumentError, error_message unless valid_value?(option, value)
      end
      @default_file_options = new_options
    end



    # Helper methods
    # ------------------------------------------

    def extract_options provided_options, supported_options

      provided_options_copy = provided_options.dup
      supported_options = supported_options.keys

      provided_options_copy.inject({}) do |extracted, (option, value)|
        if supported_options.include?(option)
          if Configuration.valid_value?(option, value)
            extracted[option] = value 
            provided_options.delete(option)
          else
            raise ArgumentError, "path #{@path}: '#{value}' (#{value.class}) is not a valid value for option #{option.inspect}"
          end
        end
      extracted
      end
    end


    def self.valid_value? option, value
      Validations[option][value]
    end


    def arg_error_message path, all_options
      keys = all_options.keys.join(', ')
      "Unsupported options: #{keys} for path '#{path}'"
    end


    # def only_keys seq
    #   seq.is_a?(Hash) ? seq.keys : seq
    # end


  end
end

 
