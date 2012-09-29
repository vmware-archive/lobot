module Lobot
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
    argument :build_server, :type => :string, :default => "Jenkins"

    def create_ci_files
      template 'ci.yml', 'config/ci.yml'
      template 'ci.yml', 'config/ci.yml.example'
      template 'deploy-ci.rb', 'config/deploy/ci.rb'
      template 'soloistrc', 'soloistrc'
      template 'ci_build.sh', 'script/ci_build.sh'
      system "chmod a+x #{destination_root}/script/ci_build.sh"
    end

    def add_load_path_to_capfile
      template 'Capfile', 'Capfile' unless File.exists?("#{destination_root}/Capfile")
      prepend_to_file 'Capfile', "require 'lobot/recipes/ci'\n"
    end

    def add_ci_reporter_to_gitignore
      system("touch #{destination_root}/.gitignore")
      append_to_file '.gitignore', "spec/reports\n"
    end
  end
end
