# encoding: utf-8

module CSVStore
  class BaseTable

    class << self
      attr_reader :table_classes
    end

    @table_classes = Hash.new

    def self.inherited subclass
      BaseTable.table_classes[subclass.name] = subclass
    end

    def self.create &block
      class << self
        attr_reader :table_info
      end

      @table_info = block
    end

    def self.name  
      super.gsub!(/Table/,'').downcase.to_sym
    end
  end
end

