require "thor"

module Lobot
  class ConfigurationWizard < ::Thor
    include Actions

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
      say config.reload.display
      if user_wants_to_create_instance?
        create_instance
        provision_server
        say("Setup complete! You may now access your new CI server at #{config.reload.jenkins_url}")
      end
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

        if this_is_a_rails_project? && prompt_for_default_rails_script
          build_command = Proc.new { "script/ci_build.sh" }
          copy_file('default_rails_build_script.sh', 'script/ci_build.sh')
        else
          build_command = Proc.new { ask_with_default("What command should be run during the build?", build["command"]) }
        end

        config.node_attributes.jenkins.builds[0] = {
          "name" => ask_with_default("What would you like to name your build?", build["name"]),
          "repository" => ask_with_default("What is the address of your git repository?", build["repository"]),
          "command" => build_command.call,
          "branch" => "master"
        }
      end

      def user_wants_to_create_instance?
        return unless config.master.nil?
        yes?("Would you like to start an instance on AWS now? (Yes/No)")
      end

      def create_instance
        cli.create
        say("Instance launched.")
      end

      def provision_server
        return if config.reload.master.nil?
        cli.bootstrap
        cli.chef
      end

      def config
        @config ||= Lobot::Config.from_file(lobot_config_path)
      end
    end

    private

    def source_paths
      [File.join(File.expand_path(File.dirname(__FILE__)), "templates")] + super
    end

    def prompt_for_default_rails_script
      return false if File.exists?('script/ci_build.sh')
      yes?("It looks like this is a Rails project.  Would you like to use the default Rails build script? (Yes/No)")
    end

    def this_is_a_rails_project?
      File.exists?('script/rails')
    end

    def lobot_config_path
      FileUtils.mkdir_p(File.join(Dir.pwd, "config"))
      File.expand_path("config/lobot.yml", Dir.pwd)
    end

    def cli
      Lobot::CLI.new
    end
  end
end
