# encoding: utf-8

require 'spec_helper'

describe RStore::CSV do

  # csv_data at path '../test_dir/dir_1/dir_2/test.csv':
  # "strings","integers","floats"
  # "string1","1","1.12"
  # "string2","2","2.22"

  class TestDB < RStore::BaseDB
    connect 'sqlite:/'
  end

  class DataTable < RStore::BaseTable
    create do
      primary_key :id, :allow_null => false
      String      :col1
      Integer     :col2
      Float       :col3
    end
  end

  

  context "On initialization" do

    context "should set all variables correctly" do

      store = RStore::CSV.new do
        from '../test_dir/dir_1/dir_2/test.csv'
        to   'test.data'
        run
      end

      pp store.database.name







    end
  end
end
