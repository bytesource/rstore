# RStore 

### A library for batch processing csv files into a database 

Uses the CSV library for parsing and the fantastic Sequel ORM for database managment

#### Sample Usage

``` ruby

# Sample csv file:
# "product","quantity","price","created_at","min_demand","max_demand","on_stock"
# "toy1","1","1.12","2011-2-4","1:30","1:30am","true"
# "toy2","2","2.22","2012/2/4","2:30","2:30pm","false"
# "toy3","3","3.33","2013/2/4","3:30","3:30 a.m.","True"
# "toy4","4",,,"4:30","4:30 p.m.","False"
# "toy4","5","5.55","2015-2-4","5:30","5:30AM","1"
# "toy5","6","6.66","2016/2/4","6:30","6:30 P.M.","0"
# "toy6","7","7.77",,,,"false"


require 'rstore/csv'

# 1)
# Store database information in a subclass of RStore::BaseDB
# Naming convention: name => NameDB
class CompanyDB < RStore::BaseDB

  connect(:adapter => 'mysql', 
          :host     => 'localhost',
          :user     => 'root',
          :password => 'xxx')
end

# 2)
# Store table information in a subclass of RStore::BaseTable
# Naming convention: name => NameTable
class ProductsTable < RStore::BaseTable

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

# Note: 
# You can either put the database and table class definitions in the same file or store them 
# anywhere you like just 'require' them when you need them.


# 3) 
# Enter csv data into the database
# The 'from' method accepts a path to a directory, file, or URL.
# The 'to' metthod accepts a string of the form 'db_name.table_name'.
RStore::CSV.new do
  from '../easter/children', :recursive => true                   # select a directory or
  from '../christmas/children/toys.csv'                           # file, or
  from 'www.example.com/sweets.csv', :selector => 'pre div.line'  # URL
  to   'company.products'                                         # provide database and table name
  run                                                             # run the program
end




# 4)
# Optional convenience method enabling you to use
# the main features of Sequel ODM with on your database table
RStore::CSV.connect_to('company.products') do |db, table|  # db = Sequel database object, table = RStore BaseTable object
  db[table.name].all                                             # fetch everything (sample output below)
  db[table.name].filter(:id => 2).update(:on_stock => true)      # update entry
  db[table.name].filter(:id => 3).delete                         # delete entry
end

```
#### Special Features

* Batch processing of csv files
* Fetching data from different sources: files, directories, URLs
* Customizable using additional options
* Validation of field values. At the moment validation is supported for the following types:
  String, Integer, Float, Date, DateTime, Time, Boolean 
* Descriptive error messages pointing helping you to find any invalid data quickly.
* Either all data from all files is inserted or no data.

* Only write your database and table classes once

### Available Options

RStore::CSV uses two kinds of options, file options and parse options

**File Options**
File options are used when fetching csv data from a source. The following options are recognized:
*Option*          *Default*   *Description*
:has_headers        true      When set to false, the first line of a file is processed as data, otherwise it is discarded.
:recursive          false     When set to true and a directory is given, recursively search for files. Non-csv files are skipped. 
:selector           ''        Mandatory css selector a URL is given. For more details please see the [Nokogiri documentation](http://nokogiri.org)

**Parse Options**
Parse options are arguments to CSV.parse. The following options are recognized:
*Option*          *Default*   *Description*
:col_sep            ","       The String placed between each field.
:row_sep            :auto     The String appended to the end of each row.
:quote_char         '"'       The character used to quote fields.
:field_size_limit   nil       The maximum size CSV will read ahead looking for the closing quote for a field.
:skip_blanks        false     When set to a true value, CSV will skip over any rows with no content.

More information on these options can be found at [CSV standard library documentation](http://ruby-doc.org/stdlib-1.9.2/libdoc/csv/rdoc/CSV.html#method-c-new)





#### Database Requirements



