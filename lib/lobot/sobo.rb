require 'net/ssh/telnet'

module Lobot
  module Sobo
    class Server
      PROMPT_REGEX = /[$%#>] (\z|\e)/n

      attr_reader :ip, :key

      def initialize(ip, key)
        @ip = ip
        @key = key
      end

      def ssh_session
        @ssh_session ||= Net::SSH.start(ip, "ubuntu", keys: [key], timeout: 10000)
      end

      def shell
        @shell ||= Net::SSH::Telnet.new('Session' => ssh_session, 'Prompt' => PROMPT_REGEX, 'Timeout' => 10000)
      end

      def close
        @shell.close if @shell
      end

      def upload(from, to, opts = "--exclude .git")
        system("rsync -avz --delete #{from} ubuntu@#{ip}:#{to} #{opts}")
      end

      def run(*command_fragments)
        command = command_fragments.join(' ')
        result = run_command(command)
        raise "Command failed: #{command}" unless run_command('echo $?', true) == '0'
        result
      end

      def run!(*command_fragments)
        run_command(command_fragments.join(' '))
      end

      def run?(*command_fragments)
        run_command(command_fragments.join(' '))
        run_command("echo $?") == '0'
      end

      def run_silently(*command_fragments)
        command = command_fragments.join(' ')
        result = run_command(command, true)
        raise "Command failed: <silenced>" unless run_command('echo $?', true) == '0'
        result
      end

      def run_command(command, silent=false)
        output = shell.cmd(command) {|data| print data.gsub(/(\r|\r\n|\n\r)+/, "\n") unless silent }
        command_regex = /#{Regexp.escape(command)}/
        output.split("\n").reject {|l| l.match(command_regex) || l.match(PROMPT_REGEX)}.join("\n")
      end
    end
  end
end