# encoding: utf-8

require 'spec_helper'

describe CSVStore::FileCrawler do
  
  options     = {col_sep: ";", quote_char: "'", recursive: true}
  test_dir   = '../test_dir/dir_1/dir_2'

  # pp File.directory?(test_dir)
  # pp File.directory?(File.expand_path(test_dir))

  let(:crawler) { described_class.new(test_dir, options) }

  context "On Initialization" do

    it "should set all variables correctly" do
      config = CSVStore::Configuration.new(test_dir, options)

      crawler.path.should == test_dir
      crawler.file_options.should  == config.file_options
      crawler.parse_options.should == config.parse_options
    end
  end

  describe :file_queue do

    context "with default options for 'recursive'" do

      let(:crawler) { described_class.new(test_dir, options)}

      it "should add return a hash with of the kind 'individual_filename => options'" do

        crawler.add
        CSVStore::FileCrawler.file_queue.should == {'empty.csv' => {:file_options=>{:recursive=>true, :has_headers=>true}, 
                                                                    :parse_options=>{:col_sep=>";", :quote_char=>"'"}}}
      end
    end
  end
end
