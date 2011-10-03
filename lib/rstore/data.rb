# encoding: utf-8

require 'rstore/core_ext/object'

module RStore
  class Data

    attr_reader   :path
    attr_reader   :content
    attr_reader   :state
    attr_reader   :type


    KnownStates = [:parsed, :verified, :error]


    def initialize path, content, state
      @path      = path
      @content   = content
      self.state = state
      @type      = extract_type path
    end


    def extract_type path
      path, filename = File.split(path)
      filename.match(/\.(?<type>.*)$/)[:type].to_sym
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
