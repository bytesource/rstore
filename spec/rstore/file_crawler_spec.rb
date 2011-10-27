# encoding: utf-8

require 'spec_helper'

describe RStore::FileCrawler do

  # Directory struture:
  # test_dir/
  # -- csv.bad
  # -- empty.csv
  # -- dir_1/
  # -- -- dir_2/
  # -- -- -- test.csv

  options     = {col_sep: ";", quote_char: "'", recursive: true}
  test_dir    = '../test_dir'
  file_type   = :csv

  let(:crawler) { described_class.new(test_dir, file_type, options) }

  context "On Initialization" do

    it "should set all variables correctly" do
      config = RStore::Configuration.new(test_dir, options)

      crawler.path.should          == test_dir
      crawler.file_options.should  == config.file_options
      crawler.parse_options.should == config.parse_options
      crawler.file_type.should     == file_type
      crawler.data_hash.each do |path, data|
        data.class.should   == RStore::Data
        data.content.should == ''
        data.state.should   == :raw
        data.options.should == crawler.instance_variable_get(:@file_options_hash)[path]
      end

    end
  end

  describe :file_queue do


    describe "given a path to a directory" do
      # If given a directory, all files not ending on 'file_type' are silently skipped without raising an exception.

      context "on success" do

        context "with default options for 'recursive'" do

          let(:crawler) { described_class.new(test_dir, file_type) }

          # @return: [Hash<filename => {:file_options => Hash, :parse_options => Hash}>]
          it "should return a hash for all files of the current directory" do

            data = crawler.data_hash["#{File.expand_path('../test_dir/empty.csv')}"]

            data.path.should == "#{File.expand_path('../test_dir/empty.csv')}"
            data.options.should == {:file_options=>{:recursive=>false, :has_headers=>true, :selector => ""}, 
                                    :parse_options=>{row_sep: :auto, col_sep: ",", quote_char: '"', field_size_limit: nil, skip_blanks: false}}
          end
        end

        context "with 'recursive' set to 'true'" do

          let(:crawler) { described_class.new(test_dir, file_type, options) }

          it "should return a hash for all files of the current directory and subdirectories" do

          data1 = crawler.data_hash["#{File.expand_path('../test_dir/empty.csv')}"]
          data2 = crawler.data_hash["#{File.expand_path('../test_dir/dir_1/dir_2/test.csv')}"]

          data1.path.should == "#{File.expand_path('../test_dir/empty.csv')}"
          data2.path.should == "#{File.expand_path('../test_dir/dir_1/dir_2/test.csv')}"

          data1.options.should == 
            {:file_options=>{:recursive=>true, :has_headers=>true, :selector => ""}, 
             :parse_options=>{row_sep: :auto, col_sep: ";", quote_char: "'", field_size_limit: nil, skip_blanks: false}}

          data2.options.should == 
            {:file_options=>{:recursive=>true, :has_headers=>true, :selector => ""}, 
             :parse_options=>{row_sep: :auto, col_sep: ";", quote_char: "'", field_size_limit: nil, skip_blanks: false}}

          end
        end
      end

      context "on failure" do

        context "when directory does not exist" do

          wrong_dir_path = 'xxx'

          let(:crawler) { described_class }

          it "should throw an exception" do

            lambda do
              crawler.new(wrong_dir_path, file_type, options)
            end.should raise_exception(ArgumentError,"'#{wrong_dir_path}' is not a valid path")

          end
        end
      end
    end

    describe "given a path to a file" do

      context "on success" do

        file = '../test_dir/empty.csv'
        let(:crawler) { described_class.new(file, file_type, options) }

        # @return: [Hash<filename => {:file_options => Hash, :parse_options => Hash}>]
        it "should return a hash for the file" do

          data = crawler.data_hash["#{File.expand_path("/home/sovonex/Desktop/temp/rstore/spec/test_dir/empty.csv" )}"]

          data.path.should == "#{File.expand_path("/home/sovonex/Desktop/temp/rstore/spec/test_dir/empty.csv" )}"
          data.options.should == 
            {:file_options=>{:recursive=>true, :has_headers=>true, :selector => ""}, 
             :parse_options=>{row_sep: :auto, col_sep: ";", quote_char: "'", field_size_limit: nil, skip_blanks: false}}

        end
      end

      context "on failure" do

        context "when file does not exist" do

          wrong_file_path = 'xxx.csv'

          let(:crawler) { described_class }

          it "should throw an exception" do

            lambda do
              crawler.new(wrong_file_path, file_type, options)
            end.should raise_exception(ArgumentError,"'#{wrong_file_path}' is not a valid path")

          end
        end

        context "when file type is not csv" do

        wrong_file_type = '../test_dir/csv.bad' # file exists, but has the wrong file type

          let(:crawler) { described_class.new(wrong_file_type, file_type) }

          it "should throw an exception" do

            lambda do
              crawler.add
            end.should raise_exception(ArgumentError)
          end
        end
      end
    end

    describe "given a URL" do

      context "on success" do

        url1 = 'http://github.com/circle/fastercsv/blob/master/test/test_data.csv'
        url2 = 'www.sovonex.com/drill-collars.php' # does require a file in an URL to be of a specific file type.
        urls = [url1, url2]
        let(:crawler) { described_class }

        # @return: [Hash<filename => {:file_options => Hash, :parse_options => Hash}>]
        it "should return a hash for the url" do

          c1 = crawler.new(url1, file_type, options)
          c2 = crawler.new(url2, file_type, options)

          data1 = c1.data_hash["#{urls[0].gsub(/http/,'https')}"]
          data2 = c2.data_hash["http://#{urls[1]}"]

          data1.path.should == "#{urls[0].gsub(/http/,'https')}"
          data2.path.should == "http://#{urls[1]}"

          data1.options.should == {:file_options=>{:recursive=>true, :has_headers=>true, :selector => ""}, 
             :parse_options=>{row_sep: :auto, col_sep: ";", quote_char: "'", field_size_limit: nil, skip_blanks: false}}

          data2.options.should == {:file_options=>{:recursive=>true, :has_headers=>true, :selector => ""}, 
             :parse_options=>{row_sep: :auto, col_sep: ";", quote_char: "'", field_size_limit: nil, skip_blanks: false}}

        end
      end

      context "on failure" do

        context "when the url has the wrong format" do

          wrong_format = 'http:/www.sovonex.com/test.csv' # one slash missing

          let(:crawler) { described_class } 

          it "should throw an exception" do

            lambda do
              crawler.new(wrong_format, file_type) 
            end.should raise_exception(ArgumentError,"'#{wrong_format}' is not a valid path")

          end
        end

        context "when the remote file does not exist" do

          does_not_exist = 'http://www.sovonex.com/does-not_exist.csv'

          let(:crawler) { described_class.new(does_not_exist, file_type) }

          it "should throw an exception" do

            lambda do
              crawler.add
            end.should raise_exception(ArgumentError,/Could not connect to #{does_not_exist}/)
          end
        end
      end
    end
  end
end
