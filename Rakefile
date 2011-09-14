# require 'spec/rake/spectask' # depreciated
require 'rspec/core/rake_task'
require 'rake/gempackagetask'

# Build gem: rake gem
# Push gem:  rake push

task :default => [ :spec, :gem ]

RSpec::Core::RakeTask.new :spec
# Spec::Rake::SpecTask.new do |t|
#   t.spec_files = FileList['spec/**/*_spec.rb']
# end

gem_spec = eval(File.read('csvtable.gemspec'))

Rake::GemPackageTask.new( gem_spec ) do |t|
  t.need_zip = true
end

task :push => :gem do |t|
  sh "gem push pkg/#{gem_spec.name}-#{gem_spec.version}.gem"
end
