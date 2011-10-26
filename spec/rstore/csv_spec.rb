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

    before(:each) do
      @name = DataTable.name 
      DB    = PlastronicsDB.connect
      DB.drop_table(@name)  if DB.table_exists?(@name)
    end

    context "on success" do

      context "when given a directory" do

        it "should store the data into the table without errors" do

          store = RStore::CSV.new do
            from '../test_dir/dir_1', :recursive => true
            to   'plastronics.data'
            run
          end

          store.ran_once?.should == true

          RStore::CSV.query('plastronics.data') do |table|
            table.all.should == 
              [{:id=>1, :col1=>"string1", :col2=>1, :col3=>1.12},
               {:id=>2, :col1=>"string2", :col2=>2, :col3=>2.22}]
          end
        end

        context "when calling #to before #from" do

          it "should store the data into the table without errors" do

            store = RStore::CSV.new do
              to   'plastronics.data'
              from '../test_dir/dir_1', :recursive => true
              run
            end

            store.ran_once?.should == true

            RStore::CSV.query('plastronics.data') do |table|
              table.all.should == 
                [{:id=>1, :col1=>"string1", :col2=>1, :col3=>1.12},
                 {:id=>2, :col1=>"string2", :col2=>2, :col3=>2.22}]
            end
          end
        end

        context "when calling #run more than once on the same instance" do

          it "should store the data into the table only once" do

            store = RStore::CSV.new do
              to   'plastronics.data'
              from '../test_dir/dir_1', :recursive => true
              run
              run      # calling #run a second time
            end

            store.run  # calling #run a third time

            store.ran_once?.should == true

            RStore::CSV.query('plastronics.data') do |table|
              table.all.should == 
                [{:id=>1, :col1=>"string1", :col2=>1, :col3=>1.12},
                 {:id=>2, :col1=>"string2", :col2=>2, :col3=>2.22}]
            end
          end
        end

        context "when changing default options" do

          it "should store the data into the table without errors" do

            RStore::CSV.change_default_options(:recursive => true) 

            store = RStore::CSV.new do
              from '../test_dir/dir_1'
              to   'plastronics.data'
              run
            end

            store.ran_once?.should == true

            RStore::CSV.query('plastronics.data') do |table|
              table.all.should == 
                [{:id=>1, :col1=>"string1", :col2=>1, :col3=>1.12},
                 {:id=>2, :col1=>"string2", :col2=>2, :col3=>2.22}]
            end

            RStore::CSV.reset_default_options
          end
        end

        context "when using more than one #from function" do

          it "should store the data from all files into the table without errors" do

            store = RStore::CSV.new do
              from '../test_dir/dir_1', :recursive => true
              from '../test_dir/dir_a/test.csv'
              to   'plastronics.data'
              run
            end

            store.ran_once?.should == true

            RStore::CSV.query('plastronics.data') do |table|
              table.all.should == 
                [{:id=>1, :col1=>"string1", :col2=>1, :col3=>1.12},
                 {:id=>2, :col1=>"string2", :col2=>2, :col3=>2.22},
                 {:id=>3, :col1=>"string1", :col2=>1, :col3=>1.12},
                 {:id=>4, :col1=>"string2", :col2=>2, :col3=>2.22}]
            end
          end
        end
      end

      context "on failure" do

        context "when method #from is missing" do

          it "should throw an exception" do

            # As #from is missing, no table won't be created automatically.
            DB   = PlastronicsDB.connect
            name = DataTable.name
            info = DataTable.table_info

            DB.create_table(name, &info)

            lambda do
              RStore::CSV.new do
                #from '../test_dir/dir_1'
                to   'plastronics.data'
                run
              end
            end.should raise_exception(Exception, /At least one method 'from' has to be called/)

            DB[@name].all.should be_empty 

          end
        end

        context "when method #to is missing" do

          it "should throw an exception" do

            #run will not be called, so table 'plastronics.data' does not exist (as it had been dropped in #before(:each)
            DB   = PlastronicsDB.connect
            name = DataTable.name
            info = DataTable.table_info

            DB.create_table(name, &info)


            lambda do
              RStore::CSV.new do
                from '../test_dir/dir_1'
                #to   'plastronics.data'
                run
              end
            end.should raise_exception(Exception, /Method 'to' has to be called before method 'run'/)

            DB[@name].all.should be_empty 
          end
        end

        context "when the content of one of the csv files loaded cannot be parsed" do

          # Directory structure: 
          # test_dir/
          # -- dir_a/ 
          # -- -- test.csv            # csv file with valid content
          # -- -- dir_b/
          # -- -- -- dir_c/
          # -- -- -- not_valid.csv    # csv file whose's content is not valid

          #NOTE: The valid data of 'test.csv' will be inserted into the database BEFORE the error in 'not_valid.csv'
          #      is encountered. Therefore a roll-back has to set the state of the database to before RStore::CSV was called.  

          it "should raise an exception, report the error and roll back any data already inserted into the database" do

            @error_path = "#{File.expand_path('../test_dir/dir_a/dir_b/dir_c/not_valid.csv')}"

            lambda do
              RStore::CSV.new do
                from '../test_dir/dir_a/', :recursive => true
                to   'plastronics.data'
                run
              end
            end.should raise_exception(RStore::FileProcessingError, /#{@error_path}/)


            RStore::CSV.query('plastronics.data') do |table|
              table.all.should be_empty
            end

          end
        end

        context "when the value of an option is not valid" do

          it "should throw an exception and abort" do

            lambda do
              store = RStore::CSV.new do
                from '../test_dir/', :recursive => 'yes'
                to   'plastronics.data'
                run
              end
            end.should raise_exception(ArgumentError, /yes/)
          end
        end
      end
    end
  end

  context :insert_all do

    context "on failure" do

      before(:each) do
        @name = DataTable.name 
        DB    = PlastronicsDB.connect
        DB.drop_table(@name)  if DB.table_exists?(@name)
      end

      it "should raise an exception, report the error and roll back any data already inserted into the database" do

        store = RStore::CSV.new do
          from '../test_dir/dir_1', :recursive => true
          to   'plastronics.data'
        end

        db    = store.database.connect
        store.create_table db
        table = store.table
        name  = table.name

        options = RStore::Configuration.default_options

        # Mocking up a Data objects with converted content
        content = [
          [["string1", 1, 1.12], ["string2", 2, 2.22]],   # correctly converted content
          [["string1", 1, 1.12], ["string2", 2, 2.22]],   # correctly converted content
          [["string1", 1, 1.12], ["string2", 2, :error]]] # Sequel will throw an exception on :error

          data_array = content.map do |csv|
            RStore::Data.new('dummy_path.csv', csv, :converted, options)
          end

          prepared_content = 
            [{:col1=>"string1", :col2=>1, :col3=>1.12}, 
             {:col1=>"string2", :col2=>2, :col3=>2.22}, 
             {:col1=>"string3", :col2=>1, :col3=>1.12}, 
             {:col1=>"string4", :col2=>2, :col3=>2.22}, 
             {:col1=>"string5", :col2=>2, :col3=>:invalid}, 
             {:col1=>"string6", :col2=>1, :col3=>1.12}]


          DB = Sequel.connect(adapter: 'mysql', 
                              host:    'localhost', 
                              database:'plastronics', 
                              user:    'root', 
                              password:'moinmoin')


          unless DB.table_exists?(:data)
            DB.create_table(:data) do
              primary_key :id, :allow_null => false
              String      :col1
              Integer     :col2
              Float       :col3
            end
          end

          dataset = DB[:data]

          lambda do
            DB.transaction do
              dataset.insert(prepared_content[0])
              dataset.insert(prepared_content[1])
              dataset.insert(prepared_content[4])
            end
          end.should raise_exception  # OK

          DB[:data].all.should == []

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

#    store2.ran_once?.should == true
#    RStore::CSV.query('plastronics.fastercsv') do |table|
#      table.first.should == 
#        {:id=>1,
#         :col1=>"GPNLWG",
#         :col2=>"",
#         :col3=>"PNX",
#         :col4=>"994190320",
#         :col5=>"5089227",
#         :col6=>"=\"6996479699989\"",
#         :col7=>"90/00/92",
#         :col8=>"6452735",
#         :col9=>"95784560",
#         :col10=>"6",
#         :col11=>"MG929000.OCS",
#         :col12=>"W0902-",
#         :col13=>"09/90/96",
#         :col14=>"09/90/96",
#         :col15=>"-002.59"}
#    end
#
