require File.expand_path("lib/rstore/version")

Gem::Specification.new do |s|
  s.name        = "rstore"
  s.version     = RStore::VERSION
  s.authors     = ["Stefan Rohlfing"]
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.description = <<-DESCRIPTION
  RStore makes batch processing of csv files a breeze.
  Automatically fetches data files, directories, URLs
  :: Customizable using additional options
  :: Validation of field values
  :: Descriptive error messages
  :: Safe and transparent data storage using database transactions
  DESCRIPTION
  s.summary               = 'RStore - A library for easy batch storage of csv data into a database'
  s.email                 = 'stefan.rohlfing@gmail.com'
  s.homepage              = 'http://github.com/bytesource/rstore'
  s.has_rdoc              = 'yard'
  s.required_ruby_version = '>= 1.9.1'
  s.rubyforge_project     = 'rstore'

  s.add_dependency 'open-uri'
  s.add_dependency 'nokogiri'
  s.add_dependency 'bigdecimal'
  s.add_dependency 'sequel'
  s.add_dependency 'csv'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'mysql'
  s.add_development_dependency 'sqlite3'

  s.files = Dir["{lib}/**/*.rb", "*.md", 'Rakefile', 'LICENSE']
end
