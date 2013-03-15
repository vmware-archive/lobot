$: << File.expand_path("../../lib", __FILE__)

require "lobot"
require "godot"
require "tempfile"

module SpecHelpers
  def self.ec2_credentials_present?
    ENV.has_key?("EC2_KEY") && ENV.has_key?("EC2_SECRET")
  end

  def ssh_key_pair_path
    File.join(File.dirname(__FILE__), 'fixtures', 'ssh_keys', 'vagrant_test_key')
  end
end

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
  c.include SpecHelpers
end

$stderr.puts "***WARNING*** EC2 credentials are not present, so no AWS tests will be run" unless SpecHelpers::ec2_credentials_present?
