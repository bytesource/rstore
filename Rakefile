# require 'spec/rake/spectask' # depreciated
require 'rspec/core/rake_task'
require 'rake/gempackagetask'
require 'rdoc/task'

# Build gem: rake gem
# Push gem:  rake push

task :default => [ :spec, :gem ]

# RSpec::Core::RakeTask.new :spec

gem_spec = eval(File.read('rstore.gemspec'))

Rake::GemPackageTask.new( gem_spec ) do |t|
  t.need_zip = true
end

#RDoc::Task.new do |rdoc|
#
#end

task :push => :gem do |t|
  sh "gem push pkg/#{gem_spec.name}-#{gem_spec.version}.gem"
end
