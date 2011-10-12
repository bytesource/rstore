# encoding: utf-8

module RStore
  class Logger

    class << self
      attr_accessor :error_queue
    end

    KnownStates = 
      {:fetch   => "loading files", 
       :parse   => "parsing file content",
       :convert => "converting field values into their corresponding datatypes",
       :store   => "storing file content into database"}

    # http://aberant.tumblr.com/post/4639094626/ruby-drive-by-autovivification
    # @error_queue = Hash.new {|h,k| h[k] = Hash.new(&h.default_proc)}
    @error_queue = Hash.new {|h,k| h[k] = Hash.new{|h,k| h[k] = []}}

    def self.log(path, state, error, optional_info={})
      main_info = Hash[:error, error.class, :message, error.to_s]
      main_info.merge!(optional_info)
      @error_queue[path][state] << main_info
    end


    def self.empty_error_queue
      @error_queue = Hash.new {|h,k| h[k] = Hash.new{|h,k| h[k] = []}}
    end


    def self.print path, state, error, loc={}
      check_state
      type_of_error = error.class
      error_message = error.to_s
      location      = "Location:      #{location_to_s(loc)}" 
      location      = loc.size == 0 ? '' : location

      report = <<-TEXT.gsub(/^\s+/, '')
               "The following error occured on #{KnowStates[state]}:
               File:          #{path} 
               Type of error: #{type_of_error} 
               Error message: #{error_message}
               #{location}
               =============
               Please fix the error and run again.
               NOTE: No data has been inserted into the database yet."
               TEXT

               puts report
    end


    # Helper methods ------------------------

    def location_to_s location
      location.map { |loc,val| "#{loc} #{val}" }.join(', ')
    end

    def valid_state? state
      KnownStates.keys.any? { |val| val == state } 
    end
  end
end




