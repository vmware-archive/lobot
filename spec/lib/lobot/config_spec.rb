require "spec_helper"

describe Lobot::Config do
  describe ".from_file" do
    let(:tempfile) { Tempfile.new('lobot-config') }

    before do
      tempfile.write(YAML.dump({ssh_port: 42}))
      tempfile.close
    end

    after do
      tempfile.unlink
    end

    it "should load from a yaml file" do
      Lobot::Config.from_file(tempfile.path).ssh_port.should == 42
    end
  end

  describe "#ssh_port" do
    let(:config) { Lobot::Config.new(ssh_port: 33) }

    it "should set the ssh_port" do
      config.ssh_port.should == 33
    end
  end

  describe "#master" do
    let(:config) { Lobot::Config.new(master: "127.0.0.2") }

    it "should set master" do
      config.master.should == "127.0.0.2"
    end
  end

  describe "#server_ssh_key" do
    let(:config) { Lobot::Config.new(server_ssh_key: "~/.ssh/gorbypuff") }

    it "should set the server_ssh_key" do
      config.server_ssh_key.should == "~/.ssh/gorbypuff"
    end
  end

  describe "#basic_auth_user" do
    let(:config) { Lobot::Config.new(basic_auth_user: "tenderlove") }

    it "should set the basic_auth_user" do
      config.basic_auth_user.should == "tenderlove"
    end
  end

  describe "#basic_auth_password" do
    let(:config) { Lobot::Config.new(basic_auth_password: "gorbypuff") }

    it "should set the basic_auth_password" do
      config.basic_auth_password.should == "gorbypuff"
    end
  end
end