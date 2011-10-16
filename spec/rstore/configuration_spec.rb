# encoding: utf-8

require 'spec_helper'

describe RStore::Configuration do

  file_options  = {has_headers: true, selector: 'pre div.line'}  # :recursive not included
  parse_options = {row_sep: '\n', col_sep: ';', quote_char: "'", field_size_limit: nil} # :skip_blanks not inlcuded

  all_options   = file_options.merge(parse_options)

  path = '/home/sovonex/Desktop/temp/test.csv'

  let(:config) { described_class.new(path, all_options) }


  describe "On initialization" do

    context "when successfull" do

      # Always returns all options available, e.g. #file_options returns all file options, not just the ones passes on initialization.

      specify { config.options.should        == file_options.merge(:recursive => false).merge(parse_options).merge(:skip_blanks => false) }
      specify { config.file_options.should   == RStore::Configuration.default_file_options.merge(file_options) }
      specify { config.parse_options.should  == RStore::Configuration.default_parse_options.merge(parse_options) }
      specify { config.path.should           == path }

      specify { config[:options].should       == file_options.merge(:recursive => false).merge(parse_options).merge(:skip_blanks => false) }
      specify { config[:file_options].should  == RStore::Configuration.default_file_options.merge(file_options) }
      specify { config[:parse_options].should == RStore::Configuration.default_parse_options.merge(parse_options) }
      specify { config[:path].should          == path }
      
      specify { lambda { config[:does_not_exist] }.should  raise_exception }

    end

    
    context "on failure" do

      context "when option hash contains unknown option keys" do
        with_unknown_option = all_options.merge(:unknown => 'some value', :also_unknown => 'some other value')

        it "should throw an exception" do

          lambda do
            described_class.new(path, with_unknown_option)
          end.should raise_exception(ArgumentError, /unknown, also_unknown/)
        end
      end

      context "when a file option has the wrong value" do

        wrong_selector = all_options.merge(:selector => [])            # valid: String
        wrong_recursive = all_options.merge(:recursive => 'true')      # valid: true, false, nil
        wrong_has_headers = all_options.merge(:has_headers => 'false') # valid: true, false, nil
        wrong_values = [wrong_selector, wrong_recursive, wrong_has_headers]

      

        it "should throw an exception" do

          wrong_values.each do |option|
            lambda do
              described_class.new(path, option)
            end.should raise_exception(ArgumentError)
          end
        end
      end
    end

    context "self.update_default_options" do

      let(:config) { described_class }

      context "on success" do

        it "should set the new value" do

          options = {:selector => 'body', :col_sep => ';'}

          defaults = config.default_options

          config.update_default_options(options)
          config.default_file_options.should == defaults.merge(options)
        end
      end

      context "on failure" do

        it "should raise an exception if the parameter is not an instance of Hash" do
          lambda do
            config.update_default_options([1,2,3])
          end.should raise_exception(ArgumentError, /must be an instance of Hash/) 
        end

        it "should raise an exception if the parameter contains an unknown option key" do
          lambda do
            config.update_default_options({selector: 'body', unknown: 'body'})
          end.should raise_exception(ArgumentError, /contains unknown option key/)
        end

        it "should raise an exception if a key does not contain the correct value" do 
          lambda do 
            config.update_default_options({selector: true})
          end.should raise_exception(ArgumentError, /is not a valid value for option/) 
        end
      end
    end
  end
end
