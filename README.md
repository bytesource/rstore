# RStore

### A library for easy batch storage of csv data into a database

Uses the CSV standard library for parsing, *Nokogiri* for URL handling, and *Sequel* ORM for database management.

## Special Features

* **Batch processing** of csv files
* Fetches data from different sources: **files, directories, URLs**
* **Customizable** using additional options (also see section *Available Options*)
* **Validation of field values**. At the moment validation of the following types is supported:
  * `String`, `Integer`, `Float`, `Date`, `DateTime`, `Time`, and `Boolean`
* **Descriptive error messages** pointing helping you to find any invalid data quickly.
* Only define your database and table classes once, then just `require` them when needed.
* **Safe and transparent data storage**:
  * Using database transactions: Either the data from all all files is stored or none (also see section *Database Requirements*)
  * To avoid double entry of data, the `run` method can only be run once on a single instance of `RStore::CSV`.


## Database Requirements

1. Expects the database table to have an addition column storing an auto-incrementing primary key.
2. **Requires the database to support transactions**:
   Most other database platforms support transactions natively.
   In MySQL, you'll need to be running `InnoDB` or `BDB` table types rather than the more common `MyISAM`.
   If you are using MySQL and the table has not been created yet, RStore::CSV will take care of using the
   correct table type upon creation.


## Installation

``` bash
$ gem install rstore
```

**Note**:
As `RStore` depends on [Nokogiri](http://nokogiri.org/) for fetching data from URLs, you need to install Nokogiri first to use this feature.
However, on some operating systems there can be problems due to missing libraries,
so you might want to take a look at the following installation instructions:

**Debian**
Users of Debian Linux (e.g. Ubuntu) need to run:

``` bash
$ sudo apt-get install libxslt1-dev libxml2-dev

$ gem install nokogiri

```

**Mac OS X**
The following instruction should work, but I haven't tested them personally

``` bash
$ sudo port install libxml2 libxslt

$ gem install nokogiri

```

Source: [Installing Nokogiri](http://nokogiri.org/tutorials/installing_nokogiri.html)

If you have any difficulties installing Nokogiri, please let me know, so that I can help you.


## Public API Documentation

The documentation is hosted on *RubyDoc.info*: [RStore Public API documentation](http://rubydoc.info/github/bytesource/rstore).


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
  info(:adapter  => 'mysql',
       :host     => 'localhost',
       :user     => 'root',
       :password => 'xxx')

end

```

3) Store table information in a subclass of `RStore::BaseTable`
Naming convention: name => NameTable

``` ruby

class ProductsTable < RStore::BaseTable

  # Specify the database table the same way
  # you do in Sequel
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
You can put the database and table class definitions in separate files
and `require` them when needed.


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
### Additional Features
---

You can change and reset the default options (see section *Available Options* below for details)

``` ruby
# Search directories recursively and handle the first row of a file as data by default
RStore::CSV.change_default_options(:recursive => true, :has_headers => false)

RStore::CSV.new do
  from 'dir1'
  from 'dir2'
  from 'dir3'
  to   'company.products'
  run
end

# Restore default options
RStore::CSV.reset_default_options

```

There is also a convenience method enabling you to use
all of [Sequels query methods](http://sequel.rubyforge.org/rdoc/files/doc/querying_rdoc.html).

``` ruby
RStore::CSV.query('company.products') do |table|    # table = Sequel::Dataset object
  table.all                                         # fetch everything
  table.all[3]                                      # fetch row number 4 (see output below)
  table.filter(:id => 2).update(:on_stock => true)  # update entry
  table.filter(:id => 3).delete                     # delete entry
end

```

*)
Output of `db[table.name].all[3]`

``` ruby
# {:product     => "toy4",
#  :quantity    => 4,
#  :price       => nil,
#  :created_at  => nil,
#  :min_demand  => <DateTime: 2011-10-25T04:30:00+00:00 (39293755/16,0/1,2299161)>,
#  :max_demand  => <DateTime: 2011-10-25T16:30:00+00:00 (39293763/16,0/1,2299161)>,
#  :on_stock    => false}

```

Access all of Sequels functionality by using the convenience methods
`BaseDB.connect`, `BaseTable.name`, and `BaseTable.table_info`:

``` ruby

DB     = CompanyDB.connect           # Open connection to 'company' database
name   = ProductTable.name           # Table name, :products, used as an argument to the following methods.
layout = ProductsTable.table_info    # The Proc that was passed to ProductsTable.create

DB.create_table(name, &layout)       # Create table

DB.alter_table name do               # Alter table
  drop_column :created_at
  add_column  :entry_date, :date
end

DB.drop_table(name)                  # Drop table

```


## Available Options

The method `from` accepts two kinds of options, file options and parse options:

### File Options
File options are used for fetching csv data from a source. The following options are recognized:

* **:has_headers**, default: `true`
    * When set to false, the first line of a file is processed as data, otherwise it is discarded.
* **:recursive**, default: `false`
    * When set to true and a directory is given, recursively search for files. Non-csv files are skipped.
* **:digit_seps**, default `[',', '.']`
    * The *thousands separator* and *decimal mark* used for numbers in the data source. Different countries use different thousands separators
      and decimal marks, and setting this options ensures that parsing of these numbers succeeds. Note that all numbers will still be
      *stored* in the format that Ruby recognizes, that is with a point (.) as the decimal mark.
* **:selector**, default: `""`
    * Mandatory css selector when fetching data from an URL. For more details please see the section *Further Reading* below


### Parse Options
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

For more information on the parse options, please see section *Further Reading* below.


## Further Reading

* Sequel
  * [Cheat sheet][sequel_cheat]
  * [Connecting to a database][sequel_connect]
  * [Querying][sequel_query]
* CSV
  * [Parse options documentation][csv_options]
  * [Common Format and MIME Type][csv_standard] for Comma-Separated Values (CSV) Files
* Nokogiri
  * [Project Site][nokogiri_home]

[sequel_cheat]: http://sequel.rubyforge.org/rdoc/files/doc/cheat_sheet_rdoc.html
[sequel_connect]: http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html
[sequel_query]: http://sequel.rubyforge.org/rdoc/files/doc/querying_rdoc.html
[csv_options]: http://ruby-doc.org/stdlib-1.9.2/libdoc/csv/rdoc/CSV.html#method-c-new
[csv_standard]: http://www.ietf.org/rfc/rfc4180.txt
[nokogiri_home]: http://nokogiri.org/


## Feedback

Any suggestions or criticism are highly welcome! Whatever your feedback, it will help me make this gem better!





