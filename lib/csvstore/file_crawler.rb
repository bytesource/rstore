# encoding: utf-8

module CSVStore
  class FileCrawler

    class << self
      attr_accessor :file_queue
    end

    @file_queue = Hash.new {|h,k| h[k] = Hash.new {|h,k| h[k] = nil}}



         





  end
end
