require File.expand_path("lib/rstore/version")

Gem::Specification.new do |s|
  s.name = "rstore"
  s.version = RStore::VERSION
  s.authors = ["Stefan Rohlfing"]
  s.date = %q(2011-10-27)
  s.description = <<-DESCRIPTION.gsub(/^\s+/,'')
+ Batch processing of csv files
+ Fetches data from different sources: files, directories, URLs
+ Customizable using additional options 
+ Validation of field values. At the moment validation of the following types is supported
+ Descriptive error messages pointing helping you to find any invalid data quickly
+ Safe and transparent data storage:
+ -- Using database transactions: Either the data from all files is stored or none
+ -- The data storage method can only be executed once for every instance of RStore::CSV
  DESCRIPTION
  s.summary = 'RStore - A library for easy batch storage of csv data into a database'
  s.email = 'stefan.rohlfing@gmail.com'
  s.homepage = 'http://github.com/bytesource/rstore'
  s.has_rdoc = 'yard'
  s.required_ruby_version = '>= 1.9.1'
  s.rubyforge_project = 'rstore'
  s.add_dependency 'nokogiri'
  s.add_development_dependency 'rspec'
  s.files = Dir["{lib}/**/*.rb", "*.md"]
end
