#!/usr/bin/env rake
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

file "chef/travis-cookbooks/README.md" do
  sh "git submodule init"
  sh "git submodule update"
end

RSpec::Core::RakeTask.new(:spec)

desc ""
task :spec => ["chef/travis-cookbooks/README.md"]

desc "Run specs"
task :default => :spec
