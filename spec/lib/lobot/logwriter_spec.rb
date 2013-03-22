require 'spec_helper'

describe Lobot::Logwriter do
  let(:file_name) { 'bootstrap.log' }

  context 'when writing to a file' do
    describe '#<<' do
      let(:logwriter) { Lobot::Logwriter.new(file_name) }
      let(:file_double) { StringIO.new }

      before do
        File.stub(:open).with(file_name, 'w').and_return(file_double)
      end

      it 'streams to the file' do
        logwriter << 'output'
        file_double.string.should == 'output'
      end

      it 'flushes to the file' do
        file_double.should_receive(:flush)
        logwriter << 'output'
      end
    end

    context 'when verbose' do
      it 'streams to stdout in addition to the file' do
        File.stub(:open).with(file_name, 'w').and_return(double.as_null_object)

        STDOUT.should_receive('<<').with('output')

        logwriter = Lobot::Logwriter.new(file_name, verbose: true)
        logwriter << 'output'
      end
    end
  end

  context 'when no file is given' do
    it 'raises an exception' do
      expect {
        Lobot::Logwriter.new
      }.to raise_exception
    end
  end
end