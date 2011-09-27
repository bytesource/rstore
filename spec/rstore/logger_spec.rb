# encoding: utf-8

require 'spec_helper'

describe RStore::Logger do

  let(:logger) { described_class }

  begin
    raise Exception, "Something went wrong..."
  rescue Exception => e
    puts "ERROR:"
    puts $!
  end


  context "Adding error messages" do


    error_information1 = ['/home/sovonex/Desktop', :verify, ArgumentError, {value: 'hello', row: 2, col: 1}]

    it "#log: should edit and store error information correctly" do

      begin
        raise Exception, "Something went wrong"
      rescue Exception => error
        logger.log('/temp/', :verify, error, {value: 'hello', row: 2, col: 1})
        logger.log('/temp/temp', :verify, error, {value: 'hello', row: 2, col: 1})
        logger.log('/temp/', :verify, error, {row: 2})
        logger.log('/temp/', :write, error, {row: 2})
      end
      pp logger.error_queue.should == {"/temp/"=>
                                       {:verify=>
                                        [{:error=>Exception,
                                          :message=>"Something went wrong",
                                          :value=>"hello",
                                          :row=>2,
                                          :col=>1},
                                          {:error=>Exception, :message=>"Something went wrong", :row=>2}],
                                          :write=>[{:error=>Exception, :message=>"Something went wrong", :row=>2}]},
                                          "/temp/temp"=>
                                        {:verify=>
                                         [{:error=>Exception,
                                           :message=>"Something went wrong",
                                           :value=>"hello",
                                           :row=>2,
                                           :col=>1}]}}
    end
  end
end
