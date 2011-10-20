# RStore 

### A library for batch processing csv files into a database 

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
# The 'from' method accepts a path to a file or directory as well as an URL.
# The 'to' metthod accepts a string of the form 'db_name.table_name'
RStore::CSV.new do
  from '../easter/children', :recursive => true
  from '../christmas/children/toys.csv'
  to   'company.products'
  run
end


# 4)
# Optional convenience method enabling you to use
# the main features of Sequel ODM with on your database table
RStore::CSV.connect_to('company.products') do |db, table|
  name = table.name

  db[name].all                                         # fetch everything (sample output below)
  db[name].filter(:id => 2).update(:on_stock => true)  # update entry
  db[name].filter(:id => 3).delete                     # delete entry
end

```
#### Special Features

* Batch processing of csv files
* Fetching data from different sources: files, directories, URLs
* Customizable using additional options
* Validation of field values. At the moment validation is supported for the following types:
  String, Integer, Float, Date, DateTime, Time, Boolean 

#### Database Requirements



