require "thor"
require "lobot/config"
require "lobot/port_checker"
require "lobot/sobo"
require "pp"

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

    desc "create_vagrant", "Create a new Lobot server using Vagrant"
    def create_vagrant
      spawn_env = {"LOBOT_SSH_KEY" => File.expand_path("#{lobot_config.server_ssh_key}.pub"),
                   "VAGRANT_HOME" => File.expand_path("~")}
      spawn_options = {chdir: lobot_root_path}

      pid = Process.spawn(spawn_env, "vagrant up", spawn_options)
      Process.wait(pid)

      vagrant_ip = "192.168.33.10"

      puts "Writing ip address for vagrant: #{vagrant_ip}"
      lobot_config.master = vagrant_ip
      lobot_config.save
    end

    desc "config", "Dumps all configuration data for Lobot"
    def config
      pp lobot_config.to_hash
    end

    # desc "bootstrap", "Configures Lobot's master node"
    # def bootstrap
    #   master_server.upload(File.expand_path("script/", lobot_root_path), "script/")
    #   master_server.run! "chmod +x script/bootstrap_server.sh && script/bootstrap_server.sh"
    # end

    # desc "chef", "Uploads chef recipes and runs them"
    # def chef
    #   master_server.upload(File.join(lobot_root_path, "chef/"), "chef/")
    #   master_server.upload(File.expand_path("lib/generators/lobot/templates/soloistrc", lobot_root_path), "soloistrc")
    #   master_server.run! "rvm use 1.9.3; gem list | grep soloist || gem install --no-ri --no-rdoc soloist; soloist"
    # end

    no_tasks do
      # def master_server
      #   Sobo::Server.new(lobot_config.master, lobot_config.server_ssh_key)
      # end

      def lobot_config
        @lobot_config ||= Lobot::Config.from_file(lobot_config_path)
      end
    end

    private
    def lobot_root_path
      File.expand_path('../../..', __FILE__)
    end

    def lobot_config_path
      File.expand_path("config/lobot.yml", Dir.pwd)
    end
  end
end