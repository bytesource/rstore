# encoding: utf-8

require 'spec_helper'
require 'csv'

describe RStore::Data do

  # Preparing data for content:
  csv = <<-CSV.gsub(/^ +/, "")
  "col1","col2","col3","生日","col5","col6"
  1,2,3,4.433,5,-6.43
  ""test"",test2,,,,
  CSV

  content = CSV.parse(csv)
  path    = '/home/sovonex/temp/fantastic.csv'
  options = RStore::Configuration.default_options

  let(:data) { described_class.new(path, content, :parsed, options) }

  context "On initialization" do

    it "should set all instance variables correctly" do

      data.path.should       == '/home/sovonex/temp/fantastic.csv'
      data.state.should      == :parsed
      data.type.should       == :csv
      data.content.should    == [["col1", "col2", "col3", "生日", "col5", "col6"], 
                                 ["1", "2", "3", "4.433", "5", "-6.43"], 
                                 ["\"test\"", "test2", nil, nil, nil, nil]]
    end
  end


  context :state do

    context "on failure" do

      it "should raise an error" do

        state = :wrong_state

        lambda do
          data.state = state
        end.should raise_exception(ArgumentError, /#{state.inspect} is not a valid state/ )
      end
    end
  end
end
