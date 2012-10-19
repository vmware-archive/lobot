require 'net/ssh/telnet'

module Lobot
  module Sobo
    class Server
      attr_reader :ip, :key

      def initialize(ip, key)
        @ip = ip
        @key = key
      end

      def exec(command)
        Net::SSH.start(ip, "ubuntu", :keys => [key], :timeout => 10000) do |ssh|
          ssh.exec(command)
        end
      end

      def upload(from, to, opts = "--exclude .git")
        system("rsync -avz --delete #{from} ubuntu@#{ip}:#{to} #{opts}")
      end
    end
  end
end