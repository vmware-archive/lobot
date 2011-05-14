require "rubygems"

require 'rails/all'
require 'rails/generators'

require File.expand_path('../lib/lobot', File.dirname(__FILE__))

require 'generator_spec/test_case'

require 'generator_spec'
require File.expand_path('../../lib/generators/lobot/install_generator.rb', __FILE__)