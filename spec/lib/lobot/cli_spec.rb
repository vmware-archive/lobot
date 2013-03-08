require "spec_helper"

describe Lobot::CLI do
  let(:cli) { subject }
  let(:sobo) { Lobot::Sobo.new(lobot_config.master, lobot_config.server_ssh_key_path) }

  before do
    cli.stub(:lobot_config).and_return(lobot_config) # lobot_config must be defined in each context below
  end

  after do
    cleanup_temporary_ssh_keys
  end

  context 'with Amazon' do
    let(:lobot_config) { Lobot::Config.new(
        :aws_key => ENV["EC2_KEY"],
        :aws_secret => ENV["EC2_SECRET"],
        :server_ssh_key => key_pair_path)
    }

    describe '#create & #destroy', :slow, :ec2 do
      it "launches an instance and associates elastic ip" do
        pending "Missing EC2 Credentials" unless ENV.has_key?("EC2_KEY") && ENV.has_key?("EC2_SECRET")
        cli.lobot_config.instance_size = 't1.micro'
        expect { cli.create }.to change { lobot_config.master }.from(nil)

        cli.stub(:options).and_return({'force' => 'force'})
        expect { cli.destroy_ec2 }.to change { lobot_config.master }.to(nil)
      end
    end

    describe "#ssh" do
      it "starts an ssh session to the lobot host" do
        cli.should_receive(:exec).with("ssh -i #{cli.lobot_config.server_ssh_key_path} ubuntu@#{cli.lobot_config.master} -p #{cli.lobot_config.ssh_port}")
        cli.ssh
      end
    end

    describe "#open", :osx do
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

    describe "#trust_certificate", :osx do
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

      context "when the config is invalid" do
        before { lobot_config.node_attributes.jenkins = {} }

        it "raises an error" do
          expect do
            cli.add_build(name, repository, branch, command)
          end.to raise_error %r{your config file does not have a}
        end
      end

      context "when the configuration is valid" do
        context "with persisted configuration data" do
          let(:tempfile) do
            Tempfile.new('lobot-config').tap do |file|
              file.write YAML.dump({})
              file.close
            end
          end

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
    end

    context "with a fake amazon" do
      let(:ip_address) { "127.0.0.1" }
      let(:server) { double("server", :public_ip_address => ip_address).as_null_object }
      let(:amazon) { double("AMZN", :launch_server => server).as_null_object }
      let(:instance_id) { 'i-xxxxxx' }

      before do
        cli.stub(:amazon).and_return(amazon)
      end

      describe "#create" do
        before do
          amazon.stub(:with_key_pair).and_yield("unique-key-pair-name")
        end

        it "uses the configured key pair" do
          amazon.should_receive(:with_key_pair).with(cli.lobot_config.server_ssh_pubkey)
          cli.create
        end

        context "with a custom instance size", :slow => false do
          before { cli.lobot_config.instance_size = 'really_big_instance' }

          it "launches the instance with the configured instance size" do
            amazon.should_receive(:launch_server).with(anything, anything, 'really_big_instance')
            cli.create
          end
        end
      end

      describe "destroy_ec2" do
        before do
          cli.lobot_config.master = ip_address
          cli.lobot_config.instance_id = instance_id
        end

        context 'by default' do
          before do
            amazon.stub(:destroy_ec2).and_yield(mock("SERVER").as_null_object)
          end

          it 'deletes the known instance' do
            amazon.should_receive(:destroy_ec2).and_yield(mock("SERVER").as_null_object)
            cli.destroy_ec2
          end

          it 'clears the master ip address' do
            expect { cli.destroy_ec2 }.to change(cli.lobot_config, :master).to(nil)
          end

          it 'clears the master instance id' do
            expect { cli.destroy_ec2 }.to change(cli.lobot_config, :instance_id).to(nil)
          end

          it 'does not delete sibling instances' do
            amazon.should_receive(:destroy_ec2).with(a_kind_of(Proc), instance_id)
            cli.destroy_ec2
          end

          it 'prompts for confirmation' do
            cli.should_receive(:ask).and_return(true)
            amazon.should_receive(:destroy_ec2).with(a_kind_of(Proc), instance_id) do |confirm_proc, instance_id|
              confirm_proc.call(mock("SERVER").as_null_object)
            end
            cli.destroy_ec2
          end
        end

        context 'with --all' do
          before do
            cli.stub(:options).and_return({'all' => 'all'})
          end

          it 'deletes everything tagged "lobot"' do
            amazon.should_receive(:destroy_ec2).with(a_kind_of(Proc), :all)
            cli.destroy_ec2
          end
        end

        context 'with --force' do
          before do
            cli.stub(:options).and_return({'force' => 'force'})
          end

          it 'does not prompt for confirmation' do
            cli.should_not_receive(:ask)
            amazon.should_receive(:destroy_ec2).with(a_kind_of(Proc), instance_id) do |confirm_proc, instance_id|
              confirm_proc.call(mock("SERVER").as_null_object)
            end
            cli.destroy_ec2
          end
        end
      end
    end
  end

  context 'with Vagrant' do
    let(:lobot_config) {
      Lobot::Config.new(
          "node_attributes" => {
              "jenkins" => {
                  "builds" => []
              },
              "nginx" => {
                  "basic_auth_user" => "ci",
                  "basic_auth_password" => "secret"
              }
          },
          "server_ssh_key" => key_pair_path,
          "github_ssh_key" => key_pair_path
      )
    }

    describe "#create_vagrant", :vagrant do
      it "starts a virtual machine" do
        cli.create_vagrant
        Godot.wait('192.168.33.10', 22).should be
      end

      it "updates the config master ip address" do
        expect { cli.create_vagrant }.to change { lobot_config.master }.to('192.168.33.10')
      end
    end

    describe "#bootstrap", :slow do
      before { cli.create_vagrant }

      it "installs all necessary packages, installs rvm and sets up the user" do
        cli.bootstrap
        sobo.backtick("dpkg --get-selections").should include("libncurses5-dev")
        sobo.backtick("ls /usr/local/rvm/").should_not be_empty
        sobo.backtick("groups ubuntu").should include("rvm")
      end
    end

    describe "#chef", :slow do
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
        FileUtils.mkdir_p("/tmp/lobot_dummy/cookbooks/pork/recipes/")
        File.write("/tmp/lobot_dummy/cookbooks/pork/recipes/bacon.rb", "package 'htop'")
      end

      after do
        FileUtils.rm_rf("/tmp/lobot_dummy")
      end

      it "runs chef" do
        Dir.chdir('/tmp/lobot_dummy/') do
          cli.lobot_config.recipes = ["pivotal_ci::jenkins", "pivotal_ci::id_rsa", "pivotal_ci::git_config", "sysctl", "pivotal_ci::jenkins_config", "pork::bacon"]
          cli.chef
        end

        sobo.backtick("ls /var/lib/").should include "jenkins"
        sobo.backtick("grep 'kernel.shmmax=' /etc/sysctl.conf").should_not be_empty
        sobo.backtick("sudo cat /var/lib/jenkins/.ssh/id_rsa").should == lobot_config.github_ssh_key
        sobo.system("dpkg -l htop").should == 0

        godot.wait!
        godot.match!(/Bob/, 'api/json')
      end
    end
  end
end
