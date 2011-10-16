# encoding: utf-8
require 'rstore/core_ext/object'

module RStore
  class Configuration

    class << self
      attr_reader :default_file_options
      attr_reader :default_parse_options
      attr_reader :default_options
    end


    # Supported options
    @default_file_options    = {recursive: false, has_headers: true, selector: ''}
    @default_parse_options   = {row_sep: :auto, col_sep: ",", quote_char: '"', field_size_limit: nil, skip_blanks: false}.freeze
    @default_options         = @default_file_options.merge(@default_parse_options)


    # Validations for RStore::CSV specific options
    # @default_parse_options will not be validated here, as validation occurs on calling CSV.parse
    Validations = Hash.new { |h,k| lambda { |value| true }}.
      merge!({recursive:   lambda { |value| value.boolean_or_nil? },
              has_headers: lambda { |value| value.boolean_or_nil? },
              selector:    lambda { |value| value.is_a?(String) }})


    attr_reader   :options
    attr_reader   :file_options
    attr_reader   :parse_options
    attr_reader   :path



    def initialize path, options
      new_options  = options.dup

      @path        = path
      self.options = new_options
      raise ArgumentError, arg_error_message(@path, new_options) if new_options.size > 0

      @file_options  = extract_with(Configuration.default_file_options)
      @parse_options = extract_with(Configuration.default_parse_options)
    end


    #def options= new_options
    #  result = new_options.dup.inject({}) do |acc, (option, value)|
    #    if self.default_options.include?(option)
    #      if self.valid_value?(option.value)
    #        acc[option] = value
    #        new_options.delete(option)
    #      else
    #        raise ArgumentError, "path #{@path}: '#{value}' (#{value.class}) is not a valid value for option #{option.inspect}"
    #      end
    #    end
    #  acc
    #  end

    #  @options = result
    #end

    def options= options

      new_options = Configuration.default_options.merge(options)

      result = new_options.inject({}) do |acc, (option, value)|
        if Configuration.default_options.include?(option)
          if Configuration.valid_value?(option, value)
            acc[option] = value
            options.delete(option)
          else
            raise ArgumentError, "path #{@path}: '#{value}' (#{value.class}) is not a valid value for option #{option.inspect}"
          end
        end
      acc
      end

      @options = result 
    end


    def extract_with options
      keys = options.keys
      @options.inject({}) do |acc, (option, value)|
        if keys.include?(option)
          acc[option] = value 
        end

      acc
      end
    end


    def self.change_default_options options
      raise ArgumentError, "#{options} must be an instance of Hash" unless options.is_a?(Hash)
      new_options = Configuration.default_options.merge(options)
      raise ArgumentError, "#{options} contains unknown option key" if new_options.size > Configuration.default_options.size
      new_options.each do |option, value|
        error_message = "'#{value}' (#{value.class}) is not a valid value for option #{option.inspect}"
        raise ArgumentError, error_message unless valid_value?(option, value)
      end

      @default_file_options = new_options
    end



    #def parse_options= new_options
    #  new_settings = extract_options(new_options, Configuration.default_parse_options)
    #  @parse_options = new_settings
    #end


    #def file_options= new_options
    #  new_settings = extract_options(new_options, Configuration.default_file_options)
    #  @file_options = Configuration.default_file_options.merge(new_settings)
    #end


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


    


    # Helper methods
    # ------------------------------------------

    #def extract_options provided_options, supported_options

    #  provided_options_copy = provided_options.dup
    #  supported_options = supported_options.keys

    #  provided_options_copy.inject({}) do |extracted, (option, value)|
    #    if supported_options.include?(option)
    #      if Configuration.valid_value?(option, value)
    #        extracted[option] = value 
    #        provided_options.delete(option)
    #      else
    #        raise ArgumentError, "path #{@path}: '#{value}' (#{value.class}) is not a valid value for option #{option.inspect}"
    #      end
    #    end
    #  extracted
    #  end
    #end

        




    #def extract_options default_options, new_options

    #  new_options = new_options.keys

    #  default_options.dup.inject({}) do |acc, (option, value)|
    #    if new_options.include?(option)
    #      if Configuration.valid_value?(option, value)
    #        acc[option] = value 
    #        default_options.delete(option)
    #      end
    #    else
    #      raise ArgumentError, "path #{@path}: '#{value}' (#{value.class}) is not a valid value for option #{option.inspect}"
    #    end
    #  acc
    #  end
    #end


    def self.valid_value? option, value
      Validations[option][value]
    end


    def arg_error_message path, new_options
      keys = new_options.keys.join(', ')
      "Unsupported options: #{keys} for path '#{path}'"
    end


  end
end

 
