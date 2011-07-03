# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "lobot/version"

Gem::Specification.new do |s|
  s.name        = "lobot"
  s.version     = Lobot::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Matthew Kocher & Lee Edwards"]
  s.email       = ["pair@pivotallabs.com"]
  s.homepage    = ""
  s.summary     = %q{Lobot provides generators of chef recipes to set up CI easily.}
  s.description = %q{Description coming soon}

  s.rubyforge_project = "lobot"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency('fog', '0.9.0')
  s.add_dependency('capistrano')
  s.add_dependency('capistrano-ext')
  s.add_dependency('rvm')
  s.add_dependency('nokogiri', '>=1.4.4')
end
