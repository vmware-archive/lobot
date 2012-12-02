require "spec_helper"

describe Lobot::Wizard do
  let(:lobot_config) { Lobot::Config.new }

  subject { Lobot::Wizard.new(lobot_config) }

  describe "#prompt_for_build_name" do
    it "accepts the name of the build" do
      capture { subject.prompt_for_build_name }
    end
  end
end
