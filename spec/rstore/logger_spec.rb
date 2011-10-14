# encoding: utf-8

require 'spec_helper'

describe RStore::Logger do

  path    = '/home/sovonex/Desktop.csv'
  state   = :raw
  content = ''
  options = RStore::Configuration.default_options

  let(:data)   { RStore::Data.new(path, content, state, options) }  # has_headers => true
  let(:logger) { described_class.new(data) }


  context "Adding error messages" do

    error_information1 = [:convert, ArgumentError, {row: 2, col: 1}]
    error_information2 = [:convert, ArgumentError, {row: 2}]
    error_information3 = [:convert, ArgumentError]

    context :log do

      it "should raise an error and output a well formatted error message" do

        lambda do
          logger.log(*error_information1)
          logger.error
        end.should raise_exception(RStore::FileProcessingError, /row 4, col 2/)

        lambda do
          logger.log(*error_information2)
          logger.error
        end.should raise_exception(RStore::FileProcessingError, /row 4[^,]/)

        lambda do
          logger.log(*error_information3)
          logger.error
        end.should raise_exception(RStore::FileProcessingError, /ArgumentError\n=+/)

        # RStore::FileProcessingError:
        # An error occured while converting field values into their corresponding datatypes:
        # File         : /home/sovonex/Desktop.csv 
        # Type of error: Class 
        # Error message: ArgumentError
        # Location     : row 4, col 2
        # =============
        # Please fix the error and run again.
        # NOTE: No data has been inserted into the database yet.
        # =============


      end
    end
  end
end


