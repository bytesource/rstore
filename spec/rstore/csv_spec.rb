# encoding: utf-8

require 'spec_helper'

describe RStore::CSV do

  # csv_data at path '../test_dir/dir_1/dir_2/test.csv':
  # "strings","integers","floats"
  # "string1","1","1.12"
  # "string2","2","2.22"

  class PlastronicsDB < RStore::BaseDB
    info(adapter: 'mysql', 
         host:    'localhost', 
         user:    'root', 
         password:'xxx')
  end

  class DataTable < RStore::BaseTable
    create do
      primary_key :id, :allow_null => false
      String      :col1
      Integer     :col2
      Float       :col3
    end
  end

# WGCI,"",CJV,774336218,16654904,"=""5772776577792""",79/99/72,5432103,73164359,4,ZG727999.PHN,E9792-,79/75/72,79/75/72,.77

 class FasterCSVTable < RStore::BaseTable
   create do
     primary_key :id, :allow_null => false
     String   :col1
     String   :col2
     String   :col3
     String   :col4
     String   :col5
     String   :col6
     String   :col7
     String   :col8
     String   :col9
     String   :col10
     String   :col11
     String   :col12
     String   :col13
     String   :col14
     String   :col15
   end
 end

  context "On initialization" do

    context "given a directory" do

      before(:each) do
        @name = DataTable.name 
        DB    = PlastronicsDB.connect
        DB.drop_table(@name)  if DB.table_exists?(@name)
      end

      context "on success" do

        it "should store the data into the table without errors" do

          store = RStore::CSV.new do
            from '../test_dir/dir_1', :recursive => true
            to   'plastronics.data'
            run
          end

          store.errors.empty?.should == true
          store.ran_once?.should == true

          DB = PlastronicsDB.connect
          DB[@name].all.should == 
            [{:id=>1, :col1=>"string1", :col2=>1, :col3=>1.12},
             {:id=>2, :col1=>"string2", :col2=>2, :col3=>2.22}]
        end
      end

      context "on failure" do

        context "when the content of one of the csv files loaded cannot be parsed" do

          # Directory struture:
          # test_dir/
          # -- csv.bad                # wrong file format (this file will not be loaded) 
          # -- empty.csv              # not really empty, but content is not valid csv (the error will be reported)
          # -- dir_1/
          # -- -- dir_2/
          # -- -- -- test.csv         # our target file (contents will be stored in database)

          it "should report the error, skip the file and continue with the remaining files" do

            store = RStore::CSV.new do
              from '../test_dir/', :recursive => true
              to   'plastronics.data'
              run
            end

            store.errors.empty?.should == false # has error
            store.ran_once?.should == true

            DB = PlastronicsDB.connect
            DB[@name].all.should == 
              [{:id=>1, :col1=>"string1", :col2=>1, :col3=>1.12},
               {:id=>2, :col1=>"string2", :col2=>2, :col3=>2.22}]

          end
        end

        context "when the value of an option is not valid" do

          it "should throw an exception and abort" do

            store = RStore::CSV.new do
              from '../test_dir/', :recursive => 'yes'
              to   'plastronics.data'
              run
            end
          end
        end
      end
    end
  end
end

    #context "given an URL" do

    #  name = FasterCSVTable.name 

    #  DB = PlastronicsDB.connect
    #  DB.drop_table(name) if DB.table_exists?(name)

    #  it "should store the data into the table without errors" do

    #    store2 = RStore::CSV.new do
    #      from 'http://github.com/circle/fastercsv/blob/master/test/test_data.csv', :selector => 'pre div.line', :skip_blanks => true
    #      to   'plastronics.fastercsv'
    #      run
    #    end

    #    store2.errors.empty?.should == true
    #    store2.ran_once?.should == true
    #    DB[name].first.should == 
    #      {:id=>1,
    #       :col1=>"GPNLWG",
    #       :col2=>"",
    #       :col3=>"PNX",
    #       :col4=>"994190320",
    #       :col5=>"5089227",
    #       :col6=>"=\"6996479699989\"",
    #       :col7=>"90/00/92",
    #       :col8=>"6452735",
    #       :col9=>"95784560",
    #       :col10=>"6",
    #       :col11=>"MG929000.OCS",
    #       :col12=>"W0902-",
    #       :col13=>"09/90/96",
    #       :col14=>"09/90/96",
    #       :col15=>"-002.59"}
 
