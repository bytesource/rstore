# encoding: utf-8

module CSVStore
  class Logger

    class << self
      attr_accessor :error_queue
    end

    # http://aberant.tumblr.com/post/4639094626/ruby-drive-by-autovivification
    # @error_queue = Hash.new {|h,k| h[k] = Hash.new(&h.default_proc)}
    @error_queue = Hash.new {|h,k| h[k] = Hash.new{|h,k| h[k] = []}}

    def self.log(path, step, error, optional_info)
      main_info = Hash[:error, error.class, :message, error.to_s]
      main_info.merge!(optional_info)
      @error_queue[path][step] << main_info
    end
  end
end

