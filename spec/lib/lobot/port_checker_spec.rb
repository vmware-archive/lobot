require "spec_helper"

describe Lobot::PortChecker do
  describe ".is_listening?" do
    it "returns true when a port is listening" do
      Lobot::PortChecker.is_listening?("127.0.0.1", 22, 1).should be
    end

    it "returns false when a port is unavailable" do
      Lobot::PortChecker.is_listening?("127.0.0.1", 666, 1).should_not be
    end
  end
end
