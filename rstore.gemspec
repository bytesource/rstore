require File.expand_path("lib/rstore/version")

Gem::Specification.new do |s|
  s.name = "rstore"
  s.version = RStore::VERSION
  s.authors = ["Stefan Rohlfing"]
  s.date = %q(2011-10-27)
  s.description = 'RStore - Convenient batch storage of csv data into a database'
  s.summary = s.description
  s.email = 'stefan.rohlfing@gmail.com'
  s.homepage = 'http://github.com/bytesource/rstore'
  s.has_rdoc = false
  s.required_ruby_version = '>= 1.9.1'
  s.rubyforge_project = 'rstore'
  s.add_dependency 'nokogiri'
  s.add_development_dependency 'rspec'
  s.files = Dir["{lib}/**/*.rb", "*.md"]
end
