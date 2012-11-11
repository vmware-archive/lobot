require "spec_helper"

describe Lobot::CLI do
  let(:tempfile) do
    Tempfile.new('lobot-config').tap do |file|
      file.write YAML.dump({})
      file.close
    end
  end

  let(:lobot_config) { Lobot::Config.new(:aws_key => ENV["EC2_KEY"], :aws_secret => ENV["EC2_SECRET"]) }
  let(:cli) { subject }
  let(:sobo) { Lobot::Sobo.new(lobot_config.master, lobot_config.server_ssh_key) }

  before do
    cli.stub(:lobot_config).and_return(lobot_config)
  end

  describe "#ssh" do
    it "starts an ssh session to the lobot host" do
      cli.should_receive(:exec).with("ssh -i #{cli.lobot_config.server_ssh_key} ubuntu@#{cli.lobot_config.master} -p #{cli.lobot_config.ssh_port}")
      cli.ssh
    end
  end

  describe "#open" do
    let(:lobot_config) do
      Lobot::Config.new(:node_attributes => {
        :nginx => {
          :basic_auth_user => "ci",
          :basic_auth_password => "secret"
        }
      })
    end

    it "opens a web browser with the lobot page" do
      cli.should_receive(:exec).with("open -a /Applications/Safari.app https://#{cli.lobot_config.node_attributes.nginx.basic_auth_user}:#{cli.lobot_config.node_attributes.nginx.basic_auth_password}@#{cli.lobot_config.master}/")
      cli.open
    end
  end

  describe "#trust_certificate" do
    let(:keychain) { Lobot::Keychain.new("/Library/Keychains/System.keychain") }
    before { lobot_config.master = "192.168.99.99" }

    it "adds the key to the keychain" do
      fake_keychain = double(:keychain)
      fake_keychain.should_receive(:fetch_remote_certificate).with("https://#{lobot_config.master}/").and_return("IAMACERTIFICATE")
      fake_keychain.should_receive(:add_certificate).with("IAMACERTIFICATE")
      Lobot::Keychain.should_receive(:new).with("/Library/Keychains/System.keychain").and_return(fake_keychain)

      cli.trust_certificate
    end
  end

  describe "#add_build" do
    let(:name) { "bob" }
    let(:repository) { "http://github.com/mkocher/soloist.git" }
    let(:branch) { "master" }
    let(:command) { "script/ci_build.sh" }

    it "adds a build to the node attributes" do
      cli.add_build(name, repository, branch, command)
      lobot_config.node_attributes.jenkins.builds.should =~ [{
        "name" => "bob",
        "repository" => "http://github.com/mkocher/soloist.git",
        "command" => "script/ci_build.sh",
        "branch" => "master"
      }]
    end

    it "does not add a build twice with identical parameters" do
      cli.add_build(name, repository, branch, command)
      cli.add_build(name, repository, branch, command)
      lobot_config.node_attributes.jenkins.builds.should =~ [{
        "name" => "bob",
        "repository" => "http://github.com/mkocher/soloist.git",
        "command" => "script/ci_build.sh",
        "branch" => "master"
      }]
    end

    context "with persisted configuration data" do
      let(:lobot_config) { Lobot::Config.from_file(tempfile.path) }

      def builds
        cli.lobot_config.reload.node_attributes.jenkins.builds
      end

      it "persists a build" do
        cli.add_build(name, repository, branch, command)
        builds.should_not be_nil
        builds.should_not be_empty
      end
    end
  end

  shared_examples_for "a start command that updates known_hosts" do
    let(:key) { "AAAAB3NzaC1yc2EAAAADAQABAAABAQDjhJ/xZCgVhq9Xk+3DKJZ6tcgyIHcIXKSzu6Z/EK1uykyHeP/i7CwwKgiAv7lAV7B4UiUMHUm2nEiguog9VtYc6mc0g1N829lnuMhPRyOTb0SSYTNEN7Uuwy10cuq3Rd/9QAdxNV/voQW3Rl60BFzZvzp8UxJzCXFT1NmB+0W45X7Ypstv0oVV/EdyJJUuoPijQ097A4kHt6KUThKzxhagh1UrVTCE6eccscxuuRPX3yCEf8cUaVrKtuSE3vZnBcmSOY92zA4NV/YdJYNPIrKyCvWb/R+nC4R0pQNqv1gSEqPT51wYxKnvmIPFGntKaJSN2qmMlvs/AlFnFOeUsUFN" }
    let(:known_hosts_path) { Tempfile.new("known_hosts").path }

    def known_hosts_contents
      File.read(File.expand_path(known_hosts_path))
    end

    before do
      cli.stub(:known_hosts_path) { known_hosts_path }
    end

    it "clears out the entry in knownhosts as this is a new box but the ip may be recycled" do
      system "echo '#{ip_address} ssh-rsa #{key}' >> #{known_hosts_path}"
      action # Our vagrant box resets the first ssh connection. :-(
      action
      known_hosts_contents.should_not include(key)
      known_hosts_contents.should include(ip_address)
    end

    it "doesn't mess with other entries" do
      action
      expect { action }.not_to change { known_hosts_contents }
    end
  end

  describe "#create", :slow => true do
    it "launches an instance and associates elastic ip" do
      cli.lobot_config.instance_size = 't1.micro'
      expect { cli.create }.to change { lobot_config.master }.from(nil)
      expect { cli.destroy_ec2 }.to change { lobot_config.master }.to(nil)
    end

    context "with a fake amazon" do
      let(:ip_address) { "192.168.33.10" }
      let(:server) { double("server", :public_ip_address => ip_address).as_null_object }
      let(:amazon) { double("AMZN", :launch_server => server).as_null_object }

      before { cli.stub(:amazon).and_return(amazon) }

      def action
        cli.create
      end

      it_behaves_like "a start command that updates known_hosts"

      context "with a custom instance size", :slow => false do
        before { cli.lobot_config.instance_size = 'really_big_instance' }

        it "launches the instance with the configured instance size" do
          amazon.should_receive(:launch_server).with(anything, anything, 'really_big_instance')
          cli.create
        end
      end
    end
  end

  describe "#create_vagrant" do
    before do
      File.open(tempfile.path, "w") do |f|
        f.write(YAML.dump(
          "node_attributes" => {
            "nginx" => {
              "basic_auth_user" => "ci",
              "basic_auth_password" => "secret"
            }
          }
        ))
      end
    end

    def lobot_config
      Lobot::Config.from_file(tempfile.path)
    end

    it "starts a virtual machine" do
      cli.create_vagrant
      Godot.wait('192.168.33.10', 22).should be
    end

    it "updates the config master ip address" do
      expect { cli.create_vagrant }.to change { lobot_config.master }.to('192.168.33.10')
    end

    context "known_hosts" do
      let(:ip_address) { "192.168.33.10" }

      def action
        cli.create_vagrant
      end

      it_behaves_like "a start command that updates known_hosts"
    end
  end

  describe "#bootstrap", :slow => true do
    before { cli.create_vagrant }

    it "installs all necessary packages, installs rvm and sets up the user" do
      cli.bootstrap
      sobo.backtick("dpkg --get-selections").should include("libncurses5-dev")
      sobo.backtick("ls /usr/local/rvm/").should_not be_empty
      sobo.backtick("groups ubuntu").should include("rvm")
    end
  end

  describe "#chef", :slow => true do
    let(:name) { "Bob" }
    let(:repository) { "http://github.com/mkocher/soloist.git" }
    let(:branch) { "master" }
    let(:command) { "exit 0" }

    let(:godot) { Godot.new(cli.master_server.ip, 8080) }
    let(:jenkins) { Lobot::Jenkins.new(lobot_config) }

    before do
      cli.create_vagrant
      cli.bootstrap
      cli.add_build(name, repository, branch, command)
    end

    it "runs chef" do
      cli.lobot_config.recipes = ["pivotal_ci::jenkins", "pivotal_ci::id_rsa", "pivotal_ci::git_config", "sysctl", "pivotal_ci::jenkins_config"]
      cli.chef

      sobo.backtick("ls /var/lib/").should include "jenkins"
      sobo.backtick("grep 'kernel.shmmax=' /etc/sysctl.conf").should_not be_empty
      sobo.backtick("sudo cat /var/lib/jenkins/.ssh/id_rsa").should == File.read(lobot_config.github_ssh_key)

      godot.wait!
      godot.match!(/Bob/, 'api/json')
    end
  end
end
