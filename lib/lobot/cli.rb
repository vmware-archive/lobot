require "thor"
require "lobot/config"
require "lobot/sobo"
require "lobot/amazon"
require "lobot/jenkins"
require "lobot/keychain"
require "pp"
require "tempfile"
require "json"

module Lobot
  class CLI < Thor
    desc "ssh", "SSH into Lobot"
    def ssh
      exec("ssh -i #{lobot_config.server_ssh_key} ubuntu@#{lobot_config.master} -p #{lobot_config.ssh_port}")
    end

    desc "open", "Open a browser to Lobot"
    def open
      exec("open -a /Applications/Safari.app https://#{lobot_config.node_attributes.nginx.basic_auth_user}:#{lobot_config.node_attributes.nginx.basic_auth_password}@#{lobot_config.master}/")
    end

    desc "create", "Create a new Lobot server using EC2"
    def create
      ssh_key_path = File.expand_path("#{lobot_config.server_ssh_key}.pub")

      amazon.add_key_pair("lobot", ssh_key_path)
      amazon.create_security_group("lobot")
      amazon.open_port("lobot", 22, 443)
      server = amazon.launch_server("lobot", "lobot", lobot_config.instance_size)

      puts "Writing ip address for ec2: #{server.public_ip_address}"
      lobot_config.master = server.public_ip_address
      lobot_config.instance_id = server.id
      lobot_config.save

      update_known_hosts
    end

    desc "destroy_ec2", "Destroys all the lobot resources that we can find on ec2.  Be Careful!"
    def destroy_ec2
      amazon.destroy_ec2
      lobot_config.master = nil
    end

    desc "create_vagrant", "Lowers the price of heroin to reasonable levels"
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

      update_known_hosts
    end

    desc "config", "Dumps all configuration data for Lobot"
    def config
      pp lobot_config.to_hash
    end

    desc "certificate", "Dump the certificate"
    def certificate
      p keychain.fetch_remote_certificate("https://#{lobot_config.master}")
    end

    desc "bootstrap", "Configures Lobot's master node"
    def bootstrap
      sync_bootstrap_script
      master_server.exec("bash -l script/bootstrap_server.sh")
    rescue Errno::ECONNRESET
      sleep 1
    end

    desc "chef", "Uploads chef recipes and runs them"
    def chef
      sync_chef_recipes
      upload_soloist
      sync_github_ssh_key
      master_server.exec("bash -l -c 'rvm use 1.9.3; gem list | grep soloist || gem install --no-ri --no-rdoc soloist; soloist'")
    rescue Errno::ECONNRESET
      sleep 1
    end

    desc "add_build(name, repository, branch, command)", "Adds a build to Lobot"
    def add_build(name, repository, branch, command)
      build = {
        "name" => name,
        "repository" => repository,
        "branch" => branch,
        "command" => command
      }
      lobot_config.node_attributes = lobot_config.node_attributes.tap do |config|
        config.jenkins.builds << build unless config.jenkins.builds.include?(build)
      end
      lobot_config.save
    end

    no_tasks do
      def master_server
        @master_server ||= Lobot::Sobo.new(lobot_config.master, lobot_config.server_ssh_key)
      end

      def lobot_config
        @lobot_config ||= Lobot::Config.from_file(lobot_config_path)
      end

      def amazon
        @amazon ||= Lobot::Amazon.new(lobot_config.aws_key, lobot_config.aws_secret)
      end

      def keychain
        @keychain ||= Lobot::Keychain.new("/Library/Keychains/System.keychain")
      end

      def sync_bootstrap_script
        master_server.upload(File.join(lobot_root_path, "script/"), "script/")
      end

      def sync_github_ssh_key
        master_server.upload(lobot_config.github_ssh_key, "~/.ssh/id_rsa")
      end

      def sync_chef_recipes
        master_server.upload(File.join(lobot_root_path, "chef/"), "chef/")
      end

      def upload_soloist
        Tempfile.open("lobot-soloistrc") do |file|
          file.write(YAML.dump(JSON.parse(JSON.dump(lobot_config.soloistrc))))
          file.close
          master_server.upload(file.path, "soloistrc")
        end
      end
    end

    private
    def lobot_root_path
      File.expand_path('../../..', __FILE__)
    end

    def lobot_config_path
      File.expand_path("config/lobot.yml", Dir.pwd)
    end

    def known_hosts_path
      File.expand_path('~/.ssh/known_hosts')
    end

    def update_known_hosts
      raise "failed to remove old host key from known_hosts" unless system "ssh-keygen -R #{lobot_config.master} -f #{known_hosts_path} 2> /dev/null"
      raise "failed to add host key to known_hosts" unless system "ssh-keyscan #{lobot_config.master} 2> /dev/null >> #{known_hosts_path}"
    end
  end
end