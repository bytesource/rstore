# encoding: utf-8

require 'csv'
require 'rstore/converter'
require 'rstore/storage'
require 'rstore/core_ext/object'

module RStore
  class Data

    attr_reader   :path
    attr_reader   :content
    attr_reader   :state
    attr_reader   :type
    attr_reader   :options


    KnownStates = [:raw, :parsed, :converted, :error]


    def initialize path, content, state, options={}
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

    def to_csv
      raise InvalidStateError, "#{state.inspect} is not a valid Data state for method 'to_csv'"  unless state == :raw

      csv = CSV.parse(@content, @options[:parse_options])
      Data.new(@path, csv, :parsed)
    end


    def convert database, table_name
      converted_data = Converter.new(self, database, table_name).convert

      Data.new(@path, converted_data, :converted)
    end


    def insert database, table_name
      Storage.new(self, database, table_name).insert
    end


    def state= state
      error_message = "#{state.inspect} is not a valid state. The following states are valid: #{print_valid_states}" 
      raise ArgumentError, error_message  unless KnownStates.include?(state)
      @state = state
    end


    def has_error?
      @state == :error
    end


    # Helper methods --------------------------------

    def print_valid_states
      KnownStates.map { |s| s.inspect }.join(', ')
    end

  end
end 
