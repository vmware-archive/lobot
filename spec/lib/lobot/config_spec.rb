require "spec_helper"

describe Lobot::Config do
  describe "with a file" do
    let(:config_contents) { {ssh_port: 42} }
    let(:tempfile) do
      t = Tempfile.new('lobot-config')
      t.write YAML.dump(config_contents)
      t.close
      t
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
      let(:node_attributes) { {"radiator" => {"busted" => "hella"}} }
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

        it "adds in basic_auth_user into node_attributes" do
          config.soloistrc['node_attributes']['nginx']['basic_auth_user'].should == "ci"
        end

        it "has node_attributes" do
          config.soloistrc['node_attributes']['radiator']['busted'].should == "hella"
        end
      end
    end
  end

  describe "defaults" do
    its(:ssh_port) { should == 22 }
    its(:master) { should == "127.0.0.1" }
    its(:server_ssh_key) { should =~ /id_rsa$/ }
    its(:basic_auth_user) { should == "ci" }
    its(:recipes) { should == ["pivotal_ci::jenkins", "pivotal_ci::limited_travis_ci_environment", "pivotal_ci"] }
    its(:node_attributes) { should == {:travis_build_environment => {:user => "jenkins", :group => "nogroup", :home => "/var/lib/jenkins"}} }
    its(:cookbook_paths) { should == ['./chef/cookbooks/', './chef/travis-cookbooks/ci_environment'] }

    describe "#soloistrc" do
      it "defaults to recipes and nginx basic auth" do
        subject.soloistrc.should == {
          "recipes" => subject.recipes,
          "cookbook_paths" => subject.cookbook_paths,
          "node_attributes" => {
            "nginx" => {
              "basic_auth_user" => "ci",
              "basic_auth_password" => nil
            },
            "travis_build_environment" => {
              "user" => "jenkins",
              "group" => "nogroup",
              "home" => "/var/lib/jenkins"
            }
          }
        }
      end
    end
  end
end