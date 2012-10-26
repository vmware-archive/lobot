require "hashie"

module Lobot
  class Config < Hashie::Mash
    def ssh_port
      super || 22
    end

    def master
      super || "127.0.0.1"
    end

    def server_ssh_key
      super || File.expand_path("~/.ssh/id_rsa")
    end

    def basic_auth_user
      super || "ci"
    end

    def recipes
      super || ["pivotal_ci::jenkins", "pivotal_ci::limited_travis_ci_environment", "pivotal_ci"]
    end

    def node_attributes
      super || {
        travis_build_environment: {
          user: "jenkins",
          group: "nogroup",
          home: "/var/lib/jenkins"
        }
      }
    end

    def cookbook_paths
      super || ['./chef/cookbooks/', './chef/travis-cookbooks/ci_environment']
    end

    def soloistrc
      Hashie::Hash.new.merge(
        "recipes" => recipes,
        "cookbook_paths" => cookbook_paths,
        "node_attributes" => {
          "nginx" => {
            "basic_auth_user" => basic_auth_user,
            "basic_auth_password" => basic_auth_password
          }
        }.merge(node_attributes)
      ).as_json
    end

    def save
      return self unless path
      File.open(path, "w+") { |file| file.write(YAML.dump(to_hash)) }
      self
    end

    def to_hash
      hash = super
      hash.delete("path")
      {
        "ssh_port" => ssh_port,
        "master" => master,
        "server_ssh_key" => server_ssh_key,
        "basic_auth_user" => basic_auth_user,
        "basic_auth_password" => basic_auth_password,
        "recipes" => recipes
      }.merge(hash)
    end

    def self.from_file(yaml_file)
      config = read_config(yaml_file)
      self.new(config.merge(path: yaml_file))
    end

    def self.read_config(yaml_file)
      config = nil
      File.open(yaml_file, "r") { |file| config = YAML.load(file.read) }
      config
    end
  end
end