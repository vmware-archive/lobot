require "spec_helper"

module Lobot
  describe Lobot::Password do
    it "generates a random password" do
      Haddock::Password.should_receive(:generate)
      described_class.generate
    end

    it "returns an empty string if Haddock raises an error" do
      Haddock::Password.should_receive(:generate).and_raise(Haddock::Password::NoWordsError)
      described_class.generate.should == ""
    end
  end
end