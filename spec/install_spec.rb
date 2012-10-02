require 'spec_helper'
require "fileutils"

describe Lobot::InstallGenerator do
  include GeneratorSpec::TestCase

  destination File.expand_path("../tmp", __FILE__)

  before do
    prepare_destination
  end

  after :all do
    FileUtils.rm_rf ::File.expand_path("../tmp", __FILE__)
  end

  context "without requiring input" do
    before do
      before_generator
      run_generator
    end

    let(:before_generator) {}

    context "when no .gitignore exists" do
      it "creates .gitignore" do
        assert_file ".gitignore", /spec\/reports/
      end
    end

    context "when there is already a .gitignore" do
      let(:before_generator) do
        system("touch #{destination_root}/.gitignore")
      end

      it "adds spec/reports to the gitignore" do
        assert_file ".gitignore", /spec\/reports/
      end
    end

    it "creates ci.yml" do
      assert_file "config/ci.yml", /app_name/
    end

    it "creates a ci_build.sh file" do
      assert_file "script/ci_build.sh"
    end

    it "makes ci_build.sh executable" do
      system("test -x #{destination_root}/script/ci_build.sh").should == true
    end

    context "Capfile exists" do
      it "appends a load path to the Capfile" do
        prepare_destination
        system("echo 'line 2' > #{destination_root}/Capfile")
        run_generator
        assert_file "Capfile", "require 'lobot/recipes/ci'\nline 2\n"
      end
    end

    context "Capfile doesn't exist" do
      it "create a Capfile" do
        assert_file "Capfile", /require 'lobot\/recipes\/ci'/
      end

      it "give you the capify (default) capfile, but commented out" do
        assert_file "Capfile", /# load 'deploy'/
      end
    end

    it "creates config/deploy/ci.rb" do
      assert_file "config/deploy/ci.rb", /role :ci, "#\{ci_server\}:#\{ssh_port\}"/
    end

    it "creates soloistrc" do
      assert_file "soloistrc", /cookbook_paths/
    end
  end
end
