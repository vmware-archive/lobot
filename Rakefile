require 'rspec/core/rake_task'

file "chef/travis-cookbooks/README.md" do
  sh "git submodule init"
  sh "git submodule update"
end

RSpec::Core::RakeTask.new(:spec)

task :spec => ["chef/travis-cookbooks/README.md"]

task :default => :spec
