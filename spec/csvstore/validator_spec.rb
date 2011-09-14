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
  2011-2-4,2012/2/4,2013-2-4,2014-2-4,2015-2-4,2016-2-4,
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

      it "#validate_row: row of strings should return the expected result" do
        row         = content.first
        row_index   = 0 # first row
        column_type = :string
        allow_null  = true

        validator.validate_row(row, row_index, column_type, allow_null).should ==  
          ["string1", nil, "string3", "string4", "string5", "string6", "string7"]
        validator.error.should == false
      end

      it "#validate_row: row of integers should return the expected result" do
        row         = content[1]
        row_index   = 1 # second row
        column_type = :integer
        allow_null  = true

        validator.validate_row(row, row_index, column_type, allow_null).should ==  
          [nil, 2, 3, 4, 5, 6,7]
        validator.error.should == false
      end

      it "#validate_row: row of floats should return the expected result" do
        row         = content[2]
        row_index   = 2 # third row
        column_type = :float
        allow_null  = true

        validator.validate_row(row, row_index, column_type, allow_null).should ==  
          [1.12,nil,3.14,4.15,5.16,6.17,7.18]
        validator.error.should == false
      end

      it "#validate_row: row of booleans should return the expected result" do
        row         = content[6]
        row_index   = 6 # seventh row
        column_type = :boolean
        allow_null  = true

        validator.validate_row(row, row_index, column_type, allow_null).should ==  [true,false,true,false,true,false,true]
        validator.error.should == false
      end

      # it "temp test for failure:" do
      #   row         = content[5]
      #   row_index   = 5 # seventh row
      #   column_type = :boolean
      #   allow_null  = true

      #   pp CSVStore::Logger.error_queue
      #   validator.error.should == false
      #   validator.validate_row(row, row_index, column_type, allow_null).should ==  [true,false,true,false,true,false,true]
      # end
    end
  end
end



array = [[1,2,3],[4,5,6],[7,8,9]]


error_var = false
class ExTest

  @error_var = false
  @exceptions = []

  class MyException < ArgumentError; end

  def row row
    puts "error_var inside 'row': #{@error_var}"
    row.each do |item|
      raise MyException, "It's a five!" if item == 5
      puts "Number: #{item}"
    end
  rescue MyException => e
    puts "Found this exception:"
    puts e.class
    @error_var = true
    # @exceptions << e
    # execution continues immediately 
    # AFTER THE BEGIN BLOCK THAT SPAWNED IT, that is:
    # outside of 'row'
  rescue
    raise
  end
 
  # Try this
  # def row row
  #   temp_row = row
  #   begin
  #     ...
  #   rescue
  #     @error_var = true
  #     log_error error
  #   end
  #   # after 'each' or 'rescue'
  #   temp_row
  # end


  def table table
    table.each do |r|
      row r
    end

  end
end

ExTest.new.table array








