require 'rspec/core/rake_task'
require 'cucumber/rake/task'
require 'bundler'
Bundler::GemHelper.install_tasks

task :default => [:spec, :features]

desc "Run all specs in spec directory (excluding plugin specs)"
RSpec::Core::RakeTask.new(:spec)

desc "Run all features in the features directory"
Cucumber::Rake::Task.new(:features) do |t|
end
