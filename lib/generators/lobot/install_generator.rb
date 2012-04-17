module Lobot
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
    argument :build_server, :type => :string, :default => "Jenkins"

    def create_ci_files
      template 'ci.yml', 'config/ci.yml'
      template 'ci.yml', 'config/ci.yml.example'
      template 'bootstrap_server.sh', 'script/bootstrap_server.sh'
      template 'deploy-ci.rb', 'config/deploy/ci.rb'
      template 'capistrano-ci.rb', 'config/capistrano/ci.rb'
      template 'soloistrc', 'soloistrc'
      template 'ci_build.sh', 'script/ci_build.sh'
      system "chmod a+x #{destination_root}/script/ci_build.sh"
    end

    def add_load_path_to_capfile
      template 'Capfile', 'Capfile' unless File.exists?("#{destination_root}/Capfile")
      prepend_to_file 'Capfile', "load 'config/capistrano/ci'\n"
    end

    def add_ci_yml_to_gitignore
      if File.exists?("#{destination_root}/.gitignore")
        append_to_file '.gitignore', "config/ci.yml\n"
      else
        template 'dot-gitignore', '.gitignore'
      end
    end

    def create_chef_cookbooks
      directory 'chef', 'chef'
    end

    def add_ci_recipe_to_default
      server_name = build_server.downcase
      server_name = "jenkins" if build_server.blank?

      # append jenkins or teamcity recipe based on the user's choice
      append_to_file "chef/cookbooks/pivotal_ci/recipes/default.rb", %Q{include_recipe "pivotal_ci::#{server_name}"}
    end

  end
end
