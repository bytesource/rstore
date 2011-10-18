# encoding: utf-8

require 'spec_helper'
require 'csv'

describe RStore::Storage do
  include HelperMethods

  # CSV content to be parsed by CSV class
  csv = <<-CSV.gsub(/^ +/, "")
  "strings","integers","floats","dates","datetimes","times","booleans"
  "string1","1","1.12","2011-2-4","1:30","1:30am",
  "string2","2","2.22","2012/2/4","2:30","2:30pm","false"
  ,"3","3.33","2013/2/4","3:30","3:30 a.m.","True"
  "string4","4",,,"4:30","4:30 p.m.","False"
  "string5","5","5.55","2015-2-4","5:30","5:30AM","1"
  "string6","6","6.66","2016/2/4","6:30","6:30 P.M.","0"
  "string7","7","7.77",,,,
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
  options = RStore::Configuration.default_options

  let(:data)      { RStore::Data.new(path, content, :parsed, options) }
  let(:converter) { RStore::Converter.new(data, DB, :test) }

  let(:storage)   { described_class.new(converter.convert, DB, :test) }

  context "On initialization" do

    context "on success" do

      it "should set all variables correctly" do

        storage.data.content.should == converter.convert.content
        storage.primary_key.should  == :id

        prep = storage.prepared_data
        prep.size.should == 7
        storage.prepared_data[3].should ==
          {:string_col=>"string4",
           :integer_col=>4,
           :float_col=>nil,
           :date_col=>nil,
           :datetime_col=>dt('04:30'),
           :time_col=>dt('16:30'),
           :boolean_col=>false}

      end
    end

    context "on failure" do

      it "should raise exception if the state of the Data object passed is not :converted" do

        lambda { described_class.new(data, DB, :test) }.should raise_exception(/not a valid state on initialization for class Storage/)
      end
    end
  end

  context :insert do


    context "on failure" do

      data      =  RStore::Data.new(path, content, :parsed, options)
      converter =  RStore::Converter.new(data, DB, :test) 

      validated_data = converter.convert
      pp validated_data.content[1][3]
      puts "--------------------"
      validated_data.content[1][3] = 'xxx'   # 4 -> 'xxx'
      pp validated_data.content[1][3]
      validated_data_with_error = validated_data

      let(:storage)   { described_class.new(validated_data_with_error, DB, :test) }


      it "should log the error and roll back the data already inserted from the current file" do

        lambda do
        storage.insert
        end.should raise_exception(RStore::FileProcessingError, /row 3[^,]/)

        DB[:test].all.should == []
        
      end
    end


    context "on success" do

      it "should insert all data into the database table" do

        storage.insert
        types = DB[:test].all[0].map do |k,v|
          v.class
        end
        types.should == [Fixnum, String, Fixnum, Float, Date, Time, Time, NilClass]


        #   {:id=>1,
        #    :string_col=>"string1",
        #    :integer_col=>1,
        #    :float_col=>1.12,
        #    :date_col=>#<Date: 2011-02-04 (4911193/2,0,2299161)>,
        # :datetime_col=>2011-10-05 09:30:00 +0800,
        #   :time_col=>2011-10-05 09:30:00 +0800,
        #   :boolean_col=>nil}
        # [Fixnum, String, Fixnum, Float, Date, Time, Time, NilClass]


      end
    end
  end
end




