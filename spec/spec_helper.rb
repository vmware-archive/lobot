$: << File.expand_path("../../lib", __FILE__)

require "lobot"
require "godot"
require "tempfile"

module SpecHelpers
  def self.ec2_credentials_present?
    ENV.has_key?("EC2_KEY") && ENV.has_key?("EC2_SECRET")
  end

  def key_pair_path
    @key_pair_path ||= begin
      path = unique_path
      system "ssh-keygen -q -f #{path} -P ''"
      path
    end
  end

  def cleanup_temporary_ssh_keys
    if @key_pair_path
      File.delete(@key_pair_path)
      File.delete(@key_pair_path+".pub")
    end
  end

  private

  # Tempfile will normally unlink the file during garbage collection
  # We want a unique path, but we don't want the actual file to stick around
  def unique_path
    tempfile = Tempfile.new("ssh_key")
    path = tempfile.path
    tempfile.close!
    path
  end
end

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
  c.include SpecHelpers
end

$stderr.puts "***WARNING*** EC2 credentials are not present, so no AWS tests will be run" unless SpecHelpers::ec2_credentials_present?
