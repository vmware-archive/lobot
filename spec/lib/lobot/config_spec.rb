# encoding: UTF-8
require "spec_helper"

describe Lobot::Config do
  let(:default_config) { Lobot::Config.new }

  describe "#add_build" do
    let(:name) { "bob" }
    let(:repository) { "http://github.com/mkocher/soloist.git" }
    let(:branch) { "master" }
    let(:command) { "script/ci_build.sh" }

    let(:build_params) { {
      "name" => name,
      "repository" => repository,
      "command" => command,
      "branch" => branch,
      "junit_publisher" => true
    } }

    it "adds a build to the node attributes" do
      subject.add_build(name, repository, branch, command)
      subject.node_attributes.jenkins.builds.should =~ [build_params]
    end

    it "does not add a build twice with identical parameters" do
      subject.add_build(name, repository, branch, command)
      subject.add_build(name, repository, branch, command)
      subject.node_attributes.jenkins.builds.should =~ [build_params]
    end
  end

  describe "#display" do
    before do
      subject.add_build("default", "repos", "branch", "command")
      subject.add_build("integration", "repos", "branch", "command")
      subject.add_build("enemy", "repos", "branch", "command")
    end

    context "without a running instance" do
      it "returns a pretty-printed string version of the config" do
        # The basic_auth_password will be blank on CI, so we force it
        subject.stub(:basic_auth_password).and_return('password')

        subject.display.should == <<OOTPÜT
-- ciborg configuration --
  Instance ID:
  IP Address:
  Instance size:      #{subject.instance_size}

  Builds:
    default
    integration
    enemy

  Web URL:
  User name:          #{subject.basic_auth_user}
  User password:      #{subject.basic_auth_password}

  CC Menu URL:
OOTPÜT
      end
    end

    context "with a running instance" do
      subject do
        Lobot::Password.stub(:generate).and_return('password')
        Lobot::Config.new({instance_id: 'i-xxxxxx',
                                   master: '127.0.0.1',
                                   instance_size: 'c9.humungous'
                                  })
      end

      it "returns a pretty-printed string version of the config" do

        subject.display.should == <<OOTPÜT
-- ciborg configuration --
  Instance ID:        i-xxxxxx
  IP Address:         127.0.0.1
  Instance size:      c9.humungous

  Builds:
    default           https://127.0.0.1/job/default/rssAll
    integration       https://127.0.0.1/job/integration/rssAll
    enemy             https://127.0.0.1/job/enemy/rssAll

  Web URL:            https://127.0.0.1
  User name:          ci
  User password:      password

  CC Menu URL:        https://ci:password@127.0.0.1/cc.xml
OOTPÜT
      end
    end
  end

  describe "with a file" do
    let(:config_contents) { {ssh_port: 42} }
    let(:tempfile) do
      Tempfile.new('lobot-config').tap do |file|
        file.write YAML.dump(config_contents)
        file.close
      end
    end

    let(:config) { Lobot::Config.from_file(tempfile.path) }

    describe "#valid?" do
      it "returns true by default" do
        config.should be_valid
        config.errors.should be_empty
      end

      context "when there is no jenkins config" do
        let(:config_contents) { {node_attributes: {}} }

        it "returns false" do
          config.should_not be_valid
        end
      end

      context "when jenkins config has no builds" do
        let(:config_contents) { {node_attributes: {jenkins: {}}} }

        it "returns false" do
          config.should_not be_valid
        end

        it "has a useful error message" do
          config.errors.should include("your config file does not have a [:node_attributes][:jenkins][:builds] key")
        end
      end
    end

    describe ".from_file" do
      it "loads from a yaml file" do
        config.ssh_port.should == 42
      end

      context "when the yaml file does not exist" do
        let(:config) { Lobot::Config.from_file("#{tempfile.path}-nonexistent") }

        it "does not load from a yaml file" do
          config.ssh_port.should == 22
        end
      end

      context "handles deprecated keypair_name attribute" do
        let(:tempfile) do
          Tempfile.new('lobot-config').tap do |file|
            file.write <<-YAML
