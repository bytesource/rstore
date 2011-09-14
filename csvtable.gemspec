require File.expand_path("lib/csvtable/version")

Gem::Specification.new do |s|
  s.name = "csvtable"
  s.version = CSVTable::VERSION
  s.authors = ["Stefan Rohlfing"]
  s.date = %q(2011-08-29)
  s.description = 'CSVTable - Ruby class for entering data from a CSV file into a database'
  s.summary = s.description
  s.email = 'stefan.rohlfing@gmail.com'
  s.homepage = 'http://github.com/bytesource/csvtable'
  s.has_rdoc = false
  s.rubyforge_project = 'csvtable'
  # s.add_dependency = 'digest'
  # s.add_development_dependency = 'rspec'
  s.files = Dir["{lib}/**/*.rb", "*.markdown", "*.md"]
end
