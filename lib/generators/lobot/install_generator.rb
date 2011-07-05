module Lobot
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
    
    def create_ci_files
      template 'ci.yml', 'config/ci.yml'
      template 'ci.rake', 'lib/tasks/ci.rake'
      template 'bootstrap_server.sh', 'script/bootstrap_server.sh'
      template 'deploy-ci.rb', 'config/deploy/ci.rb'
      template 'capistrano-ci.rb', 'config/capistrano/ci.rb'
      template 'soloistrc', 'soloistrc'
    end
    
    def add_load_path_to_capfile
      template 'Capfile', 'Capfile' unless File.exists?("#{destination_root}/Capfile")
      prepend_to_file 'Capfile', "load 'config/capistrano/ci'\n"
    end
    
    def create_chef_cookbooks
      directory 'chef', 'chef'
    end
    
  end
end