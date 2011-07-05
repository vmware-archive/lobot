require 'spec_helper'

describe Lobot::InstallGenerator do
  include GeneratorSpec::TestCase
  destination File.expand_path("../tmp", __FILE__)
  # arguments %w(something)

  before(:each) do
    prepare_destination
    run_generator
  end
  
  it "creates ci.yml" do
    assert_file "config/ci.yml", /app_name/
  end
  
  it "creates ci.rake" do
    assert_file "lib/tasks/ci.rake", /namespace :ci do/
  end
  
  it "create bootstrap_server.sh" do
    assert_file "script/bootstrap_server.sh", /bin\/bash/
  end
  
  context "Capfile exists" do
    it "appends a load path to the Capfile" do
      prepare_destination
      system("echo 'line 2' > #{destination_root}/Capfile")
      run_generator
      assert_file "Capfile", "load 'config/capistrano/ci'\nline 2\n"
    end
    
  end
  
  context "Capfile doesn't exist" do
    it "create a Capfile" do
      assert_file "Capfile", /load 'config\/capistrano\/ci'/
    end
    
    it "give you the capify (default) capfile, but commented out" do
      assert_file "Capfile", /# load 'deploy'/
    end
  end
  
  it "creates config/deploy/ci.rb" do
    assert_file "config/deploy/ci.rb", /role :ci, ci_server/
  end

  it "creates config/capistrano/ci.rb" do
    assert_file "config/capistrano/ci.rb", /task :ci_setup do/
  end
  
  it "creates soloistrc" do
    assert_file "soloistrc", /cookbook_paths/
  end
  
  it "creates the chef directory" do
    destination_root.should have_structure do
      directory "chef" do
        directory "cookbooks" do
          directory "pivotal_ci"
          directory "pivotal_server"
        end
      end
    end
  end
  
end
