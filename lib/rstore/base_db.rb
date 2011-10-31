# encoding: utf-8

require 'sequel'

module RStore
  class BaseDB

    class << self
      attr_reader :db_classes # self = #<Class:RStore::BaseDB>
    end

    @db_classes = Hash.new     # self = RStore::BaseDB


    def self.inherited subclass
      BaseDB.db_classes[subclass.name] = subclass
    end

    # Define the database connection
    # Accepts the same _one_ _arity_ parameters as [Sequel.connect](http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html)
    # @param [Hash] connection_info Either a connection string such as `'postgres://user:password@localhost/blog'` or a `Hash` with the following options:
    # @option connection_info [String] :adapter The SQL database used, such as _'mysql'_ or _'postgres'_ 
    # @option connection_info [String] :host Example: 'localhost'
    # @return [void]
    # @example
    #  class PlastronicsDB < RStore::BaseDB
    #    info(adapter: 'mysql', 
    #         host: 'localhost', 
    #         user: 'root', 
    #         password: 'xxx')
    #    end



    # Define the database connection
    # Accepts the same _one_ _arity_ parameters as [Sequel.connect](http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html)
    # @overload info(options)
    #  @param [String, Hash] connection_info Either a connection string such as _postgres://user:password@localhost/blog_, or a `Hash` with the following options:
    #  @option options [String] :adapter The SQL database used, such as _mysql_ or _postgres_ 
    #  @option options [String] :host Example: 'localhost'
    #  @option options [String] :user 
    #  @option options [String] :password 
    #  @option options [String] :database The database name. You don't need to provide this option, as its value will be inferred from the class name. 
    # @return [void]
    # @example
    #  class PlastronicsDB < RStore::BaseDB
    #    info(adapter: 'mysql', 
    #         host: 'localhost', 
    #         user: 'root', 
    #         password: 'xxx')
    #    end
    def self.info hash_or_string
      class << self            # self = #<Class:PlastronicsDB>
        attr_reader :connection_info
      end
                               # self = PlastronicsDB
      @connection_info = hash_or_string.is_a?(Hash) ? hash_or_string.merge(:database => self.name.to_s): hash_or_string
    end


    def self.connect &block
      Sequel.connect(@connection_info, &block)
    end



    def self.name  
      super.gsub!(/DB/,'').downcase.to_sym
    end

  end
end
 
