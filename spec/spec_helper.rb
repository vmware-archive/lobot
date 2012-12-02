$: << File.expand_path("../../lib", __FILE__)

require "lobot"
require "lobot/cli"
require "godot"
require "tempfile"

Dir.glob(File.expand_path("../helpers/**/*.rb", __FILE__)).each { |h| require h}

RSpec.configure do |config|
  config.include IOHelpers
end
