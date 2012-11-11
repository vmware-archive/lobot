require 'net/ssh'
require 'shellwords'
module Lobot
  class Sobo
    class CommandFailed < StandardError; end;

    attr_reader :ip, :key, :user
    attr_writer :timeout

    def initialize(ip, key, user='ubuntu')
      @ip = ip
      @key = key
      @user = user
    end

    def timeout
      @timeout || 10000
    end

    def system(command)
      ssh_popen4!(command)[2]
    end

    def system!(command)
      result = ssh_popen4!(command)
      raise(CommandFailed, "Failed: #{command}\n#{result[0]}\n\n#{result[1]}") unless result[2] == 0
    end

    def backtick(command)
      ssh_popen4!(command)[0]
    end

    def ssh_popen4!(command)
      ssh = Net::SSH.start(ip, user, :keys => [key], :timeout => timeout)
      stdout_data = ""
      stderr_data = ""
      exit_code = nil
      exit_signal = nil
      ssh.open_channel do |channel|
        channel.exec("/bin/bash -lc #{Shellwords.escape(command)}") do |ch, success|
          unless success
            raise "FAILED: couldn't execute command (ssh.channel.exec)"
          end
          channel.on_data do |ch,data|
            stdout_data+=data
          end

          channel.on_extended_data do |ch,type,data|
            stderr_data+=data
          end

          channel.on_request("exit-status") do |ch,data|
            exit_code = data.read_long
          end

          channel.on_request("exit-signal") do |ch, data|
            exit_signal = data.read_long
          end
        end
      end
      ssh.loop
      [stdout_data, stderr_data, exit_code, exit_signal]
    end

    def upload(from, to, opts = "--exclude .git")
      Kernel.system("ssh-agent > /dev/null")
      Kernel.system("ssh-add #{key} > /dev/null")
      Kernel.system("rsync -avz --delete #{from} #{user}@#{ip}:#{to} #{opts}")
    end
  end
end