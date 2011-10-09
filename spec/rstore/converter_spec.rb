# encoding: utf-8

require 'spec_helper'
require 'csv'
require 'sequel'


describe RStore::Converter do
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

  content = CSV.parse(csv).drop(1)  # remove header row
  schema  = DB.schema(:test)
  path    = '/home/sovonex/Desktop/my_file.csv'

  let(:data)      { RStore::Data.new(path, content, :parsed) }
  let(:converter) { described_class.new(data, schema) }


  context "Initialization" do

    context "on success" do

      it "should set all parameters correctly" do
        converter.data.content.should == content
        # Sequel handles Time as DateTime
        converter.column_types.should == [:string, :integer, :float, :date, :datetime, :datetime, :boolean]
        converter.allow_null.should   == [true, true, true, true, true, true, true]
        converter.state.should        == :parsed
      end
    end

    context "on failure" do

      context "when state of Data object does not equal :parsed" do

        let(:data) { RStore::Data.new(path, content, :converted) }

        it "should raise an exception" do

          lambda { described_class.new(data, schema) }.should raise_exception(/not a valid state for class Converter/)
        end
      end

      context "when the data contains nil where nil is not allowed" do

        DB.alter_table :test do
          drop_column :boolean_col
          add_column  :boolean_col, :boolean, :default => false, :allow_null => false
        end

        new_schema = DB.schema(:test)

        it "should log the error" do

          converter = described_class.new(data, new_schema) 
          converter.allow_null.should == [true, true, true, true, true, true, false]
          converter.convert

          RStore::Logger.error_queue.should ==
            {"/home/sovonex/Desktop/my_file.csv"=>
             {:convert=>
              [{:error=>RStore::NullNotAllowedError, :message=>"NULL not allowed", :value=>nil, :row=>1, :col=>7}, 
               {:error=>RStore::NullNotAllowedError, :message=>"NULL not allowed", :value=>nil, :row=>7, :col=>7}]}}

          RStore::Logger.empty_error_queue
        end

        # Reverse changes
        DB.alter_table :test do
          drop_column :boolean_col
          add_column  :boolean_col, :boolean
        end


      end
    end
  end


  context "Validation" do

    context "on success" do


      context :convert do

        it "should convert all items into the correct type" do

          converter.convert.content.should == 
            [["string1", 1, 1.12, "2011-02-04", dt('01:30'), dt('01:30'), nil],
             ["string2", 2, 2.22, "2012-02-04", dt('02:30'), dt('14:30'), false],
             [nil, 3, 3.33, "2013-02-04", dt('03:30'), dt('03:30'), true],
             ["string4", 4, nil, nil, dt('04:30'), dt('16:30'), false],
             ["string5", 5, 5.55, "2015-02-04",dt('05:30'), dt('05:30') , true],
             ["string6", 6, 6.66, "2016-02-04", dt('06:30'), dt('18:30'), false],
             ["string7", 7, 7.77, nil, nil, nil, nil]]

          converter.state.should == :converted
          RStore::Logger.error_queue.should be_empty
        end
      end
    end

    context "on failure" do

      data_with_errors = 
        [["string1", "xxx", "1.12", "2011-2-4", "1:30", "1:30am", nil],     # '1'       -> 'xxx'
         ["string2", "2", "xxx", "2012/2/4", "2:30", "2:30pm", "false"],    # '2.2'     -> 'xxx'
         [nil, "3", "3.33", "xxx", "3:30", "3:30 a.m.", "True"],            # '20132/4' -> 'xxx'
         ["string4", "4", nil, nil, "xxx", "4:30 p.m.", "False"],           # '4:30'    -> 'xxx'
         ["string5", "5", "5.55", "2015-2-4", "5:30", "xxx", "1"],          # '5:30AM'  -> 'xxx'
         ["string6", "6", "6.66", "2016/2/4", "6:30", "6:30 P.M.", "xxx"],  # '0'       -> 'xxx'
         ["string7", "7", "7.77", nil, nil, nil, nil]]

      let(:data)      { RStore::Data.new(path, data_with_errors, :parsed) }
      let(:converter) { described_class.new(data, schema) }

      context :convert do

        it "should log the error, skip the rest of the current row and continue with the next row" do

        converter.convert.content.should == 
          [["string1", "xxx", "1.12", "2011-2-4", "1:30", "1:30am", nil],   
           ["string2", 2, "xxx", "2012/2/4", "2:30", "2:30pm", "false"], 
           [nil, 3, 3.33, "xxx", "3:30", "3:30 a.m.", "True"],        
           ["string4", 4, nil, nil, "xxx", "4:30 p.m.", "False"],      
           ["string5", 5, 5.55, "2015-02-04", dt('05:30'), "xxx", "1"],    
           ["string6", 6, 6.66, "2016-02-04", dt('06:30'),dt('18:30'), "xxx"],
           ["string7", 7, 7.77, nil, nil, nil, nil]]

        converter.state.should == :error

        log = RStore::Logger.error_queue[path][:convert]
        log.size.should  == 6
        log[0].should == {:error=>ArgumentError,
                          :message=>"invalid value for Integer(): \"xxx\"",
                          :value=>"xxx",
                          :row=>1,
                          :col=>2}
        end
      end
    end
  end
end
