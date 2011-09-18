# encoding: utf-8

require 'spec_helper'
require 'csv'
require 'sequel'

describe CSVStore::Validator do

  # CSV content to be parsed by CSV class
  csv = <<-CSV.gsub(/^ +/, "")
  col1,col2,生日,col4,col5,col6,col7
  string1,,string3,string4,string5,string6,string7
  ,2,3,4,5,6,7
  1.12,,3.14,4.15,5.16,6.17,7.18
  2011-2-4,2012/2/4,2013/2/4,2014-2-4,2015-2-4,2016/2/4,
  1:30,,3:30pm,4:30,5:30am,6:30,7:30
  1:30,,3:30pm,4:30,5:30am,6:30,7:30
  true,false,True,False,1,0,true
  CSV

  # Create database table and retrieve the schema:
  DB = Sequel.sqlite

  unless DB.table_exists?(:test)
    DB.create_table :test do
      primary_key :id, allow_null: false
      String      :string_col
      Integer     :integer_col
      Float       :float_col
      Date        :date_col
      DateTime    :datetime_col
      Time        :time_col
      Boolean     :boolean_col
    end
  end

  content = CSV.parse(csv).drop(1)
  schema  = DB.schema(:test)
  path    = '/home/sovonex/Desktop/my_file.csv'

  let(:data)      { CSVStore::Data.new(path, content) }
  let(:validator) { described_class.new(data, schema) }


  context "Initialization" do

    it "should set all parameters correctly" do
      validator.data.content.should == content
      # Sequel handles Time as DateTime
      validator.column_types.should == [:string, :integer, :float, :date, :datetime, :datetime, :boolean]
      validator.allow_null.should   == [true, true, true, true, true, true, true]
      validator.error.should        == false
    end
  end

  context "Validation" do

    context "On Success" do

      context "#validate_and_convert_row" do

        it "should convert the items of a String column into the correct type" do
          row         = content.first
          row_index   = 0 # first row
          column_type = :string
          allow_null  = true

          validator.validate_and_convert_row(row, row_index, column_type, allow_null).should ==  
            ["string1", nil, "string3", "string4", "string5", "string6", "string7"]
          validator.error.should == false
        end

        it "should convert the items of an Integer column into the correct type" do
          row         = content[1]
          row_index   = 1 # second row
          column_type = :integer
          allow_null  = true

          validator.validate_and_convert_row(row, row_index, column_type, allow_null).should ==  
            [nil, 2, 3, 4, 5, 6,7]
          validator.error.should == false
        end

        it "should convert the items of a Float column into the correct type" do
          row         = content[2]
          row_index   = 2 # third row
          column_type = :float
          allow_null  = true

          validator.validate_and_convert_row(row, row_index, column_type, allow_null).should ==  
            [1.12,nil,3.14,4.15,5.16,6.17,7.18]
          validator.error.should == false
        end

        it "should convert the items of a Date column into the correct type" do
          row         = content[3]
          row_index   = 3 # fourth row
          column_type = :date
          allow_null  = true

          validator.validate_and_convert_row(row, row_index, column_type, allow_null).should ==
            ["2011-02-04", "2012-02-04", "2013-02-04", "2014-02-04", "2015-02-04", "2016-02-04", nil]
          validator.error.should == false
        end

        it "should convert the items of a DateTime column into the correct type" do
          row         = content[4]
          row_index   = 4 # fourth row
          column_type = :datetime
          allow_null  = true

          validator.validate_and_convert_row(row, row_index, column_type, allow_null).each do |item|
            if item.nil?
              nil
            else
              item.should == DateTime.parse(item).to_s
            end
          end
          validator.error.should == false
        end

        it "should convert the items of a Time column into the correct type" do
          row         = content[5]
          row_index   = 5 # sixth row
          column_type = :datetime
          allow_null  = true

          validator.validate_and_convert_row(row, row_index, column_type, allow_null).each do |item|
            if item.nil?
              nil
            else
              item.should == DateTime.parse(item).to_s
            end
          end
          validator.error.should == false
        end


        it "should convert the items of a Boolean column into the correct type" do
          row         = content[6]
          row_index   = 6 # seventh row
          column_type = :boolean
          allow_null  = true

          validator.validate_and_convert_row(row, row_index, column_type, allow_null).should ==  [true,false,true,false,true,false,true]
          validator.error.should == false
        end

      end
    end

    context "On Failure" do

        let(:empty_hash) { Hash.new {|h,k| h[k] = Hash.new{|h,k| h[k] = []}} }

      context "#validate_and_convert_row" do



        it "Integer column: return row as converted so far and log the error" do

          row         = content[1].dup
          row[3]      = 'xxx' # wrong value
          row_index   = 1
          column_type = :integer
          allow_null  = true

          validator.error.should == false
          validator.validate_and_convert_row(row, row_index, column_type, allow_null).should ==
            [nil, 2, 3, "xxx", "5", "6", "7"]

          CSVStore::Logger.error_queue.should == 
            {"/home/sovonex/Desktop/my_file.csv" => 
             {:verify=>
              [{:error=>ArgumentError,
                :message=>"invalid value for Integer(): \"xxx\"",
                :value=>"xxx",
                :row=>2,
                :col=>4}]}}

              validator.error.should == true
        end

        it "Float column: return row as converted so far and log the error" do

          row         = content[2].dup
          row[3]      = 'xxx' # wrong value
          row_index   = 1
          column_type = :float
          allow_null  = true
          CSVStore::Logger.error_queue = empty_hash

          validator.error.should == false
          validator.validate_and_convert_row(row, row_index, column_type, allow_null).should ==
            [1.12, nil, 3.14, "xxx", "5.16", "6.17", "7.18"]

          CSVStore::Logger.error_queue["/home/sovonex/Desktop/my_file.csv"][:verify].size.should == 1 

          validator.error.should == true
        end

        it "Date column: return row as converted so far and log the error" do

          row         = content[3].dup
          row[3]      = '2011-40-2' # wrong date
          row_index   = 1
          column_type = :date
          allow_null  = true
          CSVStore::Logger.error_queue = empty_hash

          validator.error.should == false
          validator.validate_and_convert_row(row, row_index, column_type, allow_null).should == 
            ["2011-02-04", "2012-02-04", "2013-02-04", "2011-40-2", "2015-2-4", "2016/2/4", nil]

          CSVStore::Logger.error_queue["/home/sovonex/Desktop/my_file.csv"][:verify].size.should == 1 
          validator.error.should == true
        end

        it "DateTime column: return row as converted so far and log the error" do

          row         = content[4].dup
          row[3]      = '7:61' # wrong time
          row_index   = 1
          column_type = :datetime
          allow_null  = true
          CSVStore::Logger.error_queue = empty_hash

          validator.error.should == false

          date_now = Time.now.to_s.match(/(?<date>.*?)\s/)[:date]
          validator.validate_and_convert_row(row, row_index, column_type, allow_null).should ==
            ["#{date_now}T01:30:00+00:00", nil, "#{date_now}T15:30:00+00:00", "7:61", "5:30am", "6:30", "7:30"]

          CSVStore::Logger.error_queue["/home/sovonex/Desktop/my_file.csv"][:verify].size.should == 1 
          validator.error.should == true
        end

        it "Time column: return row as converted so far and log the error" do

          row         = content[5].dup
          row[3]      = '7:61' # wrong time
          row_index   = 1
          column_type = :datetime
          allow_null  = true
          CSVStore::Logger.error_queue = empty_hash

          validator.error.should == false

          date_now = Time.now.to_s.match(/(?<date>.*?)\s/)[:date]
          result = validator.validate_and_convert_row(row, row_index, column_type, allow_null).should ==
            ["#{date_now}T01:30:00+00:00", nil, "#{date_now}T15:30:00+00:00", "7:61", "5:30am", "6:30", "7:30"]

          CSVStore::Logger.error_queue["/home/sovonex/Desktop/my_file.csv"][:verify].size.should == 1 
          validator.error.should == true
        end

        it "Boolean column: return row as converted so far and log the error" do

          row         = content[6].dup
          row[3]      = 'xxx' # wrong value
          row_index   = 1
          column_type = :boolean
          allow_null  = true
          CSVStore::Logger.error_queue = empty_hash

          validator.error.should == false
          validator.validate_and_convert_row(row, row_index, column_type, allow_null).should ==
            [true, false, true, "xxx", "1", "0", "true"]

          CSVStore::Logger.error_queue["/home/sovonex/Desktop/my_file.csv"][:verify].size.should == 1 

          validator.error.should == true
        end


        it "NULL value where null not allowed: return row as converted so far and log the error" do

          row         = content[6].dup
          row[3]      = nil  # NULL value
          row_index   = 1
          column_type = :boolean
          allow_null  = false  # no null values allowed
          CSVStore::Logger.error_queue = empty_hash

          validator.error.should == false
          validator.validate_and_convert_row(row, row_index, column_type, allow_null).should ==
            [true, false, true, nil, "1", "0", "true"]

          CSVStore::Logger.error_queue["/home/sovonex/Desktop/my_file.csv"][:verify].size.should == 1
          CSVStore::Logger.error_queue.should == 
            {"/home/sovonex/Desktop/my_file.csv"=>
             {:verify=>
              [{:error=>CSVStore::NullNotAllowedError,
                :message=>"NULL not allowed",
                :value=>nil,
                :row=>2,
                :col=>4}]}}


              validator.error.should == true
        end

      end

      context "#validate_and_convert" do


        it "Row length shorter than the number of columns: return new Data object with content converted so far and log the error" do

          short_row   = ["1.12", nil,"3.14", "4.15", "5.16", "6.17"]
          new_content = content.dup
          new_content[2] = short_row
          allow_null  = true

          new_data = CSVStore::Data.new(path, new_content) 
          new_validator = CSVStore::Validator.new(new_data, schema) 

          CSVStore::Logger.error_queue = empty_hash

          new_validator.error.should == false

          result = new_validator.validate_and_convert
          result.content.should == 
            [["string1", nil, "string3", "string4", "string5", "string6", "string7"],
             [nil, 2, 3, 4, 5, 6, 7],
             ["1.12", nil, "3.14", "4.15", "5.16", "6.17"], # row too short. No further validation from here
             ["2011-2-4", "2012/2/4", "2013/2/4", "2014-2-4", "2015-2-4", "2016/2/4", nil],
             ["1:30", nil, "3:30pm", "4:30", "5:30am", "6:30", "7:30"],
             ["1:30", nil, "3:30pm", "4:30", "5:30am", "6:30", "7:30"],
             ["true", "false", "True", "False", "1", "0", "true"]]


          result.error.should == true

          CSVStore::Logger.error_queue.should == 
            {"/home/sovonex/Desktop/my_file.csv"=>
             {:verify=>
              [{:error=>CSVStore::InvalidRowLengthError,
                :message=>"Row length does not match number of columns",
                :row=>3}]}}


              CSVStore::Logger.error_queue["/home/sovonex/Desktop/my_file.csv"][:verify].size.should == 1


              new_validator.error.should == true
        end

        it "Row length long than the number of columns: return new Data object with content converted so far and log the error" do

          long_row   = ["1.12", nil,"3.14", "4.15", "5.16", "6.17", "7.18", "8.19"]
          new_content = content.dup
          new_content[2] = long_row
          allow_null  = true

          new_data = CSVStore::Data.new(path, new_content) 
          new_validator = CSVStore::Validator.new(new_data, schema) 

          CSVStore::Logger.error_queue = empty_hash

          new_validator.error.should == false

          result = new_validator.validate_and_convert
          result.content.should == 
            [["string1", nil, "string3", "string4", "string5", "string6", "string7"],
             [nil, 2, 3, 4, 5, 6, 7],
             ["1.12", nil, "3.14", "4.15", "5.16", "6.17", "7.18", "8.19"], # row too long. No further validation from here
             ["2011-2-4", "2012/2/4", "2013/2/4", "2014-2-4", "2015-2-4", "2016/2/4", nil],
             ["1:30", nil, "3:30pm", "4:30", "5:30am", "6:30", "7:30"],
             ["1:30", nil, "3:30pm", "4:30", "5:30am", "6:30", "7:30"],
             ["true", "false", "True", "False", "1", "0", "true"]]
          
          result.error.should == true

          CSVStore::Logger.error_queue.should == 
            {"/home/sovonex/Desktop/my_file.csv"=>
             {:verify=>
              [{:error=>CSVStore::InvalidRowLengthError,
                :message=>"Row length does not match number of columns",
                :row=>3}]}}


              CSVStore::Logger.error_queue["/home/sovonex/Desktop/my_file.csv"][:verify].size.should == 1


              new_validator.error.should == true
        end
      end
    end
  end
end
