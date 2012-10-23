require "spec_helper"

describe Lobot::Amazon do
  let(:amazon) { Lobot::Amazon.new(ENV["EC2_KEY"], ENV["EC2_SECRET"]) }

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
    let(:tempdir) { Dir.mktmpdir }
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
      it "doesn't reupload" do
        amazon.add_key_pair("is_supernuts", "#{key_pair_path}.pub")
        expect do
          amazon.add_key_pair("is_supernuts", "#{key_pair_path}.pub")
        end.not_to raise_error
      end
    end
  end
end