require File.expand_path("lib/rstore/version")

Gem::Specification.new do |s|
  s.name = "rstore"
  s.version = RStore::VERSION
  s.authors = ["Stefan Rohlfing"]
  s.date = %q(2011-08-29)
  s.description = 'RStore - Ruby class for entering data from a CSV file into a database'
  s.summary = s.description
  s.email = 'stefan.rohlfing@gmail.com'
  s.homepage = 'http://github.com/bytesource/rstore'
  s.has_rdoc = false
  s.rubyforge_project = 'rstore'
  # s.add_dependency = 'digest'
  # s.add_development_dependency = 'rspec'
  s.files = Dir["{lib}/**/*.rb", "*.markdown", "*.md"]
end
