# encoding: utf-8

module RStore
  class BaseTable

    class << self
      # A Hash holding subclasses of {RStore::BaseTable}
      # @return [Hash{Symbol=>BaseTable}] All subclasses of {RStore::BaseTable} defined in the current namespace.   
      #   Subclasses are added automatically via _self.inherited_.
      # @example
      #   class ProductsTable < RStore::BaseTable
      #     create #...
      #   end
      #
      #   class DataTable < RStore::BaseTable
      #     create #...
      #   end
      #
      #   RStore::BaseTable.table_classes
      #   #=> {:products=>ProductsTable, :data=>DataTable} 
      attr_reader :table_classes
    end

    @table_classes = Hash.new

    def self.inherited subclass
      BaseTable.table_classes[subclass.name] = subclass
    end


    # Define the table layout.
    # @note To be called when defining of a _subclass_ of {RStore::BaseTable}
    # @note You need to define an extra column for an auto-incrementing primary key.  
    # @yield The same block as {http://sequel.rubyforge.org/rdoc/classes/Sequel/Database.html#method-i-create_table Sequel::Database.create_table}.  
    # @return [void]
    # @example
    #  class ProductsTable < RStore::BaseTable
    #
    #    create do
    #      primary_key :id, :allow_null => false
    #      String      :product
    #      Integer     :quantity
    #      Float       :price
    #      Date        :created_at
    #      DateTime    :min_demand
    #      Time        :max_demand
    #      Boolean     :on_stock, :allow_null => false, :default => false
    #    end
    #  end
    def self.create &block
      class << self
        attr_reader :table_info
      end

      @table_info = block
    end


    # @return [Symbol] The lower-case class name without the _DB_ postfix
    # @example
    #  class CompanyDB < RStore::BaseDB
    #    info('postgres://user:password@localhost/blog')
    #  end
    #
    #  CompanyDB.name
    #  #=> :company

    
    # @return [Symbol] The lower-case class name without the _Table_ postfix
    # @example
    #  class ProductsTable < RStore::BaseTable
    #
    #    create do
    #      primary_key :id, :allow_null => false
    #      String      :product
    #      Integer     :quantity
    #      Float       :price
    #      Date        :created_at
    #      DateTime    :min_demand
    #      Time        :max_demand
    #      Boolean     :on_stock, :allow_null => false, :default => false
    #    end
    #  end
    #
    #  ProductsTable.name
    #  #=> :products
    def self.name  
      super.gsub!(/Table/,'').downcase.to_sym
    end
  end
end

