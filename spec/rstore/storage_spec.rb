# encoding: utf-8

require 'spec_helper'
require 'csv'

describe RStore::Storage do
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

  let(:data)      { RStore::Data.new(path, content) }
  let(:validator) { RStore::Validator.new(data, schema) }

  let(:storage)   { described_class.new(validator.data, DB, :test) }

  context "On initialization" do

    it "should set all variables correctly" do

      storage.data.content.should == validator.data.content
      # storage.prepared_data[6].should == nil



      RStore::Logger.error_queue.should be_empty
    end
  end
end
