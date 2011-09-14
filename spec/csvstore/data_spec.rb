# encoding: utf-8

require 'spec_helper'
require 'csv'

describe CSVStore::Data do

  # Preparing data for content:
  csv = <<-CSV.gsub(/^ +/, "")
  "col1","col2","col3","生日","col5","col6"
  1,2,3,4.433,5,-6.43
  ""test"",test2,,,,
  CSV

  content = CSV.parse(csv)
  path    = '/home/sovonex/temp/fantastic.csv'

  let(:data) { described_class.new(path, content) }

  context "When initializing CSVStore::Data" do

    it "should set all instance variables correctly" do

      data.path.should == '/home/sovonex/temp/fantastic.csv'
      data.has_error?.should == false
      data.type.should == :csv
      data.content.should == [["col1", "col2", "col3", "生日", "col5", "col6"], 
                              ["1", "2", "3", "4.433", "5", "-6.43"], 
                              ["\"test\"", "test2", nil, nil, nil, nil]]
    end

    it "#has_error? should return the respective value given at initialization, 
    'false' by default and if no boolean value was passed" do
      data.has_error?.should == false

      with_error = CSVStore::Data.new(path, content, :has_error => true)
      with_error.has_error?.should == true

      lambda do
        CSVStore::Data.new(path, content, :has_error =>  'xxx')
      end.should raise_error
    end
  end
end
