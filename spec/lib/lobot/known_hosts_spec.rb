require "spec_helper"

describe Lobot::KnownHosts do
  let(:known_hosts) { Tempfile.new([".", "known_hosts"]).tap {|f| f.close} }
  let(:key_blob) { "AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==" }
  let(:key) { Net::SSH::Buffer.new(key_blob.unpack("m*").first).read_key }
  let(:ipaddr) {"1.2.3.4"}

  subject { Lobot::KnownHosts.new(known_hosts.path) }

  describe ".key_for", :osx do
    let(:local) { `ssh-keyscan localhost 2> /dev/null`.chomp.split(' ').last }
    let(:local_key) { Net::SSH::Buffer.new(local.unpack("m*").first).read_key }

    it "returns the public key for a local machine" do
      Lobot::KnownHosts.key_for("localhost").to_s.should == local_key.to_s
    end
  end

  context 'with a stubbed key_for' do
    before do
      described_class.stub(:key_for).and_return(key)
    end

    describe "#include?" do
      context "when the known hosts file does not have the host" do
        it "returns false" do
          subject.include?(ipaddr).should_not be
        end
      end

      context "when the known hosts file has the host" do
        before { subject.add(ipaddr) }

        it "returns true" do
          subject.include?(ipaddr).should be
        end
      end
    end

    describe "#add" do
      context "when the known hosts file does not have the host" do
        it "adds the host" do
          expect do
            subject.add(ipaddr)
          end.to change { subject.include?(ipaddr) }
        end
      end

      context "when the known hosts file has the host" do
        before { subject.add(ipaddr) }

        it "does not add the host" do
          expect do
            subject.add(ipaddr)
          end.not_to change { subject.include?(ipaddr) }
        end
      end
    end

    describe "#update" do
      let(:host) { '1.2.3.4' }

      it "removes the host if it exists" do
        subject.add(host)
        subject.should_receive(:remove).with(host)

        subject.update(host)
      end

      it "adds the host" do
        expect do
          subject.update(host)
        end.to change { subject.include?(host) }
      end
    end

    describe "#remove" do
      context "when the known hosts file does not have the host" do
        it "does not raise an exception" do
          expect { subject.remove(ipaddr) }.not_to raise_error
        end
      end

      context "when the known hosts file has the host" do
        before { subject.add(ipaddr) }

        it "removes the host" do
          expect do
            subject.remove(ipaddr)
          end.to change { subject.include?(ipaddr) }
        end

        context "when the known hosts file has other hosts" do
          before do
            subject.add(ipaddr)
            subject.add("4.3.2.1")
          end

          it "removes the host" do
            expect do
              subject.remove(ipaddr)
              subject.include?("4.3.2.1").should be_true
            end.to change { subject.include?(ipaddr) }.to(false)
          end
        end
      end
    end
  end
end