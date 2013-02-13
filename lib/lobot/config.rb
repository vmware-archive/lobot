require "hashie"

module Lobot
  class Config < Hashie::Dash
    property :path
    property :aws_key
    property :aws_secret
    property :instance_id
    property :master

    property :instance_size, :default => 'c1.medium'
    property :ssh_port, :default => 22
    property :server_ssh_key, :default => "~/.ssh/id_rsa"
    property :github_ssh_key, :default => "~/.ssh/id_rsa"
    property :keypair_name, :default => "lobot"
    property :recipes, :default => ["pivotal_ci::jenkins", "pivotal_ci::limited_travis_ci_environment", "pivotal_ci"]
    property :cookbook_paths, :default => ['./chef/cookbooks/', './chef/travis-cookbooks/ci_environment', './chef/project-cookbooks']
    property :node_attributes, :default => {
      :travis_build_environment => {
        :user => "jenkins",
        :group => "nogroup",
        :home => "/var/lib/jenkins"
      },
      :nginx => {
        :basic_auth_user => "ci",
      },
      :jenkins => {
        :builds => []
      }
    }

    def initialize(attributes = {})
      super
      self["node_attributes"] = Hashie::Mash.new(node_attributes)
    end

    def github_ssh_key
      File.expand_path(self["github_ssh_key"])
    end

    def server_ssh_key
      File.expand_path(self["server_ssh_key"])
    end

    def node_attributes=(attributes)
      self["node_attributes"] = Hashie::Mash.new(attributes)
    end

    def valid?
      errors.empty?
    end

    def errors
      messages = []
      if node_attributes.has_key?("jenkins")
        unless node_attributes.jenkins.has_key?("builds")
          messages << "[:node_attributes][:jenkins][:builds]"
        end
      else
        messages << "[:node_attributes][:jenkins]"
      end
      messages.map{ |path| "your config file does not have a #{path} key" }
    end

    def soloistrc
      {
        "recipes" => recipes,
        "cookbook_paths" => cookbook_paths,
        "node_attributes" => node_attributes.to_hash
      }
    end

    def save
      return self unless path
      File.open(path, "w+") { |file| file.write(YAML.dump(JSON.parse(JSON.dump(to_hash)))) }
      self
    end

    def reload
      self.class.from_file(path)
    end

    def to_hash
      hash = super
      hash.delete("path")
      {
        "ssh_port" => ssh_port,
        "master" => master,
        "server_ssh_key" => server_ssh_key,
        "recipes" => recipes,
        "cookbook_paths" => cookbook_paths,
        "node_attributes" => node_attributes
      }.merge(hash)
    end

    def self.from_file(yaml_file)
      config = {:path => yaml_file}
      config.merge!(read_config(yaml_file)) if File.exists?(yaml_file)
      self.new(config)
    end

    def self.read_config(yaml_file)
      File.open(yaml_file, "r") { |file| YAML.load(file.read) }
    end
  end
end