---
ssh_port: 42
keypair_name: lobot
            YAML
            file.close
          end
        end
        let(:config) { Lobot::Config.from_file(tempfile.path) }

        it "silently removes it from the configuration" do
          config.ssh_port.should == 42
        end

      end
    end

    describe "#save" do
      it "writes the values to the file" do
        config.ssh_port = 20912
        config.save
        config = Lobot::Config.from_file(tempfile.path)
        config.ssh_port.should == 20912
      end
    end

    describe "#update" do
      it "sets and persists the provided values" do
        config.update(ssh_port: 20912)
        config = Lobot::Config.from_file(tempfile.path)
        config.ssh_port.should == 20912
      end
    end

    describe "soloistrc-specific attributes" do
      let(:recipes) { ["pivotal_workstation::broken_postgres", "pivotal_workstation::janus"] }
      let(:node_attributes) { default_config.node_attributes.merge({"radiator" => {"busted" => "hella"}}) }
      let(:config_contents) { {recipes: recipes, node_attributes: node_attributes} }

      describe "#recipes" do
        it "preserves the recipes in a config file" do
          config.recipes.should == recipes
        end
      end

      describe "#soloistrc" do
        it "has recipes" do
          config.soloistrc['recipes'].should == recipes
        end

        it "has node_attributes" do
          config.soloistrc['node_attributes']['radiator']['busted'].should == "hella"
        end
      end
    end
  end

  describe "defaults" do
    its(:ssh_port) { should == 22 }
    its(:recipes) { should == ["pivotal_ci::jenkins", "pivotal_ci::limited_travis_ci_environment", "pivotal_ci"] }
    its(:cookbook_paths) { should == ['./chef/cookbooks/', './chef/travis-cookbooks/ci_environment', './chef/project-cookbooks'] }
    its(:instance_size) { should == 'c1.medium' }

    context 'when id_rsa exists' do
      before { File.stub(:exists?).and_return(true) }

      its(:server_ssh_key_path) { should == File.expand_path('~/.ssh/id_rsa')}
      its(:github_ssh_key_path) { should == File.expand_path('~/.ssh/id_rsa')}
    end

    context 'when id_rsa does not exist' do
      before { File.stub(:exists?).and_return(false) }

      its(:server_ssh_key_path) { should_not be }
      its(:github_ssh_key_path) { should_not be }
    end

    describe "#node_attributes" do
      it "defaults to overwriting the travis build environment" do
        subject.node_attributes.travis_build_environment.to_hash.should == {
          "user" => "jenkins",
          "group" => "nogroup",
          "home" => "/var/lib/jenkins"
        }
      end
    end

    describe "#soloistrc" do
      before do
        Haddock::Password.stub(:generate).and_return('a_secure_password')
      end

      it "defaults to recipes and nginx basic auth" do
        subject.soloistrc.should == {
          "recipes" => subject.recipes,
          "cookbook_paths" => subject.cookbook_paths,
          "node_attributes" => {
            "nginx" => {
              "basic_auth_user" => "ci",
              "basic_auth_password" => 'a_secure_password'
            },
            "travis_build_environment" => {
              "user" => "jenkins",
              "group" => "nogroup",
              "home" => "/var/lib/jenkins"
            },
            "jenkins" => {
              "builds" => []
            }
          }
        }
      end
    end

    describe 'ssh key accessors' do
      before do
        File.stub(:exists?).with(File.expand_path('~/.ssh/id_rsa')).and_return(true)
      end

      context 'github' do
        before do
          File.stub(:read).with(subject.github_ssh_key_path) { "---GITHUB PRIVATE---" }
          File.stub(:read).with(subject.github_ssh_pubkey_path) { "---GITHUB PUBLIC---" }
        end

        its(:github_ssh_key_path) { should =~ /^\/.*id_rsa$/ }
        its(:github_ssh_pubkey_path) { should =~ /^\/.*id_rsa\.pub$/ }

        its(:github_ssh_key) { should == "---GITHUB PRIVATE---" }
        its(:github_ssh_pubkey) { should == "---GITHUB PUBLIC---" }
      end

      context 'server' do
        before do
          File.stub(:read).with(subject.server_ssh_key_path) { "---SERVER PRIVATE---" }
          File.stub(:read).with(subject.server_ssh_pubkey_path) { "---SERVER PUBLIC---" }
        end

        its(:server_ssh_key_path) { should =~ /^\/.*id_rsa$/ }
        its(:server_ssh_pubkey_path) { should =~ /^\/.*id_rsa\.pub$/ }

        its(:server_ssh_key) { should == "---SERVER PRIVATE---" }
        its(:server_ssh_pubkey) { should == "---SERVER PUBLIC---" }
      end
    end
  end
end