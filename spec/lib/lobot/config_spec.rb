require "spec_helper"

describe Lobot::Config do
  let(:default_config) { Lobot::Config.new }

  describe "with a file" do
    let(:config_contents) { {ssh_port: 42} }
    let(:tempfile) do
      Tempfile.new('lobot-config').tap do |file|
        file.write YAML.dump(config_contents)
        file.close
      end
    end

    let(:config) { Lobot::Config.from_file(tempfile.path) }

    describe ".from_file" do
      it "loads from a yaml file" do
        config.ssh_port.should == 42
      end
    end

    describe "#save" do
      it "writes the values to the file" do
        config.ssh_port = 20912
        config.save
        config = Lobot::Config.from_file(tempfile.path)
        config.ssh_port.should == 20912
      end
    end

    describe "soloistrc-specific attributes" do
      let(:recipes) { ["pivotal_workstation::broken_postgres", "pivotal_workstation::janus"] }
      let(:node_attributes) { default_config.node_attributes.merge({"radiator" => {"busted" => "hella"}}) }
      let(:config_contents) { {recipes: recipes, node_attributes: node_attributes} }

      describe "#recipes" do
        it "preserves the recipes in a config file" do
          config.recipes.should == recipes
        end
      end

      describe "#soloistrc" do
        it "has recipes" do
          config.soloistrc['recipes'].should == recipes
        end

        it "has node_attributes" do
          config.soloistrc['node_attributes']['radiator']['busted'].should == "hella"
        end
      end
    end
  end

  describe "defaults" do
    its(:ssh_port) { should == 22 }
    its(:server_ssh_key) { should =~ /id_rsa$/ }
    its(:github_ssh_key) { should =~ /id_rsa$/ }
    its(:recipes) { should == ["pivotal_ci::jenkins", "pivotal_ci::limited_travis_ci_environment", "pivotal_ci"] }
    its(:cookbook_paths) { should == ['./chef/cookbooks/', './chef/travis-cookbooks/ci_environment'] }
    its(:instance_size) { should == 'c1.medium' }

    describe "#node_attributes" do
      it "defaults to overwriting the travis build environment" do
        subject.node_attributes.travis_build_environment.to_hash.should ==  {
          "user" => "jenkins",
          "group" => "nogroup",
          "home" => "/var/lib/jenkins"
        }
      end
    end

    describe "#soloistrc" do
      it "defaults to recipes and nginx basic auth" do
        subject.soloistrc.should == {
          "recipes" => subject.recipes,
          "cookbook_paths" => subject.cookbook_paths,
          "node_attributes" => {
            "nginx" => {
              "basic_auth_user" => "ci",
            },
            "travis_build_environment" => {
              "user" => "jenkins",
              "group" => "nogroup",
              "home" => "/var/lib/jenkins"
            },
            "jenkins" => {
              "builds" => []
            }
          }
        }
      end
    end
  end
end
