require "fog"

module Lobot
  class Amazon
    PORTS_TO_OPEN = [22, 443] + (9000...9010).to_a

    attr_reader :key, :secret

    def initialize(key, secret)
      @key = key
      @secret = secret
    end

    def security_groups
      fog.security_groups
    end

    def key_pairs
      fog.key_pairs
    end

    def create_security_group(group_name)
      unless security_groups.get(group_name)
        security_groups.create(:name => group_name, :description => 'Lobot-generated group')
      end
    end

    def open_port(group_name, *ports)
      group = security_groups.get(group_name)
      ports.each do |port|
        unless group.ip_permissions.any? { |p| (p["fromPort"]..p["toPort"]).include?(port) }
          group.authorize_port_range(port..port)
        end
      end
    end

    def delete_key_pair(key_pair_name)
      key_pairs.new(:name => key_pair_name).destroy
    end

    def add_key_pair(key_pair_name, key_path)
      unless key_pairs.get(key_pair_name)
        key_pairs.create(:name => key_pair_name, :public_key => File.read("#{key_path}"))
      end
    end

    private

    def fog
      @fog ||= Fog::Compute.new(
        :provider => 'aws',
        :aws_access_key_id => key,
        :aws_secret_access_key => secret
      )
    end
  end
end