# encoding: utf-8

require 'spec_helper'
require 'data/table_classes' # BaseTable subclasses

describe CSVStore::BaseTable do
  let(:base) {described_class}

  context "When loading BaseTable subclasses" do

    it "#table_classes: should contain all subclasses in a hash" do
     base.table_classes.should == {:project => ProjectTable, :dna => DNATable} 
    end

    it "#table_classes: should also add an ad-hoc subclass to the hash" do

      class TestTable < CSVStore::BaseTable
      end

      base.table_classes.should == {:project => ProjectTable, :dna => DNATable, :test => TestTable} 
    end
  end

  context "When inspecting a subclass of BaseTable" do
    let(:subclass) {described_class.table_classes[:project]}

    it "Subclass#table_info: should return a proc with the table info" do

      subclass.table_info.class == Proc
    end
  end
end
