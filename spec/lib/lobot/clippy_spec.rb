require 'spec_helper'

describe Lobot::Clippy do
  let(:working_path) { Dir.mktmpdir }
  let(:cli) { double(:cli).as_null_object }
  let(:clippy) { Lobot::Clippy.new }

  before { clippy.stub(:cli => cli) }

  around do |example|
    Dir.chdir(working_path) { example.run }
  end

  describe "#config" do
    it "creates the config directory if it does not exist" do
      expect {
        clippy.config
      }.to change {
        File.directory?(File.join(working_path, "config"))
      }.from(false).to(true)
    end

    it "uses the values in your existing lobot.yml" do
      FileUtils.mkdir_p "config"
      config = Lobot::Config.new(:path => "config/lobot.yml")
      config.ssh_port = 2222
      config.save

      clippy.config.ssh_port.should == 2222
    end

    it "saves off the config to config/lobot.yml" do
      expect {
        clippy.config.save
      }.to change {
        File.exists?(File.join(working_path, "config", "lobot.yml"))
      }.from(false).to(true)
    end
  end

  describe "#ask_with_default" do
    it "makes you feel like you need a shower" do
      clippy.should_receive(:ask).with("Your ID [1]:")
      clippy.ask_with_default("Your ID", "1")
    end

    it "defaults to the default value" do
      clippy.should_receive(:ask).and_return("")
      clippy.ask_with_default("Who is buried in Grant's Tomb", "Grant").should == "Grant"
    end

    it "uses the provided answer" do
      clippy.should_receive(:ask).and_return("robert e lee's left nipple")
      clippy.ask_with_default("Who is buried in Grant's Tomb", "Grant").should_not == "Grant"
    end

    it "does not display a nil default" do
      clippy.should_receive(:ask).with("Monkey mustache:")
      clippy.ask_with_default("Monkey mustache", nil)
    end
  end

  describe "#clippy" do
    before do
      clippy.stub(:ask => "totally-valid-value", :yes? => true, :say => nil)
      clippy.config.stub(:save)
    end

    it "Says that you're trying to set up a ci box" do
      question = "It looks like you're trying to set up a CI Box. Can I help?"
      clippy.should_receive(:yes?).with(question)
      clippy.clippy
    end

    it "prompts for aws credentials" do
      clippy.should_receive(:prompt_for_aws)
      clippy.clippy
    end

    it "prompts for nginx basic auth credentials" do
      clippy.should_receive(:prompt_for_basic_auth)
      clippy.clippy
    end

    it "prompts for an ssh key" do
      clippy.should_receive(:prompt_for_ssh_key)
      clippy.clippy
    end

    it "prompts for a github key" do
      clippy.should_receive(:prompt_for_github_key)
      clippy.clippy
    end

    it "prompts for a build" do
      clippy.should_receive(:prompt_for_build)
      clippy.clippy
    end

    it "saves the config" do
      clippy.config.should_receive(:save)
      clippy.clippy
    end

    it "prompts to start an instance on amazon" do
      clippy.should_receive(:prompt_for_amazon_create)
      clippy.clippy
    end

    it "provisions the server" do
      clippy.should_receive(:provision_server)
      clippy.clippy
    end
  end

  describe "#prompt_for_aws" do
    before { clippy.stub(:say) }

    it "reads in the key and secret" do
      clippy.should_receive(:ask).and_return("aws-key")
      clippy.should_receive(:ask).and_return("aws-secret-key")

      clippy.prompt_for_aws

      clippy.config.aws_key.should == "aws-key"
      clippy.config.aws_secret.should == "aws-secret-key"
    end
  end

  describe "#prompt_for_basic_auth" do
    it "prompts for the username and password" do
      clippy.should_receive(:ask).and_return("admin")
      clippy.should_receive(:ask).and_return("password")

      clippy.prompt_for_basic_auth

      clippy.config.node_attributes.nginx.basic_auth_user.should == "admin"
      clippy.config.node_attributes.nginx.basic_auth_password.should == "password"
    end
  end

  describe "#prompt_for_server_ssh_key" do
    it "prompts for the path" do
      clippy.should_receive(:ask).and_return("~/.ssh/top_secret_rsa")

      clippy.prompt_for_ssh_key

      clippy.config.server_ssh_key.should == File.expand_path("~/.ssh/top_secret_rsa")
    end
  end

  describe "#prompt_for_github_key" do
    it "prompts for the path" do
      clippy.should_receive(:ask).and_return("~/.ssh/the_matthew_kocher_memorial_key")

      clippy.prompt_for_github_key

      clippy.config.github_ssh_key.should == File.expand_path("~/.ssh/the_matthew_kocher_memorial_key")
    end
  end

  describe "#prompt_for_build" do
    before { clippy.stub(:ask) }

    context "when there are no builds" do
      it "asks you for the build name" do
        clippy.should_receive(:ask).and_return("fancy-build")
        clippy.prompt_for_build
        clippy.config.node_attributes.jenkins.builds.first["name"].should == "fancy-build"
      end

      it "asks you for the git repository" do
        clippy.should_receive(:ask)
        clippy.should_receive(:ask).and_return("earwax-under-my-pillow")
        clippy.prompt_for_build
        clippy.config.node_attributes.jenkins.builds.first["repository"].should == "earwax-under-my-pillow"
      end

      it "asks you for the build command" do
        clippy.should_receive(:ask).twice
        clippy.should_receive(:ask).and_return("unit-tested-bash")
        clippy.prompt_for_build
        clippy.config.node_attributes.jenkins.builds.first["command"].should == "unit-tested-bash"
      end

      it "always builds the master branch" do
        clippy.prompt_for_build
        clippy.config.node_attributes.jenkins.builds.first["branch"].should == "master"
      end
    end

    context "when there are builds" do
      before do
        clippy.stub(:ask_with_default)

        clippy.config.node_attributes.jenkins.builds << {
          "name" => "first-post",
          "repository" => "what",
          "command" => "hot-grits",
          "branch" => "oak"
        }

        clippy.config.node_attributes.jenkins.builds << {
          "name" => "grails",
          "repository" => "huh",
          "command" => "colored-greens",
          "branch" => "larch"
        }
      end

      it "prompts for the name using the first build as a default" do
        clippy.should_receive(:ask_with_default).with(anything, "first-post")
        clippy.prompt_for_build
      end

      it "prompts for the repository using the first build as a default" do
        clippy.should_receive(:ask_with_default)
        clippy.should_receive(:ask_with_default).with(anything, "what")
        clippy.prompt_for_build
      end

      it "prompts for the repository using the first build as a default" do
        clippy.should_receive(:ask_with_default).twice
        clippy.should_receive(:ask_with_default).with(anything, "hot-grits")
        clippy.prompt_for_build
      end
    end
  end

  describe "#prompt_for_amazon_create" do
    before { clippy.stub(:yes? => true, :say => nil) }

    context "when there is not an instance in the config" do
      it "asks to start an amazon instance" do
        clippy.should_receive(:yes?).and_return(false)
        clippy.prompt_for_amazon_create
      end

      it "calls create on CLI" do
        cli.should_receive(:create)
        clippy.prompt_for_amazon_create
      end
    end

    context "when there is an instance in the config" do
      before { clippy.config.master = "1.123.123.1" }

      it "does not ask to start an instance" do
        clippy.should_not_receive(:yes?)
        clippy.prompt_for_amazon_create
      end

      it "does not create an instance" do
        cli.should_not_receive(:create)
        clippy.prompt_for_amazon_create
      end
    end
  end

  describe "#provision_server" do
    before { clippy.stub(:say) }

    context "when there is no instance in the config" do
      it "does not bootstrap the instance" do
        cli.should_not_receive(:bootstrap)
        clippy.provision_server
      end

      it "does not run chef" do
        cli.should_not_receive(:chef)
        clippy.provision_server
      end
    end

    context "when an instance exists" do
      before do
        clippy.config
        clippy.config.master = "1.2.3.4"
        clippy.config.save
        clippy.config.master = nil
      end

      it "bootstraps the instance" do
        cli.should_receive(:bootstrap)
        clippy.provision_server
      end

      it "runs chef" do
        cli.should_receive(:chef)
        clippy.provision_server
      end
    end
  end
end
