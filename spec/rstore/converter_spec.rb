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
  db = Sequel.sqlite

  unless db.table_exists?(:test)
    db.create_table :test do
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
  schema  = db.schema(:test)
  path    = '/home/sovonex/Desktop/my_file.csv'
  options = RStore::Configuration.default_options

  let(:data)      { RStore::Data.new(path, content, :parsed, options) }
  let(:converter) { described_class.new(data, db, :test) }


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

        let(:data) { RStore::Data.new(path, content, :converted, options) }

        it "should raise an exception" do

          lambda { described_class.new(data, db, :test) }.should raise_exception(/not a valid state for class Converter/)
        end
      end

      context "when the data contains nil where nil is not allowed" do
        new_schema = db.schema(:test)

        it "should raise an exception and output a detailed error message" do

          db.alter_table :test do
            drop_column :boolean_col
            add_column  :boolean_col, :boolean, :default => false, :allow_null => false
          end


          converter = described_class.new(data, db, :test)
          converter.allow_null.should == [true, true, true, true, true, true, false]
          lambda do
            converter.convert
          end.should raise_exception(RStore::FileProcessingError)


          # Reverse changes
          db.alter_table :test do
            drop_column :boolean_col
            add_column  :boolean_col, :boolean
          end
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

      let(:data)      { RStore::Data.new(path, data_with_errors,:parsed, options) }
      let(:converter) { described_class.new(data, db, :test) }

      context :convert do

        context "non-valid Integer value" do

          error_content = content.dup
          error_content[0] = data_with_errors[0]

          let(:data)      { RStore::Data.new(path, error_content,:parsed, options) }
          let(:converter) { described_class.new(data, db, :test) }

          it "should raise an error" do

            lambda do
              converter.convert
            end.should raise_exception(RStore::FileProcessingError, /row 2, col 2/)
          end
        end


        context "non-valid Float value" do

          error_content = content.dup
          error_content[1] = data_with_errors[1]

          let(:data)      { RStore::Data.new(path, error_content,:parsed, options) }
          let(:converter) { described_class.new(data, db, :test) }

          it "should raise an error" do

            lambda do
              converter.convert
            end.should raise_exception(RStore::FileProcessingError, /row 3, col 3/)
          end
        end


        context "non-valid Date value" do

          error_content = content.dup
          error_content[2] = data_with_errors[2]

          let(:data)      { RStore::Data.new(path, error_content,:parsed, options) }
          let(:converter) { described_class.new(data, db, :test) }

          it "should raise an error" do

            lambda do
              converter.convert
            end.should raise_exception(RStore::FileProcessingError, /row 4, col 4/)
          end
        end


        context "non-valid DateTime value" do

          error_content = content.dup
          error_content[3] = data_with_errors[3]

          let(:data)      { RStore::Data.new(path, error_content,:parsed, options) }
          let(:converter) { described_class.new(data, db, :test) }

          it "should raise an error" do

            lambda do
              converter.convert
            end.should raise_exception(RStore::FileProcessingError, /row 5, col 5/)
          end
        end


        context "non-valid Time value" do

          error_content = content.dup
          error_content[4] = data_with_errors[4]

          let(:data)      { RStore::Data.new(path, error_content,:parsed, options) }
          let(:converter) { described_class.new(data, db, :test) }

          it "should raise an error" do

            lambda do
              converter.convert
            end.should raise_exception(RStore::FileProcessingError, /row 6, col 6/)
          end
        end


        context "non-valid Boolean value" do

          error_content = content.dup
          error_content[5] = data_with_errors[5]

          let(:data)      { RStore::Data.new(path, error_content,:parsed, options) }
          let(:converter) { described_class.new(data, db, :test) }

          it "should raise an error" do

            lambda do
              converter.convert
            end.should raise_exception(RStore::FileProcessingError, /row 7, col 7/)
          end
        end
      end
    end
  end
end

