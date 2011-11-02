# encoding: utf-8

require 'spec_helper'
require 'data/db_classes' # BaseDB subclasses

describe RStore::BaseDB do
  let(:base) {described_class}

  context "When loading BaseDB subclasses" do

    it "#db_classes: should contain all subclasses in a hash" do

      expected = {:company => CompanyDB, :my => MyDB}


      base.db_classes.include_pairs?(expected).should be_true 
    end

    it "#db_classes: should also add an ad-hoc subclass to the hash" do

      class TestDB < RStore::BaseDB
      end

      expected = {:company => CompanyDB, :my => MyDB, :test => TestDB}

      base.db_classes.include_pairs?(expected).should be_true 
    end
  end

  context "When inspecting a subclass of BaseDB" do
    let(:subclass) {described_class.db_classes[:company]}

    it "Subclass#connection_info: should return a hash with the connection info" do

      subclass.connection_info.should == 
        {:adapter => 'mysql', :user => 'root', :password => 'xxx', :host => 'localhost', :database => 'company'}

    end
  end
end
