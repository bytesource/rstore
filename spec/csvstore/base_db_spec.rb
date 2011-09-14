# encoding: utf-8

require 'spec_helper'
require 'data/db_classes' # BaseDB subclasses

describe CSVStore::BaseDB do
  let(:base) {described_class}

  context "When loading BaseDB subclasses" do

    it "#db_classes: should contain all subclasses in a hash" do
      base.db_classes.should == {:plastronics => PlastronicsDB, :my => MyDB}
    end

    it "#db_classes: should also add an ad-hoc subclass to the hash" do

      class TestDB < CSVStore::BaseDB
      end

      base.db_classes.should == {:plastronics => PlastronicsDB, :my => MyDB, :test => TestDB}
    end
  end

  context "When inspecting a subclass of BaseDB" do
    let(:subclass) {described_class.db_classes[:plastronics]}

    it "Subclass#connection_info: should return a hash with the connection info" do

      subclass.connection_info == {:database => 'mysql', :password => 'xxx'}
    end
  end
end
