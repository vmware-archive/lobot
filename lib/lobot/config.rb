require "hashie"

module Lobot
  class Config
    attr_accessor :ssh_port, :master, :server_ssh_key, :basic_auth_user, :basic_auth_password

    def initialize(config_hash = {})
      config = Hashie::Mash.new(config_hash)
      @ssh_port = config.ssh_port || 22
      @master = config.master || "127.0.0.1"
      @server_ssh_key = config.server_ssh_key || File.expand_path("~/.ssh/lobot_id_rsa")
      @basic_auth_user = config.basic_auth_user || "ci"
      @basic_auth_password = config.basic_auth_password
    end

    def self.from_file(yaml)
      config = nil
      File.open(yaml, "r") { |file| config = YAML::load(file) }
      self.new(config)
    end
  end
end