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

  s.files         = "lib/lobot.rb"
  s.executables   = "lobot"
  s.require_paths = ["lib"]

  s.add_dependency "ciborg", "~> 3.0"

  s.post_install_message = <<-MESSAGE
!    The 'lobot' gem has been deprecated and has been replaced by 'ciborg'.
!    See: https://rubygems.org/gems/ciborg
!    And: https://github.com/pivotal/ciborg
  MESSAGE
end
