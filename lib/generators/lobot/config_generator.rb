module Lobot
  class ConfigGenerator < Rails::Generators::Base
    source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))

    def generate_ci_config
      default_git_location = nil
      if File.exist?(Rails.root.join(".git/config"))
        default_git_location = `cat .git/config | grep url`.strip.split.last
      else
        puts "nope"
      end
      default_app_name = File.basename(Rails.root)
      config = {
        'app_name' => default_app_name,
        'app_user' => ENV['USER'],
        'git_location' => default_git_location,
        'basic_auth' => {
          'username' => "#{default_app_name}_ci",
        },
        'credentials' => {
          'provider' => "AWS"
        },
        'server' => {
          'flavor_id' => "m1.large",
          'security_group' => "ci_servers",
          'ssh_port' => "22"
        },
        'build_command' => "./script/ci_build.sh",
        'ec2_server_access' => {
          "key_pair_name" => "#{default_app_name}_ci",
          "id_rsa_path" => File.expand_path("~/.ssh/id_rsa")
        },
        "github_private_ssh_key_path" => File.expand_path("~/.ssh/id_rsa")
      }

      say "* The name of your application as it will appear in CI"
      app_name = ask "Application Name [#{config['app_name']}]: "
      config['app_name'] = app_name if app_name != ""

      say "* The user created to run your CI process"
      app_user = ask "Application User [#{config['app_user']}]: "
      config['app_user'] = app_user if app_user != ""

      say "* The location of your remote git repository which CI will poll and pull from on changes"
      git_location = ask "Git Repository Location [#{config['git_location']}]: "
      config['git_location'] = git_location if git_location != ""

      say "* The username you will use to access the CI web interface"
      ci_username = ask "CI Username [#{config['basic_auth']['username']}]: "
      config['basic_auth']['username'] = ci_username if ci_username != ""

      say "* The password you will use to access the Jenkins web interface"
      ci_password = ask "Choose a CI password: "
      config['basic_auth']['password'] = ci_password

      say <<-EOS
* See https://aws-portal.amazon.com/gp/aws/developer/account/index.html?ie=UTF8&action=access-key
* for access key id and secret access key
      EOS
      aws_access_key_id = ask "AWS Access Key ID: "
      config['credentials']['aws_access_key_id'] = aws_access_key_id
      aws_secret_access_key = ask "AWS Secret Access Key: "
      config['credentials']['aws_secret_access_key'] = aws_secret_access_key

      say <<-EOS
* See http://aws.amazon.com/ec2/instance-types/ API name values (e.g. m1.large)
      EOS
      flavor_id = ask "Choose an EC2 instance type [#{config['server']['flavor_id']}]: "
      config['server']['flavor_id'] = flavor_id if flavor_id != ""

      security_group = ask "AWS EC2 Security Group Name [#{config['server']['security_group']}]: "
      config['server']['security_group'] = security_group if security_group != ""

      ssh_port = ask "Server SSH Port [#{config['server']['ssh_port']}]: "
      config['server']['ssh_port'] = ssh_port if ssh_port != ""

      build_command = ask "Build Command: [#{config['build_command']}]: "
      config['build_command'] = build_command if build_command != ""

      say <<-EOS
* This should refer to an SSH key pair that you have already generated. You may wish to generate a new key
* separate from what you may already be using for github or other systems.
* For a tutorial on this see: http://open.bsdcow.org/histerical/tutorials/ssh_pubkey_auth#1.2
      EOS
      while true do
        id_rsa_path = ask "Path to SSH Private Key for EC2 Access [#{config['ec2_server_access']['id_rsa_path']}]: "
        config['ec2_server_access']['id_rsa_path'] = id_rsa_path if id_rsa_path != ""
        if config['ec2_server_access']['id_rsa_path'] != File.expand_path(config['ec2_server_access']['id_rsa_path'])
          config['ec2_server_access']['id_rsa_path'] = File.expand_path(File.join(ENV['HOME'], '.ssh', config['ec2_server_access']['id_rsa_path']))
        end
        if File.exist?(config['ec2_server_access']['id_rsa_path']) && File.exist?("#{config['ec2_server_access']['id_rsa_path']}.pub")
          break
        else
          say "Unable to find both #{config['ec2_server_access']['id_rsa_path']} and #{config['ec2_server_access']['id_rsa_path']}.pub"
        end
      end

      say <<-EOS
* This is an arbitrary label corresponding to the SSH credentials that you just selected
* You may name this anything you like. For example: your project name, hostname or name of the SSH key you just chose
      EOS
      key_pair_name = ask "AWS EC2 Key Pair Name [#{config['ec2_server_access']['key_pair_name']}]: "
      config['ec2_server_access']['key_pair_name'] = key_pair_name if key_pair_name != ""

      say <<-EOS
* This needs to refer to an SSH Private Key that has been associated an account that has access to the git
* repository you entered above. On github this will be listed here: https://github.com/settings/ssh
      EOS
      while true do
        github_private_ssh_key_path = ask "Path to SSH Private Key for Github [#{config['github_private_ssh_key_path']}]: "
        config['github_private_ssh_key_path'] = github_private_ssh_key_path if github_private_ssh_key_path != ""
        if config['github_private_ssh_key_path'] != File.expand_path(config['github_private_ssh_key_path'])
          config['github_private_ssh_key_path'] = File.expand_path(File.join(ENV['HOME'], '.ssh', config['github_private_ssh_key_path']))
        end
        if File.exist?(config['github_private_ssh_key_path'])
          break
        else
          say "Unable to find #{config['github_private_ssh_key_path']}"
        end
      end



      config_ci = YAML.load_file(Rails.root.join("config/ci.yml")) rescue {}
      config_ci.merge!(config)

      File.open(Rails.root.join("config/ci.yml"), "w") do |f|
        f << config_ci.to_yaml
      end

      say "\n\nconfig/ci.yml configured. To launch your instance run rake ci:server_start."
      say "Be sure to push uncommitted changes made by the lobot:install process first."
    end
  end
end

