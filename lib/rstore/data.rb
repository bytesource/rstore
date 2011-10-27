# encoding: utf-8

require 'csv'
require 'rstore/converter'
require 'rstore/storage'
require 'rstore/core_ext/object'
require 'rstore/core_ext/csv_wrapper'

module RStore
  class Data

    attr_reader   :path
    attr_reader   :content
    attr_reader   :state
    attr_reader   :type
    attr_reader   :options


    KnownStates = [:raw, :parsed, :converted, :error]


    def initialize path, content, state, options
      error_message = "#{path}: The following options are not valid as an argument to #{self.class}:\n#{options}"
      raise ArgumentError, error_message  unless options.is_a?(Hash) 
      @path      = path
      @content   = content
      self.state = state
      @options   = options
      @type      = extract_type path
    end

  
    def extract_type path
      path, filename = File.split(path)
      filename.match(/\.(?<type>.*)$/)[:type].to_sym
    end

    def parse_csv
      raise InvalidStateError, "#{state.inspect} is not a valid Data state for method 'to_csv'"  unless state == :raw

      file_options  = @options[:file_options]
      parse_options = @options[:parse_options]

      begin
        csv = CSVWrapper.parse(@content, parse_options)
        csv = csv.drop(1)  if file_options[:has_headers] == true  # drop the first row if it is a header 
      rescue => e
        Logger.new(@options).print(@data.path, :parse, e)
      end

      @state = :parsed
        Data.new(@path, csv, @state, @options)
    end



    def convert_fields database, table_name
      converter = Converter.new(self, database, table_name)
      converter.convert
    end


    def into_db database, table_name
      Storage.new(self, database, table_name).insert
    end


    def state= state
      error_message = "#{state.inspect} is not a valid state. The following states are valid: #{print_valid_states}" 
      raise ArgumentError, error_message  unless KnownStates.include?(state)
      @state = state
    end

    # Helper methods --------------------------------

    def print_valid_states
      KnownStates.map { |s| s.inspect }.join(', ')
    end

  end
end 
 
