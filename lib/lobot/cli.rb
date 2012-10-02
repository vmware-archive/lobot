require "thor"
require "lobot/config"

module Lobot
  class CLI < Thor
    desc "ssh", "SSH into Lobot"
    def ssh
      exec("ssh -i #{lobot_config.server_ssh_key} ubuntu@#{lobot_config.master} -p #{lobot_config.ssh_port}")
    end

    desc "open", "Open a browser to Lobot"
    def open
      exec("open https://#{lobot_config.basic_auth_user}:#{lobot_config.basic_auth_password}@#{lobot_config.master}/")
    end

    no_tasks do
      def lobot_config
        @lobot_config ||= Lobot::Config.from_file(lobot_config_path)
      end
    end

    private
    def lobot_config_path
      File.expand_path("config/lobot.yml", Dir.pwd)
    end
  end
end