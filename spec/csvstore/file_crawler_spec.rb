# encoding: utf-8

require 'spec_helper'

describe CSVStore::FileCrawler do

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
  let(:empty_hash) { Hash.new {|h,k| h[k] = Hash.new{|h,k| h[k] = []}} }

  context "On Initialization" do

    it "should set all variables correctly" do
      config = CSVStore::Configuration.new(test_dir, options)

      crawler.path.should == test_dir
      crawler.file_options.should  == config.file_options
      crawler.parse_options.should == config.parse_options
      crawler.file_type.should == file_type

    end
  end

  describe :file_queue do


    describe "given a path to a directory" do
      # If given a directory, all files not ending on 'file_type' are silently skipped without raising an exception.

      context "On success" do

        context "with default options for 'recursive'" do

          let(:crawler) { described_class.new(test_dir, file_type) }

          # @return: [Hash<filename => {:file_options => Hash, :parse_options => Hash}>]
          it "should return a hash for all files of the current directory" do

            crawler.add
            CSVStore::FileCrawler.file_queue.should == {"#{File.expand_path('../test_dir/empty.csv')}" => 
                                                        {:file_options=>{:recursive=>false, :has_headers=>true}, 
                                                         :parse_options=>{}}}
          end
        end

        context "with 'recursive' set to 'true'" do

          let(:crawler) { described_class.new(test_dir, file_type, options) }

          # @return: [Hash<filename => {:file_options => Hash, :parse_options => Hash}>]
          it "should return a hash for all files of the current directory and subdirectories" do

            CSVStore::FileCrawler.file_queue = empty_hash
            crawler.add
            CSVStore::FileCrawler.file_queue.should == {"#{File.expand_path('../test_dir/empty.csv')}"  => 
                                                        {:file_options=>{:recursive=>true, :has_headers=>true}, 
                                                         :parse_options=>{:col_sep => ";", :quote_char => "'"}},
                                                         "#{File.expand_path('../test_dir/dir_1/dir_2/test.csv')}"  => 
                                                        {:file_options=>{:recursive=>true, :has_headers=>true}, 
                                                         :parse_options=>{:col_sep => ";", :quote_char => "'"}}}
          end
        end
      end

      context "On failure" do

        context "when directory does not exist" do

          wrong_dir_path = 'xxx'

          let(:crawler) { described_class.new(wrong_dir_path, file_type) }

          it "should throw an exception" do

            lambda do
              crawler.add
            end.should raise_exception(ArgumentError,"'#{wrong_dir_path}' is not a valid path")

          end
        end
      end
    end

    describe "given a path to a file" do

      context "On success" do

        file = '../test_dir/empty.csv'
        let(:crawler) { described_class.new(file, file_type, options) }

        # @return: [Hash<filename => {:file_options => Hash, :parse_options => Hash}>]
        it "should return a hash for the file" do

          CSVStore::FileCrawler.file_queue = empty_hash
          crawler.add
          CSVStore::FileCrawler.file_queue.should == {"/home/sovonex/Desktop/temp/csvstore/spec/test_dir/empty.csv" => 
                                                      {:file_options=>{:recursive=>true, :has_headers=>true}, 
                                                       :parse_options=>{:col_sep => ";", :quote_char => "'"}}}
        end
      end

      context "On failure" do

        context "when file does not exist" do

          wrong_file_path = 'xxx.csv'

          let(:crawler) { described_class.new(wrong_file_path, file_type) }

          it "should throw an exception" do

            lambda do
              crawler.add
            end.should raise_exception(ArgumentError,"'#{wrong_file_path}' is not a valid path")

          end
        end

        context "when file type is not csv" do

        wrong_file_type = '../test_dir/csv.bad' # file exists, but has the wrong file type

          let(:crawler) { described_class.new(wrong_file_type, file_type) }

          it "should throw an exception" do

            crawler.add
            lambda do
              crawler.add
            end.should raise_exception(ArgumentError)
          end
        end
      end
    end
  end
end
