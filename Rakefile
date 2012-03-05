# require 'spec/rake/spectask' # depreciated
require 'rspec/core/rake_task'
# require 'rake/gempackagetask' # depreciated
require 'rubygems/package_task'
require 'rdoc/task'

# Build gem: rake gem
# Push gem:  rake push

task :default => [ :spec, :gem ]

RSpec::Core::RakeTask.new do

  message = <<-MESSAGE

  ====================================
  | NOTE:
  | Make sure to provide the correct connection info for database 'PlastronicsDB'
  | in file 'csv_spec.rb' (line 12).
  ====================================

  MESSAGE

  puts message

  :spec
end

gem_spec = eval(File.read('rstore.gemspec'))

Gem::PackageTask.new( gem_spec ) do |t|
  t.need_zip = true
end

#RDoc::Task.new do |rdoc|
#
#end

task :push => :gem do |t|
  sh "gem push -v pkg/#{gem_spec.name}-#{gem_spec.version}.gem"
end
