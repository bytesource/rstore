# encoding: utf-8

module RStore
  class BaseDB

    class << self
      attr_reader :db_classes # self = #<Class:RStore::BaseDB>
    end

    @db_classes = Hash.new     # self = RStore::BaseDB


    def self.inherited subclass
      BaseDB.db_classes[subclass.name] = subclass
    end

    def self.connect hash
      class << self            # self = #<Class:PlastronicsDB>
        attr_reader :connection_info
      end

      @connection_info = hash  # self = PlastronicsDB
    end

    def self.name  
      super.gsub!(/DB/,'').downcase.to_sym
    end

  end
end

