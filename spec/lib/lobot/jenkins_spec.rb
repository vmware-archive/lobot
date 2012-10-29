require "spec_helper"

describe Lobot::Jenkins do
  let(:lobot_config) { Lobot::Config.new }
  let(:jenkins) { Lobot::Jenkins.new(lobot_config) }

  describe "#jobs" do
    before { jenkins.stub(:api_json).and_return({"jobs" => [{"name" => "meat"}]}) }

    it "returns the jobs on a running instance" do
      jenkins.jobs.first.name.should == "meat"
    end
  end
end