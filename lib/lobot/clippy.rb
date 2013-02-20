require "thor"

module Lobot
  class Clippy < ::Thor
    default_task :clippy

    desc "clippy", "One of the worst software design blunders in the annals of computing"
    def clippy
      return unless yes?("It looks like you're trying to set up a CI Box. Can I help?")
      prompt_for_aws
      prompt_for_basic_auth
      prompt_for_ssh_key
      prompt_for_github_key
      config.save
    end

    no_tasks do
      def ask_with_default(statement, default)
        question = default ? "#{statement} [#{default}]:" : "#{statement}:"
        answer = ask(question) || ""
        answer.empty? ? default : answer
      end

      def prompt_for_aws
        config.aws_key = ask_with_default("Your AWS key", config.aws_key)
        config.aws_secret = ask_with_default("Your AWS secret key", config.aws_secret)
      end

      def prompt_for_basic_auth
        config.node_attributes.nginx.basic_auth_user = ask_with_default("Your CI username", config.node_attributes.nginx.basic_auth_user)
        config.node_attributes.nginx.basic_auth_password = ask_with_default("Your CI password", config.node_attributes.nginx.basic_auth_password)
      end

      def prompt_for_ssh_key
        config.server_ssh_key = ask_with_default("Path to CI server SSH key", config.server_ssh_key)
      end

      def prompt_for_github_key
        config.github_ssh_key = ask_with_default("Path to a SSH key authorized to clone the repository", config.github_ssh_key)
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
  end
end
