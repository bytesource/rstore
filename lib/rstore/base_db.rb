# encoding: utf-8

require 'sequel'

module RStore
  class BaseDB

    class << self
      # A Hash holding subclasses of {RStore::BaseDB}
      # @return [Hash{Symbol=>BaseDB}] All subclasses of {RStore::BaseDB} defined in the current namespace.
      #   Subclasses are added automatically via _self.inherited_.
      # @example
      #   class CompanyDB < RStore::BaseDB
      #     info #...
      #   end
      #
      #   class MyDB < RStore::BaseDB
      #     info #...
      #   end
      #
      #   RStore::BaseDB.db_classes
      #   #=> {:company=>companyDB, :my=>MyDB}
      attr_reader :db_classes # self = #<Class:RStore::BaseDB>
    end

    @db_classes = Hash.new     # self = RStore::BaseDB


    def self.inherited subclass
      BaseDB.db_classes[subclass.name] = subclass
    end


    # Define the database connection.
    # @note To be called when defining a _subclass_ of {RStore::BaseDB}
    # Accepts the same _one_ _arity_ parameters as [Sequel.connect](http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html)
    # @overload info(options)
    #  @param [String, Hash] connection_info Either a connection string such as _postgres://user:password@localhost/blog_, or a `Hash` with the following options:
    #  @option options [String] :adapter The SQL database used, such as _mysql_ or _postgres_
    #  @option options [String] :host Example: 'localhost'
    #  @option options [String] :user
    #  @option options [String] :password
    #  @option options [String] :database The database name. You don't need to provide this option, as its value will be inferred from the class name.
    #  @return [void]
    # @example
    #  # Using a connection string
    #  class CompanyDB < RStore::BaseDB
    #    info('postgres://user:password@localhost/blog')
    #  end
    #
    #  # Using an options hash
    #  class CompanyDB < RStore::BaseDB
    #    info(adapter: 'mysql',
    #         host: 'localhost',
    #         user: 'root',
    #         password: 'xxx')
    #  end
    def self.info hash_or_string
      # self = CompanyDB

      class << self
        # self = #<Class:CompanyDB>
        attr_reader :connection_info
      end

      # Instance variables always belong to self.
      @connection_info = hash_or_string.is_a?(Hash) ? hash_or_string.merge(:database => self.name.to_s): hash_or_string
    end


    # Uses the connection info from {.info} to connect to the database.
    # @note To be called when defining a _subclass_ of {RStore::BaseDB}
    # @yieldparam [Sequel::Database] db The opened Sequel {http://sequel.rubyforge.org/rdoc/classes/Sequel/Database.html Database} object, which is closed when the block exits.
    # @return [void]
    # @example
    #  class CompanyDB < RStore::BaseDB
    #    info(adapter: 'mysql',
    #         host: 'localhost',
    #         user: 'root',
    #         password: 'xxx')
    #  end
    #
    #  class DataTable < RStore::BaseTable
    #    create do
    #      primary_key :id, :allow_null => false
    #      String      :col1
    #      Integer     :col2
    #      Float       :col3
    #    end
    #  end
    #
    #  name = DataTable.name
    #
    #  #Either
    #  DB = CompanyDB.connect
    #  DB.drop_table(name)
    #  DB.disconnect
    #
    #  #Or
    #  CompanyDB.connect do |db|
    #    db.drop_table(name)
    #  end
    def self.connect &block
      Sequel.connect(@connection_info, &block)
    end



    # @return [Symbol] The lower-case class name without the _DB_ postfix
    # @example
    #  class CompanyDB < RStore::BaseDB
    #    info('postgres://user:password@localhost/blog')
    #  end
    #
    #  CompanyDB.name
    #  #=> :company
    def self.name
      super.gsub!(/DB/,'').downcase.to_sym
    end

  end
end

