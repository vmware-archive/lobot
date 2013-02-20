require 'spec_helper'

describe Lobot::Clippy do
  let(:working_path) { Dir.mktmpdir }
  let(:clippy) { Lobot::Clippy.new }

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
      clippy.stub(:ask => "totally-valid-value", :yes? => true)
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

    it "saves the config" do
      clippy.config.should_receive(:save)
      clippy.clippy
    end
  end

  describe "#prompt_for_aws" do
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
end
