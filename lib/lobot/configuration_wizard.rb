require "thor"
require "godot"

module Lobot
  class ConfigurationWizard < ::Thor
    DESCRIPTION_TEXT = "Sets up lobot through a series of questions"

    default_task :setup

    desc "setup", DESCRIPTION_TEXT
    def setup
      return unless yes?("It looks like you're trying to set up a CI Box. Can I help? (Yes/No)")
      prompt_for_aws
      prompt_for_basic_auth
      prompt_for_ssh_key
      prompt_for_github_key
      prompt_for_build
      config.save
      prompt_for_amazon_create
      provision_server
    end

    no_tasks do
      def ask_with_default(statement, default)
        question = default ? "#{statement} [#{default}]:" : "#{statement}:"
        answer = ask(question) || ""
        answer.empty? ? default : answer
      end

      def prompt_for_aws
        say("For your AWS Access Key and Secret, see https://aws-portal.amazon.com/gp/aws/developer/account/index.html?ie=UTF8&action=access-key")
        config.aws_key = ask_with_default("Your AWS key", config.aws_key)
        config.aws_secret = ask_with_default("Your AWS secret key", config.aws_secret)
      end

      def prompt_for_basic_auth
        config.node_attributes.nginx.basic_auth_user = ask_with_default("Your CI username", config.node_attributes.nginx.basic_auth_user)
        config.node_attributes.nginx.basic_auth_password = ask_with_default("Your CI password", config.node_attributes.nginx.basic_auth_password)
      end

      def prompt_for_ssh_key
        config.server_ssh_key = ask_with_default("Path to CI server SSH key", config.server_ssh_key_path)
      end

      def prompt_for_github_key
        config.github_ssh_key = ask_with_default("Path to a SSH key authorized to clone the repository", config.github_ssh_key_path)
      end

      def prompt_for_build
        build = config.node_attributes.jenkins.builds.first || {}
        config.node_attributes.jenkins.builds[0] = {
          "name" => ask_with_default("What would you like to name your build?", build["name"]),
          "repository" => ask_with_default("What is the address of your git repository?", build["repository"]),
          "command" => ask_with_default("What command should be run during the build?", build["command"]),
          "branch" => "master"
        }
      end

      def prompt_for_amazon_create
        return unless config.master.nil?
        cli.create if yes?("Would you like to start an instance on AWS?")
        Godot.new(config.reload.master, 22, :timeout => 180).wait!
        say("Instance launched.")
      end

      def provision_server
        return if config.reload.master.nil?
        say <<-OOTSTRAP.gsub(/^\s*/, '')
          To bootstrap an instance, we upload the bootstrap_server.sh script. This
          script installs the packages necessary to compile ruby, installs RVM, and
          adds the ubuntu user to the rvm group.

          Bootstrapping the instance now.
        OOTSTRAP
        cli.bootstrap

        say <<-HEF.gsub(/^\s*/, '')
          Next we'll go ahead and chef the instance.  This involves uploading the chef
          recipes, and invoking chef-solo via soloist.  Chef will then converge, using
          the pivotal_ci cookbook and the travis-ci ci_environment cookbooks.

          Running chef-solo now.
        HEF
        cli.chef
      end

      def config
        @config ||= Lobot::Config.from_file(lobot_config_path)
      end
    end

    private
    def lobot_config_path
      FileUtils.mkdir_p(File.join(Dir.pwd, "config"))
      File.expand_path("config/lobot.yml", Dir.pwd)
    end

    def cli
      Lobot::CLI.new
    end
  end
end
