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

    def servers
      fog.servers
    end

    def elastic_ip_address
      @elastic_ip_address ||= fog.addresses.create
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
      key_pairs.create(:name => key_pair_name, :public_key => File.read("#{key_path}")) unless key_pairs.get(key_pair_name)
    end

    def launch_server(key_pair_name, security_group_name, instance_type = "m1.medium")
      servers.create(
        :image_id => "ami-a29943cb",
        :flavor_id => instance_type,
        :availability_zone => "us-east-1b",
        :tags => {"Name" => "Lobot", "lobot" => Lobot::VERSION},
        :key_name => key_pair_name,
        :groups => [security_group_name]
      ).tap do |server|
        server.wait_for { ready? }
        fog.associate_address(server.id, elastic_ip_address.public_ip) # needs to be running
        server.reload
      end
    end

    def destroy_ec2
      servers = fog.servers.select { |s| s.tags.keys.include?("lobot") && s.state == "running" }
      ips = servers.map(&:public_ip_address)
      servers.map(&:destroy)
      ips.each { |ip| release_elastic_ip(ip) }
    end

    def release_elastic_ip(ip)
      fog.addresses.get(ip).destroy if fog.addresses.get(ip)
    end

    private

    def fog
      @fog ||= Fog::Compute.new(
        :provider => "aws",
        :aws_access_key_id => key,
        :aws_secret_access_key => secret
      )
    end
  end
end
