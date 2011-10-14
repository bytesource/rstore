# encoding: utf-8

require 'rstore/exceptions'

module RStore
  class Logger

    # class << self
    #   attr_accessor :error_queue
    # end

   
    # http://aberant.tumblr.com/post/4639094626/ruby-drive-by-autovivification
    # @error_queue = Hash.new {|h,k| h[k] = Hash.new(&h.default_proc)}
    # @error_queue = Hash.new {|h,k| h[k] = Hash.new{|h,k| h[k] = []}}

    # def self.log(path, state, error, optional_info={})
    #   main_info = Hash[:error, error.class, :message, error.to_s]
    #   main_info.merge!(optional_info)
    #   @error_queue[path][state] << main_info
    # end


    #def self.empty_error_queue
    #  @error_queue = Hash.new {|h,k| h[k] = Hash.new{|h,k| h[k] = []}}
    #end

    attr_accessor :data
    attr_accessor :message
    

    KnownStates = 
      {:fetch   => "loading files", 
       :parse   => "parsing file content",
       :convert => "converting field values into their corresponding datatypes",
       :store   => "storing file content into database"}



    def initialize data_object
      @data    = data_object
      @message = ''
    end


    def log state, error, loc={}
      raise ArgumentError "#{state} is an invalid state vor #{self.class}"  unless valid_state? state

      loc = correct_location(loc)

      type_of_error = error.class
      error_message = error.to_s
      location      = "Location     : #{location_to_s(loc)}" 
      location      = loc.empty? ? '' : location

      report = <<-TEXT.gsub(/^\s+/, '')
      An error occured while #{KnownStates[state]}:
      File         : #{@data.path} 
      Type of error: #{type_of_error} 
      Error message: #{error_message}
      #{location}
      =============
      Please fix the error and run again.
      NOTE: No data has been inserted into the database yet.
      =============
      TEXT

      @message = report
    end


    def error
      raise FileProcessingError, @message
    end


    # Helper methods ------------------------

    def location_to_s location
      location.map { |loc,val| "#{loc} #{val}" }.join(', ')
    end


    
    def correct_location location
 
      if location[:row]        # row_index
        row = correct_row(location[:row])
        if location[:col]      # col_index
          col = location[:col]+1
          {row: row, col: col}
        else
          {row: row}
        end
      else
        location
      end
    end


    def correct_row row
      # row = row_index, which starts at 0
      # Without headers: add 1 to row
      # With headers   : add another 1 to row as the header row had been already removed
      row = with_headers? ? row+2 : row+1
      row
    end


    def valid_state? state
      KnownStates.keys.any? { |val| val == state } 
    end


    def with_headers?
      @data.options[:file_options][:has_headers]
    end

  end
end




