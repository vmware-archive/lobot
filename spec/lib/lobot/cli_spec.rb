require "spec_helper"

describe Lobot::CLI do
  let(:lobot_config) { Lobot::Config.new }

  before do
    subject.stub(:lobot_config).and_return(lobot_config)
  end

  describe "#ssh" do
    it "starts an ssh session to the lobot host" do
      subject.should_receive(:exec).with("ssh -i #{subject.lobot_config.server_ssh_key} ubuntu@#{subject.lobot_config.master} -p #{subject.lobot_config.ssh_port}")
      subject.ssh
    end
  end

  describe "#open" do
    let(:lobot_config) { Lobot::Config.new(basic_auth_user: "ci", basic_auth_password: "secret") }

    it "opens a web browser with the lobot page" do
      subject.should_receive(:exec).with("open https://#{subject.lobot_config.basic_auth_user}:#{subject.lobot_config.basic_auth_password}@#{subject.lobot_config.master}/")
      subject.open
    end
  end
end
