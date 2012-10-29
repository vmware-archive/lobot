# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "lobot/version"

Gem::Specification.new do |s|
  s.name        = "lobot"
  s.version     = Lobot::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Matthew Kocher", "Lee Edwards", "Brian Cunnie", "Doc Ritezel"]
  s.email       = ["lobot@pivotallabs.com"]
  s.homepage    = "https://github.com/pivotal/lobot"
  s.summary     = %q{CI in the Cloud: Jenkins + EC2 = Lobot}
  s.description = %q{Rails generators that make it easy to spin up a CI instance in the cloud.}

  s.rubyforge_project = "lobot"

  s.files         = `git ls-files`.split("\n") + `cd chef/travis-cookbooks && git ls-files`.split("\n").map { |f| "chef/travis-cookbooks/#{f}" }
  s.test_files    = `git ls-files -- {test,spec,features}`.split("\n")
  s.executables   = `git ls-files -- bin`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "fog", "~> 1.6"
  s.add_dependency "ci_reporter", "~> 1.7"
  s.add_dependency "thor"
  s.add_dependency "hashie"
  s.add_dependency "net-ssh"

  s.add_development_dependency "godot"
  s.add_development_dependency "rspec"
  s.add_development_dependency "jasmine"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "guard-bundler"
  s.add_development_dependency "test-kitchen"
  s.add_development_dependency "pry"

  s.add_development_dependency "terminal-notifier-guard"
  s.add_development_dependency "rb-fsevent"
  s.add_development_dependency "vagrant", "~> 1.0"
end
