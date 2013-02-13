require 'spec_helper'

describe Lobot::Generator do
  let(:working_path) { Dir.mktmpdir }
  let(:generator) { Lobot::Generator.new }

  around do |example|
    old_pwd = Dir.pwd
    Dir.chdir(working_path)
    example.run
    Dir.chdir(old_pwd)
  end

  describe "#config" do
    it "creates the config directory if it does not exist" do
      expect {
        generator.config
      }.to change {
        File.directory?(File.join(working_path, "config"))
      }.from(false).to(true)
    end

    it "uses the values in your existing lobot.yml" do
      FileUtils.mkdir_p "config"
      config = Lobot::Config.new(:path => "config/lobot.yml")
      config.ssh_port = 2222
      config.save

      generator.config.ssh_port.should == 2222
    end

    it "saves off the config to config/lobot.yml" do
      expect {
        generator.config.save
      }.to change {
        File.exists?(File.join(working_path, "config", "lobot.yml"))
      }.from(false).to(true)
    end
  end

  describe "#ask_with_default" do
    it "makes you feel like you need a shower" do
      generator.should_receive(:ask).with("Your ID [1]:")
      generator.ask_with_default("Your ID", "1")
    end

    it "defaults to the default value" do
      generator.should_receive(:ask).and_return("")
      generator.ask_with_default("Who is buried in Grant's Tomb", "Grant").should == "Grant"
    end

    it "uses the provided answer" do
      generator.should_receive(:ask).and_return("robert e lee's left nipple")
      generator.ask_with_default("Who is buried in Grant's Tomb", "Grant").should_not == "Grant"
    end

    it "does not display a nil default" do
      generator.should_receive(:ask).with("Monkey mustache:")
      generator.ask_with_default("Monkey mustache", nil)
    end
  end

  describe "#generate" do
    before do
      generator.stub(:ask => "totally-valid-value", :yes? => true)
      generator.config.stub(:save)
    end

    it "Says that you're trying to set up a ci box" do
      question = "It looks like you're trying to set up a CI Box. Can I help?"
      generator.should_receive(:yes?).with(question)
      generator.generate
    end

    it "prompts for aws credentials" do
      generator.should_receive(:prompt_for_aws)
      generator.generate
    end

    it "prompts for nginx basic auth credentials" do
      generator.should_receive(:prompt_for_basic_auth)
      generator.generate
    end

    it "prompts for an ssh key" do
      generator.should_receive(:prompt_for_ssh_key)
      generator.generate
    end

    it "prompts for a github key" do
      generator.should_receive(:prompt_for_github_key)
      generator.generate
    end

    it "saves the config" do
      generator.config.should_receive(:save)
      generator.generate
    end
  end

  describe "#prompt_for_aws" do
    it "reads in the key and secret" do
      generator.should_receive(:ask).and_return("aws-key")
      generator.should_receive(:ask).and_return("aws-secret-key")

      generator.prompt_for_aws

      generator.config.aws_key.should == "aws-key"
      generator.config.aws_secret.should == "aws-secret-key"
    end
  end

  describe "#prompt_for_basic_auth" do
    it "prompts for the username and password" do
      generator.should_receive(:ask).and_return("admin")
      generator.should_receive(:ask).and_return("password")

      generator.prompt_for_basic_auth

      generator.config.node_attributes.nginx.basic_auth_user.should == "admin"
      generator.config.node_attributes.nginx.basic_auth_password.should == "password"
    end
  end

  describe "#prompt_for_server_ssh_key" do
    it "prompts for the path" do
      generator.should_receive(:ask).and_return("~/.ssh/top_secret_rsa")

      generator.prompt_for_ssh_key

      generator.config.server_ssh_key.should == File.expand_path("~/.ssh/top_secret_rsa")
    end
  end

  describe "#prompt_for_github_key" do
    it "prompts for the path" do
      generator.should_receive(:ask).and_return("~/.ssh/the_matthew_kocher_memorial_key")

      generator.prompt_for_github_key

      generator.config.github_ssh_key.should == File.expand_path("~/.ssh/the_matthew_kocher_memorial_key")
    end
  end
end
