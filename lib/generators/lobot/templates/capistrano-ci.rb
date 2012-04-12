require 'capistrano/ext/multistage'

task :ci_setup do
  ci_conf_location ||= File.expand_path('../../../config/ci.yml', __FILE__)
  ci_conf ||= YAML.load_file(ci_conf_location)

  if ENV["rvm_path"]
    require "bundler/capistrano"
    require "rvm/capistrano"  # Use the gem, don't unshift RVM onto the load path, that's crazy.
    set :rvm_ruby_string, ENV['GEM_HOME'].gsub(/.*\//,"")
    set :rvm_type, :user
  end
  set :app_name, ci_conf['app_name']
  set(:app_dir) { "/var/#{stage}/#{app_name}" }
  set :user, ci_conf['app_user']
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
  app_user = user
  set :user, "root"
  set :default_shell, "/bin/bash"
  upload "script/bootstrap_server.sh", "/root/bootstrap_server.sh"
  run "chmod a+x /root/bootstrap_server.sh"
  run "APP_USER=#{app_user} /root/bootstrap_server.sh"
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
  p rvm_ruby_string
  run "gem list | grep soloist || gem install soloist --no-rdoc --no-ri"
  run "gem list | grep bundler || gem install bundler --no-rdoc --no-ri"
end

desc "Upload cookbooks"
task :upload_cookbooks do
  ci_setup
  run "sudo mkdir -p #{app_dir}"
  run "sudo chown -R #{user} #{app_dir}"
  run "rm #{app_dir}/soloistrc || true"
  run "rm -rf #{app_dir}/chef"
  upload("soloistrc", "#{app_dir}/soloistrc")
  upload("config/ci.yml", "#{app_dir}/ci.yml")
  ci_config = YAML.load_file("config/ci.yml")
  if ci_config.has_key?("github_private_ssh_key_path")
    upload(File.expand_path(ci_config["github_private_ssh_key_path"]), "/home/#{user}/.ssh/id_rsa", {:mode => "0600"})
  end
  upload("chef/", "#{app_dir}/chef/", :via => :scp, :recursive => true)
end

desc "Run soloist"
task :run_soloist do
  ci_setup
  run "cd #{app_dir} && ROLES=$CAPISTRANO:HOSTROLES$ PATH=/usr/sbin:$PATH APP_NAME=#{fetch(:app_name)} APP_DIR=#{fetch(:app_dir)} LOG_LEVEL=debug soloist"
end
