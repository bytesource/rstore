# encoding: utf-8

require 'pry'

module RStore
  class BaseDB

    class << self
      attr_reader :db_classes # self = #<Class:RStore::BaseDB>
    end

    @db_classes = Hash.new     # self = RStore::BaseDB


    def self.inherited subclass
      BaseDB.db_classes[subclass.name] = subclass
    end

    def self.connect hash_or_string
      # binding.pry
      class << self            # self = #<Class:PlastronicsDB>
        attr_reader :connection_info
      end
                               # self = PlastronicsDB
      @connection_info = hash_or_string.is_a?(Hash) ? hash_or_string.merge(:database => self.name.to_s): hash_or_string
    end

    def self.name  
      super.gsub!(/DB/,'').downcase.to_sym
    end

  end
end

