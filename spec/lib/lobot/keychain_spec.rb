require "spec_helper"

describe Lobot::Keychain, :osx do
  subject { Lobot::Keychain.new("/Library/Keychains/System.keychain") }

  describe "#has_key?" do
    it "returns true if a certificate exists" do
      subject.has_key?("Software Signing").should be_true
    end

    it "returns false if a certificate does not exist" do
      subject.has_key?("Jimbo's house of slaughter").should be_false
    end
  end

  describe "#fetch_remote_certificate" do
    it "fetches the certificate" do
      subject.fetch_remote_certificate('https://google.com').should include "BEGIN CERTIFICATE"
    end
  end

  describe "#add_certificate" do
    let(:certificate_path) { File.expand_path("../../../assets/test_cert.crt", __FILE__)}
    let(:certificate) { File.read(certificate_path) }

    it "adds the certificate and trusts it to the utmost" do
      subject.add_certificate(certificate)
      subject.has_key?("lobot_test_certificate").should be_true
    end

    after { system("sudo security delete-certificate -c lobot_test_certificate") }
  end
end
