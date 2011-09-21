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

  # pp File.directory?(test_dir)
  # pp File.directory?(File.expand_path(test_dir))

  let(:crawler) { described_class.new(test_dir, file_type, options) }

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

      context "with default options for 'recursive'" do

        let(:crawler) { described_class.new(test_dir, file_type) }

        # @return: [Hash<filename => {:file_options => Hash, :parse_options => Hash}>]
        it "should return a hash for all files of the current directory" do

          crawler.add
          CSVStore::FileCrawler.file_queue.should == {"#{File.expand_path('empty.csv')}" => 
                                                      {:file_options=>{:recursive=>false, :has_headers=>true}, 
                                                       :parse_options=>{}}}
        end
      end

      context "with 'recursive' set to 'true'" do

        let(:crawler) { described_class.new(test_dir, file_type, options) }

        # @return: [Hash<filename => {:file_options => Hash, :parse_options => Hash}>]
        it "should return a hash for all files of the current directory and subdirectories" do

          CSVStore::FileCrawler.file_queue = Hash.new {|h,k| h[k] = Hash.new {|h,k| h[k] = nil}} 
          crawler.add
          CSVStore::FileCrawler.file_queue.should == {"#{File.expand_path('empty.csv')}" => 
                                                      {:file_options=>{:recursive=>true, :has_headers=>true}, 
                                                       :parse_options=>{:col_sep => ";", :quote_char => "'"}},
                                                       "#{File.expand_path('dir_1/dir_2/test.csv')}"  => 
                                                      {:file_options=>{:recursive=>true, :has_headers=>true}, 
                                                       :parse_options=>{:col_sep => ";", :quote_char => "'"}}}
        end
      end
    end

    describe "given a path to a file" do

      file = '../empty.csv'

      let(:crawler) { describes_class.new(file, file_type, options) }

        # @return: [Hash<filename => {:file_options => Hash, :parse_options => Hash}>]
        it "should return a hash for the file" do
        end
    end
  end
end
