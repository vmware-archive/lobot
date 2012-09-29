Capistrano::Configuration.instance(:must_exist).load do
  require 'capistrano/ext/multistage'

  task :ci_setup do
    ci_conf_location ||= "config/ci.yml"
    ci_conf ||= YAML.load_file(ci_conf_location)

    if ENV["rvm_path"]
      require "bundler/capistrano"
      require "rvm/capistrano"
      set :rvm_ruby_string, ENV['GEM_HOME'].gsub(/.*\//,"")
      set :rvm_type, :system
    end
    set :app_name, ci_conf['app_name']
    set(:app_dir) { "/var/#{stage}/#{app_name}" }
    set :bootstrap_script, File.expand_path("../../../../script/bootstrap_server.sh", __FILE__)
    set :chef_path, File.expand_path("../../../../chef", __FILE__)
    set :user, 'ubuntu'
    ssh_options[:keys] = [ci_conf['ec2_server_access']['id_rsa_path']]
    default_run_options[:pty] = true
  end

  desc "check for server availability - run this task in a loop to see if the slice is ready to connect to"
  task :check_for_server_availability do
    ci_setup
    set :user, "root"
    run "echo Server is available"
  end

  desc "bootstrap"
  task :bootstrap do
    ci_setup
    set :default_shell, "/bin/bash"
    upload bootstrap_script, "bootstrap_server.sh"
    run "chmod a+x bootstrap_server.sh"
    run "./bootstrap_server.sh"
  end

  desc "setup and run chef"
  task :chef do
    ci_setup
    install_base_gems
    upload_cookbooks
    run_soloist
  end

  desc "Install gems that are needed for a chef run"
  task :install_base_gems do
    ci_setup
    run "gem list | grep soloist || gem install soloist --no-rdoc --no-ri"
    run "gem list | grep bundler || gem install bundler --no-rdoc --no-ri"
  end

  desc "Upload cookbooks"
  task :upload_cookbooks do
    ci_setup
    run "sudo mkdir -p #{app_dir}"
    run "sudo chown -R #{user} #{app_dir}"
    run "rm #{app_dir}/soloistrc || true"
    upload("soloistrc", "#{app_dir}/soloistrc")
    upload("config/ci.yml", "#{app_dir}/ci.yml")

    ci_config = YAML.load_file("config/ci.yml")
    if ci_config.has_key?("github_private_ssh_key_path")
      upload(File.expand_path(ci_config["github_private_ssh_key_path"]), "/home/#{user}/.ssh/id_rsa", {:mode => "0600"})
    end

    find_servers_for_task(current_task).each do |server|
      system("rsync -avz --delete '#{chef_path}/' 'ubuntu@#{server}:#{app_dir}/chef/' --exclude .git")
    end
  end

  desc "Run soloist"
  task :run_soloist do
    ci_setup
    run "cd #{app_dir} && ROLES=$CAPISTRANO:HOSTROLES$ PATH=/usr/sbin:$PATH APP_NAME=#{fetch(:app_name)} APP_DIR=#{fetch(:app_dir)} soloist"
  end
end