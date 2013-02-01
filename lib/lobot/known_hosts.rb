require "net/ssh/known_hosts"

module Lobot
  class KnownHosts
    attr_reader :path

    def self.key_for(host)
      blob = `ssh-keyscan #{host} 2> /dev/null`.chomp.split(' ').last
      Net::SSH::Buffer.new(blob.unpack("m*").first).read_key if blob
    end

    def initialize(path)
      @path = path
    end

    def include?(host)
      ! known_hosts.keys_for(host).empty?
    end

    def add(host, key)
      known_hosts.add(host, key) unless include?(host)
    end

    def remove(host)
      lines = File.readlines(path).delete_if do |line|
        line.strip.split(/\s+/).first.split(/,/).include?(host)
      end
      File.open(path, "w") { |file| lines.each { |line| file.puts(line) } }
    end

    private
    def known_hosts
      Net::SSH::KnownHosts.new(path)
    end
  end
end