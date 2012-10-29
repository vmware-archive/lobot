require 'ci/reporter/rake/rspec'
require 'rspec/core/rake_task'
require 'bundler'

Bundler::GemHelper.install_tasks

task :default => ['ci:setup:rspec', :spec]

desc "Run all specs in spec directory (excluding plugin specs)"
RSpec::Core::RakeTask.new(:spec)

