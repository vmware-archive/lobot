require "spec_helper"

describe Lobot::Amazon, :slow => true do
  let(:tempdir) { Dir.mktmpdir }
  let(:amazon) { Lobot::Amazon.new(ENV["EC2_KEY"], ENV["EC2_SECRET"]) }
  let(:fog) { amazon.send(:fog) }

  describe "#create_security_group" do
    context "when there is no existing security group" do
      it "creates a security group" do
        amazon.create_security_group("totally_not_a_honeypot")
        amazon.security_groups.map(&:name).should include "totally_not_a_honeypot"
      end
    end

    context "when the security group already exists" do
      before { amazon.create_security_group("bart_police") }

      it "does not complain" do
        expect { amazon.create_security_group("bart_police") }.not_to raise_error
      end
    end
  end

  describe "#open_port" do
    before { amazon.create_security_group("bag_of_weasels") }

    let(:group) { amazon.security_groups.get("bag_of_weasels") }

    def includes_port?(permissions, ports)
      permissions.any? { |p| (p["fromPort"]..p["toPort"]).include?(80) }
    end

    it "opens a port for business" do
      group.ip_permissions.should_not include "80"
      amazon.open_port("bag_of_weasels", 80)
      includes_port?(group.reload.ip_permissions, 80).should be_true
    end

    it "takes a bunch of ports" do
      amazon.open_port("bag_of_weasels", 22, 443)
      includes_port?(group.reload.ip_permissions, 22).should be_true
      includes_port?(group.reload.ip_permissions, 443).should be_true
    end
  end

  describe "#add_key_pair" do
    let(:key_pair_path) { "#{tempdir}/supernuts" }

    before do
      system "ssh-keygen -q -f #{key_pair_path} -P ''"
      amazon.delete_key_pair("is_supernuts")
    end

    it "uploads the key" do
      amazon.add_key_pair("is_supernuts", "#{key_pair_path}.pub")
      amazon.key_pairs.map(&:name).should include "is_supernuts"
    end

    context "when the key is already there" do
      before { amazon.add_key_pair("is_supernuts", "#{key_pair_path}.pub") }

      it "doesn't reupload" do
        expect do
          amazon.add_key_pair("is_supernuts", "#{key_pair_path}.pub")
        end.not_to raise_error
      end
    end
  end

  describe "things which launch instances" do
    let(:key_pair_path) { "#{tempdir}/cookie" }

    before do
      system "ssh-keygen -q -f #{key_pair_path} -P ''"
      amazon.add_key_pair("eating_my_cookie", "#{key_pair_path}.pub")
      amazon.create_security_group("chump_of_change")
    end

    let(:freshly_launched_server) { amazon.launch_server("eating_my_cookie", "chump_of_change", "t1.micro") }

    describe "#launch_instance" do
      it "creates an instance" do
        expect { freshly_launched_server }.to change { amazon.servers.reload.count }.by(1)

        freshly_launched_server.availability_zone.should == "us-east-1a"
        freshly_launched_server.flavor_id.should == "t1.micro"
        freshly_launched_server.tags.should == {"lobot"=>Lobot::VERSION, "Name"=>"Lobot"}
        freshly_launched_server.key_name.should == "eating_my_cookie"
        freshly_launched_server.groups.should == ["chump_of_change"]
        freshly_launched_server.public_ip_address.should == amazon.elastic_ip_address.public_ip

        freshly_launched_server.destroy
        amazon.elastic_ip_address.destroy
      end
    end

    describe "#destroy_ec2" do
      let!(:server_ip) { freshly_launched_server.public_ip_address }

      it "stops all the instances" do
        expect do
          amazon.destroy_ec2
        end.to change { freshly_launched_server.reload.state }.from("running")
        fog.addresses.get(server_ip).should_not be
      end
    end
  end

  describe "#elastic_ip_address" do
    it "allocates an ip address" do
      expect { amazon.elastic_ip_address }.to change { fog.addresses.reload.count }.by(1)
      amazon.elastic_ip_address.public_ip.should =~ /\d+\.\d+\.\d+\.\d+/
      amazon.elastic_ip_address.destroy
    end
  end

  describe "#release_elastic_ip" do
    let!(:elastic_ip) { amazon.elastic_ip_address }

    it "releases the ip" do
      expect do
        amazon.release_elastic_ip(elastic_ip.public_ip)
      end.to change { fog.addresses.reload.count }.by(-1)
    end
  end
end
