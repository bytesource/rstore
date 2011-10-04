# encoding: utf-8
$:.unshift File.expand_path('..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

require 'rspec'
require 'pp'
require 'rstore/exceptions'
require 'rstore/base_db'
require 'rstore/base_table'
require 'rstore/data'
require 'rstore/validator'
require 'rstore/logger'
require 'rstore/configuration'
require 'rstore/file_crawler'
# require 'rstore/csv'
require 'rstore/storage'


module HelperMethods
  def dt time
    date_now = Time.now.to_s.match(/(?<date>.*?)\s/)[:date]
    "#{date_now}T#{time}:00+00:00"
  end
end


