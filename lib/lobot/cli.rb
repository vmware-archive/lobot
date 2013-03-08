require "thor"
require "thor/group"
require "pp"
require "tempfile"
require "json"
require "lobot/configuration_wizard"

module Lobot
  class CLI < ::Thor
    register(ConfigurationWizard, "setup", "setup", ConfigurationWizard::DESCRIPTION_TEXT)

    desc "ssh", "SSH into Lobot"
    def ssh
      exec("ssh -i #{lobot_config.server_ssh_key_path} ubuntu@#{lobot_config.master} -p #{lobot_config.ssh_port}")
    end

    desc "open", "Open a browser to Lobot"
    def open
      exec("open -a /Applications/Safari.app https://#{lobot_config.node_attributes.nginx.basic_auth_user}:#{lobot_config.node_attributes.nginx.basic_auth_password}@#{lobot_config.master}/")
    end

    desc "create", "Create a new Lobot server using EC2"
    def create
      server = amazon.with_key_pair(lobot_config.server_ssh_pubkey) do |keypair_name|
        amazon.create_security_group("lobot")
        amazon.open_port("lobot", 22, 443)
        amazon.launch_server(keypair_name, "lobot", lobot_config.instance_size)
      end

      say("Writing ip address for ec2: #{server.public_ip_address}")

      known_hosts.update(server.public_ip_address)

      lobot_config.update(master: server.public_ip_address, instance_id: server.id)
    end

    desc "destroy_ec2", "Destroys all the lobot resources that we can find on ec2.  Be Careful!"
    method_option :all, default: false
    method_option :force, default: false
    def destroy_ec2
      instance = (options['all'] ? :all : lobot_config.instance_id)

      amazon.destroy_ec2(confirmation_proc(options['force']), instance) do |server|
        say("Clearing ip address for ec2: #{server.public_ip_address}")

        known_hosts.remove(lobot_config.master)

        lobot_config.update(master: nil, instance_id: nil)
      end
    end

    desc "create_vagrant", "Lowers the price of heroin to reasonable levels"
    def create_vagrant
      spawn_env = {"LOBOT_SSH_KEY" => lobot_config.server_ssh_pubkey_path,
                   "VAGRANT_HOME" => File.expand_path("~")}
      spawn_options = {chdir: lobot_root_path}

      pid = Process.spawn(spawn_env, "vagrant up", spawn_options)
      Process.wait(pid)

      vagrant_ip = "192.168.33.10"

      say("Writing ip address for vagrant: #{vagrant_ip}")

      known_hosts.update(vagrant_ip)

      lobot_config.update(master: vagrant_ip)
    end

    desc "config", "Dumps all configuration data for Lobot"
    def config
      say(lobot_config.to_hash.inspect)
    end

    desc "certificate", "Dump the certificate"
    def certificate
      say(keychain.fetch_remote_certificate("https://#{lobot_config.master}"))
    end

    desc "bootstrap", "Configures Lobot's master node"
    def bootstrap
      sync_bootstrap_script
      master_server.system!("bash -l script/bootstrap_server.sh")
    rescue Errno::ECONNRESET
      sleep 1
    end

    desc "chef", "Uploads chef recipes and runs them"
    def chef
      sync_chef_recipes
      upload_soloist
      sync_github_ssh_key
      master_server.upload(File.expand_path('../../../templates/Gemfile-remote', __FILE__), 'Gemfile')
      master_server.system!("bash -l -c 'rvm use 1.9.3; bundle install; soloist'")    rescue Errno::ECONNRESET
      sleep 1
    end

    desc "add_build <name> <repository> <branch> <command>", "Adds a build to Lobot"
    def add_build(name, repository, branch, command)
      raise lobot_config.errors.join(" and ") unless lobot_config.valid?

      lobot_config.add_build(name, repository, branch, command)
      lobot_config.save
    end

    desc "trust_certificate", "Adds the current master's certificate to your OSX keychain"
    def trust_certificate
      keychain = Keychain.new("/Library/Keychains/System.keychain")
      certificate_contents = keychain.fetch_remote_certificate("https://#{lobot_config.master}/")
      keychain.add_certificate(certificate_contents)
    end

    no_tasks do
      def master_server
        @master_server ||= Lobot::Sobo.new(lobot_config.master, lobot_config.server_ssh_key_path)
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
        master_server.upload(lobot_config.github_ssh_key_path, "~/.ssh/id_rsa")
      end

      def sync_chef_recipes
        master_server.upload(File.join(lobot_root_path, "chef/"), "chef/")
        master_server.upload("cookbooks/", "chef/project-cookbooks/")
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

    def known_hosts
      Lobot::KnownHosts.new(known_hosts_path)
    end

    # The proc is given a Fog server object and must return true/false
    def confirmation_proc(force)
      if force
        ->(_) { true }
      else
        ->(server) {
          ask("DESTROY #{server.id} (#{server.public_ip_address})?", :limited_to => ["", "YES", "NO"]) == "YES"
        }
      end
    end
  end
end