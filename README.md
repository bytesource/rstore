# RStore 

### A library for batch processing csv files into a database

Uses the CSV library for parsing and Sequel ORM for database managment.

### Special Features

* Batch processing of csv files
* Fetches data from different sources: files, directories, URLs
* Customizable using additional options (see section *Available Options* below for details)
* Validation of field values. At the moment validation of the following types is supported:
  * String, Integer, Float, Date, DateTime, Time, Boolean 
* Descriptive error messages pointing helping you to find any invalid data quickly.
* Safe transactions: Either all data of all files is inserted or none.
* You only need to write your database and table classes once. After that, just `require` them.


## Sample Usage

Sample csv file

> "product","quantity","price","created_at","min_demand","max_demand","on_stock"  
> "toy1","1","1.12","2011-2-4","1:30","1:30am","true"  
> "toy2","2","2.22","2012/2/4","2:30","2:30pm","false  
> "toy3","3","3.33","2013/2/4","3:30","3:30 a.m.","True  
> "toy4","4",,,"4:30","4:30 p.m.","False"  
> "toy4","5","5.55","2015-2-4","5:30","5:30AM","1"  
> "toy5","6","6.66","2016/2/4","6:30","6:30 P.M.","0"  
> "toy6","7","7.77",,,,"false"  

1) Load gem

``` ruby

require 'rstore/csv'

```

2) Store database information in a subclass of `RStore::BaseDB`  
Naming convention: name => NameDB

``` ruby
class CompanyDB < RStore::BaseDB

  # Same as Sequel.connect, except that you don't need to
  # provide the :database key.
  connect(:adapter  => 'mysql', 
          :host     => 'localhost',
          :user     => 'root',
          :password => 'xxx')
end

```

3) Store table information in a subclass of `RStore::BaseTable`  
Naming convention: name => NameDB

``` ruby
class ProductsTable < RStore::BaseTable

  # Same as #create in Sequel
  create do
    primary_key :id, :allow_null => false
    String      :product
    Integer     :quantity
    Float       :price
    Date        :created_at
    DateTime    :min_demand
    Time        :max_demand
    Boolean     :on_stock, :allow_null => false, :default => false
  end

end

```

**Note**:  
You can either put the database and table class definitions in the same file or store them  
anywhere you like just `require` them when you need them.


4) Enter csv data into the database  
The `from` method accepts a path to a file or directory as well as an URL.  
The `to` metthod accepts a string of the form *db_name.table_name*  

```ruby
RStore::CSV.new do
  from '../easter/children', :recursive => true                   # select a directory or
  from '../christmas/children/toys.csv'                           # file, or
  from 'www.example.com/sweets.csv', :selector => 'pre div.line'  # URL
  to   'company.products'                                         # provide database and table name
  run                                                             # run the program
end

```

Optional convenience method enabling you to use  
the main features of Sequel ODM with on your database table

```ruby
RStore::CSV.connect_to('company.products') do |db, table|    # db = Sequel database object, table = RStore::BaseTable object
  db[table.name].all                                         # fetch everything (sample output below)
  db[table.name].all[3]                                      # *)
  db[table.name].filter(:id => 2).update(:on_stock => true)  # update entry
  db[table.name].filter(:id => 3).delete                     # delete entry
end

```

*)
Output of `db[table.name].all[3]`

``` ruby 
# {:produce    => "string4",
#  :quantity   => 4,
#  :price      => nil,
#  :create_at  => nil,
#  :min_demand => <DateTime: 2011-10-25T04:30:00+00:00 (39293755/16,0/1,2299161)>,
#  :max_demand => <DateTime: 2011-10-25T16:30:00+00:00 (39293763/16,0/1,2299161)>,
#  :on_stock   => false}

```

## Available Options

`RStore::CSV#from` accepts two kinds of options, file options and parse options.

**File Options**  
File options are used for fetching csv data from a source. The following options are recognized:

* **:has_headers**, default: `true` 
    * When set to false, the first line of a file is processed as data, otherwise it is discarded.
* **:recursive**, default: `false` 
    * When set to true and a directory is given, recursively search for files. Non-csv files are skipped. 
* **:selector**, default: `""` 
    * Mandatory css selector with an URL. For more details please see the [Nokogiri documentation](http://nokogiri.org)
  
**Parse Options**  
Parse options are arguments to `CSV::parse`. The following options are recognized:

* **:col_sep**, default: `","`
    * The String placed between each field.
* **:row_sep**, default: `:auto`
    * The String appended to the end of each row.
* **:quote_char**, default: `'"'`
    * The character used to quote fields.
* **:field_size_limit**, default: `nil`
    * The maximum size CSV will read ahead looking for the closing quote for a field.
* **:skip_blanks**, default: `false`
    * When set to a true value, CSV will skip over any rows with no content.

More information on these options can be found at [CSV standard library documentation](http://ruby-doc.org/stdlib-1.9.2/libdoc/csv/rdoc/CSV.html#method-c-new)


## Database Requirements

1. Expects the database table to have an addition column storing an auto-incrementing primary key
2. Requires the database to support transactions:
    Most other database platforms support transactions natively.
    In MySQL, you'll need to be running InnoDB or BDB table types rather than the more common MyISAM. 





