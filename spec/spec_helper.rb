$: << File.expand_path("../../lib", __FILE__)
require "rubygems"

require 'rails/all'
require 'rails/generators'

require "lobot"
require "lobot/cli"

require 'generator_spec/test_case'
require 'generator_spec'
require "generators/lobot/install_generator"
