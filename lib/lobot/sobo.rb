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

    def system(command, options = {})
      ssh_popen4!(command, options)[2]
    end

    def system!(command, options = {})
      result = ssh_popen4!(command, options)
      raise(CommandFailed, "Failed: #{command}\n#{result[0]}\n\n#{result[1]}") unless result[2] == 0
    end

    def backtick(command)
      results = ssh_popen4!(command, io: BlackHoleObject.new)
      puts %Q|===>results: #{results.inspect}|
      results[0]
    end

    def ssh_popen4!(command, options = {})
      output_stream = options.fetch(:io)

      ssh = Net::SSH.start(ip, user, :keys => [key], :timeout => timeout, paranoid: false)
      stdout_data = ""
      stderr_data = ""
      exit_code = nil

      ssh.open_channel do |channel|
        channel.exec("/bin/bash -lc #{Shellwords.escape(command)}") do |ch, success|
          unless success
            raise "FAILED: couldn't execute command (ssh.channel.exec)"
          end

          channel.on_data do |ch,data|
            output_stream << data
            stdout_data += data
          end

          channel.on_extended_data do |ch,type,data|
            output_stream << data
            stderr_data += data
          end

          channel.on_request("exit-status") do |ch, data|
            exit_code = data.read_long
          end
        end
      end
      ssh.loop

      output_stream.close
      output_stream.delete if exit_code == 0

      [stdout_data, stderr_data, exit_code]
    end

    def upload(from, to, opts = "--exclude .git")
      Kernel.system(%Q{rsync --rsh="ssh -o 'StrictHostKeyChecking no' -i #{key}" --archive --compress --delete #{from} #{user}@#{ip}:#{to} #{opts}})
    end
  end
end