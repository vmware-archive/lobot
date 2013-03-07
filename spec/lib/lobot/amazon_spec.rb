require "spec_helper"

describe Lobot::Amazon, :slow do
  subject(:amazon) { Lobot::Amazon.new(ENV["EC2_KEY"], ENV["EC2_SECRET"]) }
  let(:tempdir) { Dir.mktmpdir }
  let(:fog) { amazon.send(:fog) }

  before { pending "Missing EC2 Credentials" unless ENV.has_key?("EC2_KEY") && ENV.has_key?("EC2_SECRET") }
  after { cleanup_temporary_ssh_keys }

  describe "#create_security_group" do
    context "when there is no existing security group" do
      let(:security_group) { "totally_not_a_honeypot" }

      after { amazon.fog_security_groups.get(security_group).destroy }

      it "creates a security group" do
        amazon.create_security_group(security_group)
        amazon.fog_security_groups.map(&:name).should include security_group
      end
    end

    context "when the security group already exists" do
      let(:security_group) { "bart_police" }

      before { amazon.create_security_group(security_group) }
      after { amazon.fog_security_groups.get(security_group).destroy }

      it "does not complain" do
        expect { amazon.create_security_group(security_group) }.not_to raise_error
      end
    end
  end

  describe "#open_port" do
    let(:security_group) { "bag_of_weasels" }
    let(:group) { amazon.fog_security_groups.get(security_group) }

    before { amazon.create_security_group(security_group) }
    after { amazon.fog_security_groups.get(security_group).destroy }

    def includes_port?(permissions, port)
      permissions.any? { |p| (p["fromPort"]..p["toPort"]).include?(port) }
    end

    it "opens a port for business" do
      group.ip_permissions.should_not include "80"
      amazon.open_port(security_group, 80)
      includes_port?(group.reload.ip_permissions, 80).should be_true
    end

    it "takes a bunch of ports" do
      amazon.open_port(security_group, 22, 443)
      includes_port?(group.reload.ip_permissions, 22).should be_true
      includes_port?(group.reload.ip_permissions, 443).should be_true
    end
  end

  describe "#add_key_pair" do
    let(:key_pair_pub) { File.read(File.expand_path(key_pair_path + ".pub"))}
    let(:key_pair_name) { "is_supernuts" }

    before { amazon.delete_key_pair(key_pair_name) }
    after { amazon.delete_key_pair(key_pair_name) }

    it "uploads the key" do
      amazon.add_key_pair(key_pair_name, key_pair_pub)
      amazon.fog_key_pairs.map(&:name).should include key_pair_name
    end

    context "when the key is already there" do
      before { amazon.add_key_pair(key_pair_name, key_pair_pub) }

      it "doesn't reupload" do
        expect do
          amazon.add_key_pair(key_pair_name, key_pair_pub)
        end.not_to raise_error
      end
    end
  end

  describe "things which launch instances" do
    let(:key_pair_name) { "eating_my_cookie" }
    let(:security_group) { "chump_of_change" }
    let(:key_pair_pub) { File.read(File.expand_path(key_pair_path + ".pub"))}
    let(:freshly_launched_server) { amazon.launch_server(key_pair_name, security_group, "t1.micro") }

    before do
      amazon.delete_key_pair(key_pair_name)
      amazon.add_key_pair(key_pair_name, key_pair_pub)
      amazon.create_security_group(security_group)
    end

    after do
      freshly_launched_server.destroy
      amazon.delete_key_pair(key_pair_name)
      # Make a best effort attempt to clean up after the tests have completed
      # EC2 does not always reap these resources fast enough for our tests, we could wait, but why bother?
      amazon.elastic_ip_address.destroy rescue nil
      amazon.fog_security_groups.get(security_group).destroy rescue nil
    end

    describe "#launch_instance" do
      it "creates an instance" do
        expect { freshly_launched_server }.to change { amazon.fog_servers.reload.count }.by(1)

        freshly_launched_server.availability_zone.should =~ /us-east-1[abcd]/
        freshly_launched_server.flavor_id.should == "t1.micro"
        freshly_launched_server.tags.should == {"lobot"=>Lobot::VERSION, "Name"=>"Lobot"}
        freshly_launched_server.key_name.should == key_pair_name
        freshly_launched_server.groups.should == [security_group]
        freshly_launched_server.public_ip_address.should == amazon.elastic_ip_address.public_ip
      end
    end

    describe "#destroy_ec2" do
      let!(:server_ip) { freshly_launched_server.public_ip_address }

      context 'with a confirmation Proc that returns true' do
        let(:proc) { ->(_) { true } }

        it "stops all the instances" do
          # TODO: This probably needs some more testing with n > 1 instances
          expect do
            amazon.destroy_ec2(proc, :all)
          end.to change { freshly_launched_server.reload.state }.from("running")
          fog.addresses.get(server_ip).should_not be
        end

        it "stops the named instances" do
          expect do
            amazon.destroy_ec2(proc, freshly_launched_server.id)
          end.to change { freshly_launched_server.reload.state }.from("running")
          fog.addresses.get(server_ip).should_not be
        end
      end

      context 'with a confirmation Proc that returns false' do
        let(:proc) { ->(_) { false } }

        it 'does not stop instances' do
          expect do
            amazon.destroy_ec2(proc, :all)
          end.to_not change { freshly_launched_server.reload.state }.from("running")
          fog.addresses.get(server_ip).should be
        end
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
