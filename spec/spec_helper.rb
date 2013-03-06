$: << File.expand_path("../../lib", __FILE__)

require "lobot"
require "godot"
require "tempfile"

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
end
