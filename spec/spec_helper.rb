$: << File.expand_path("../../lib", __FILE__)

require "lobot"
require "godot"
require "tempfile"

module SpecHelpers
  def key_pair_path
    @key_pair_path ||= begin
      path = ""
      Tempfile.new("ssh_key").tap do |tempfile|
        path = tempfile.path
        tempfile.close!
      end
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
end

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
  c.include SpecHelpers
end
