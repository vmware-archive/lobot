require 'spec_helper'

describe Lobot::ConfigurationWizard do
  let(:working_path) { Dir.mktmpdir }
  let(:cli) { double(:cli).as_null_object }
  let(:wizard) { Lobot::ConfigurationWizard.new }

  before { wizard.stub(:cli => cli) }

  around do |example|
    Dir.chdir(working_path) { example.run }
  end

  describe "#config" do
    it "creates the config directory if it does not exist" do
      expect {
        wizard.config
      }.to change {
        File.directory?(File.join(working_path, "config"))
      }.from(false).to(true)
    end

    it "uses the values in your existing lobot.yml" do
      FileUtils.mkdir_p "config"
      config = Lobot::Config.new(:path => "config/lobot.yml")
      config.ssh_port = 2222
      config.save

      wizard.config.ssh_port.should == 2222
    end

    it "saves off the config to config/lobot.yml" do
      expect {
        wizard.config.save
      }.to change {
        File.exists?(File.join(working_path, "config", "lobot.yml"))
      }.from(false).to(true)
    end
  end

  describe "#ask_with_default" do
    it "makes you feel like you need a shower" do
      wizard.should_receive(:ask).with("Your ID [1]:")
      wizard.ask_with_default("Your ID", "1")
    end

    it "defaults to the default value" do
      wizard.should_receive(:ask).and_return("")
      wizard.ask_with_default("Who is buried in Grant's Tomb", "Grant").should == "Grant"
    end

    it "uses the provided answer" do
      wizard.should_receive(:ask).and_return("robert e lee's left nipple")
      wizard.ask_with_default("Who is buried in Grant's Tomb", "Grant").should_not == "Grant"
    end

    it "does not display a nil default" do
      wizard.should_receive(:ask).with("Monkey mustache:")
      wizard.ask_with_default("Monkey mustache", nil)
    end
  end

  describe "#setup" do
    before do
      wizard.stub(:ask => "totally-valid-value", :yes? => true, :say => nil)
      wizard.config.stub(:save)
    end

    it "Says that you're trying to set up a ci box" do
      question = "It looks like you're trying to set up a CI Box. Can I help? (Yes/No)"
      wizard.should_receive(:yes?).with(question)
      wizard.setup
    end

    it "prompts for aws credentials" do
      wizard.should_receive(:prompt_for_aws)
      wizard.setup
    end

    it "prompts for nginx basic auth credentials" do
      wizard.should_receive(:prompt_for_basic_auth)
      wizard.setup
    end

    it "prompts for an ssh key" do
      wizard.should_receive(:prompt_for_ssh_key)
      wizard.setup
    end

    it "prompts for a github key" do
      wizard.should_receive(:prompt_for_github_key)
      wizard.setup
    end

    it "prompts for a build" do
      wizard.should_receive(:prompt_for_build)
      wizard.setup
    end

    it "confirms the entered configuration values" do
      reloaded_config = double("reloaded_config")
      wizard.config.should_receive(:reload).and_return(reloaded_config)
      reloaded_config.should_receive(:display)
      wizard.stub(:user_wants_to_create_instance?).and_return(false)

      wizard.setup
    end

    it "saves the config" do
      wizard.config.should_receive(:save)
      wizard.setup
    end

    it "prompts to start an instance on amazon" do
      wizard.should_receive(:user_wants_to_create_instance?)
      wizard.setup
    end

    context 'when the user wants to create an instance' do
      before do
        wizard.stub(:user_wants_to_create_instance?).and_return(true)
      end

      it "creates the instance then provisions the server" do
        wizard.should_receive(:create_instance).ordered
        wizard.should_receive(:provision_server).ordered
        wizard.setup
      end
    end

    context 'when the user does not want to create an instance' do
      before do
        wizard.stub(:user_wants_to_create_instance?).and_return(false)
      end

      it "does not creates an instance nor provision anything" do
        wizard.should_not_receive(:create_instance)
        wizard.should_not_receive(:provision_server)
        wizard.setup
      end
    end
  end

  describe "#prompt_for_aws" do
    before { wizard.stub(:say) }

    it "reads in the key and secret" do
      wizard.should_receive(:ask).and_return("aws-key")
      wizard.should_receive(:ask).and_return("aws-secret-key")

      wizard.prompt_for_aws

      wizard.config.aws_key.should == "aws-key"
      wizard.config.aws_secret.should == "aws-secret-key"
    end
  end

  describe "#prompt_for_basic_auth" do
    it "prompts for the username and password" do
      wizard.should_receive(:ask).and_return("admin")
      wizard.should_receive(:ask).and_return("password")

      wizard.prompt_for_basic_auth

      wizard.config.node_attributes.nginx.basic_auth_user.should == "admin"
      wizard.config.node_attributes.nginx.basic_auth_password.should == "password"
    end
  end

  describe "#prompt_for_ssh_key" do
    it "prompts for the path" do
      wizard.should_receive(:ask).and_return("~/.ssh/top_secret_rsa")

      wizard.prompt_for_ssh_key

      wizard.config.server_ssh_key_path.should == File.expand_path("~/.ssh/top_secret_rsa")
    end
  end

  describe "#prompt_for_github_key" do
    it "prompts for the path" do
      wizard.should_receive(:ask).and_return("~/.ssh/the_matthew_kocher_memorial_key")

      wizard.prompt_for_github_key

      wizard.config.github_ssh_key_path.should == File.expand_path("~/.ssh/the_matthew_kocher_memorial_key")
    end
  end

  describe "#prompt_for_build" do
    def first_jenkins_build
      wizard.config.node_attributes.jenkins.builds.first
    end

    before do
      wizard.stub(:ask)
      wizard.stub(:this_is_a_rails_project?).and_return(false)
    end

    context "when there are no builds" do
      it "asks you for the build name" do
        wizard.should_receive(:ask).and_return("fancy-build")
        wizard.prompt_for_build
        first_jenkins_build["name"].should == "fancy-build"
      end

      it "asks you for the git repository" do
        wizard.should_receive(:ask)
        wizard.should_receive(:ask).and_return("Fort-Knox")
        wizard.prompt_for_build
        first_jenkins_build["repository"].should == "Fort-Knox"
      end

      it "always builds the master branch" do
        wizard.prompt_for_build
        first_jenkins_build["branch"].should == "master"
      end

      context "when the project is a rails project" do
        before do
          wizard.should_receive(:this_is_a_rails_project?).and_return(true)
        end

        it "asks whether you would like to use the sample rails build script" do
          wizard.should_receive(:yes?)
          wizard.prompt_for_build
        end

        context "and when the user wants to use the sample build script" do
          before do
            wizard.stub(:yes?).and_return(true)
          end

          it 'generates a ci_build.sh file' do
            wizard.should_receive(:copy_file)
            wizard.prompt_for_build
          end
        end
      end

      context "when it is not a rails project or the user does not want the sample build script" do
        it "asks you for the build command" do
          wizard.should_receive(:ask).twice
          wizard.should_receive(:ask).and_return("unit-tested-bash")
          wizard.prompt_for_build
          first_jenkins_build["command"].should == "unit-tested-bash"
        end
      end
    end

    context "when there are builds" do
      before do
        wizard.stub(:ask_with_default)

        wizard.config.node_attributes.jenkins.builds << {
          "name" => "first-post",
          "repository" => "what",
          "command" => "hot-grits",
          "branch" => "oak"
        }

        wizard.config.node_attributes.jenkins.builds << {
          "name" => "grails",
          "repository" => "huh",
          "command" => "colored-greens",
          "branch" => "larch"
        }
      end

      it "prompts for the name using the first build as a default" do
        wizard.should_receive(:ask_with_default).with(anything, "first-post")
        wizard.prompt_for_build
      end

      it "prompts for the repository using the first build as a default" do
        wizard.should_receive(:ask_with_default)
        wizard.should_receive(:ask_with_default).with(anything, "what")
        wizard.prompt_for_build
      end

      it "prompts for the repository using the first build as a default" do
        wizard.should_receive(:ask_with_default).twice
        wizard.should_receive(:ask_with_default).with(anything, "hot-grits")
        wizard.prompt_for_build
      end
    end
  end

  describe "#user_wants_to_create_instance?" do
    before { wizard.stub(:yes? => true, :say => nil) }

    context "when there is not an instance in the config" do
      it "asks to start an amazon instance" do
        wizard.should_receive(:yes?).and_return(:yep)
        wizard.user_wants_to_create_instance?.should == :yep
      end
    end

    context "when there is an instance in the config" do
      before { wizard.config.master = "1.123.123.1" }

      it "does not ask to start an instance" do
        wizard.should_not_receive(:yes?)
        wizard.user_wants_to_create_instance?.should_not be
      end
    end
  end

  describe "#create_instance" do
    it "calls create on CLI" do
      cli.should_receive(:create)
      wizard.create_instance
    end
  end

  describe "#provision_server" do
    before { wizard.stub(:say) }

    context "when there is no instance in the config" do
      it "does not bootstrap the instance" do
        cli.should_not_receive(:bootstrap)
        wizard.provision_server
      end

      it "does not run chef" do
        cli.should_not_receive(:chef)
        wizard.provision_server
      end
    end

    context "when an instance exists" do
      before do
        wizard.config
        wizard.config.master = "1.2.3.4"
        wizard.config.save
        wizard.config.master = nil
      end

      it "bootstraps the instance" do
        cli.should_receive(:bootstrap)
        wizard.provision_server
      end

      it "runs chef" do
        cli.should_receive(:chef)
        wizard.provision_server
      end
    end
  end
end
