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
        'git_location' => default_git_location,
        'basic_auth' => [
          {
            'username' => "ci"
          }
        ],
        'credentials' => {
          'provider' => "AWS"
        },
        'server' => {
          'name' => nil,
          'instance_id' => nil,
          'flavor_id' => "c1.medium",
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

      say "* The name of your application as it will appear in CI", :green
      app_name = ask("Application Name [#{config['app_name']}]:", :bold)
      config['app_name'] = app_name if app_name != ""

      say "* The location of your remote git repository which CI will poll and pull from on changes", :green
      git_location = ask("Git Repository Location [#{config['git_location']}]:", :bold)
      config['git_location'] = git_location if git_location != ""

      say "* The username you will use to access the CI web interface", :green
      ci_username = ask("CI Username [#{config['basic_auth'][0]['username']}]:", :bold)
      config['basic_auth'][0]['username'] = ci_username if ci_username != ""

      say "* The password you will use to access the CI web interface", :green
      while true do
        ci_password = ask("Choose a CI password:", :bold)
        config['basic_auth'][0]['password'] = ci_password
        if ci_password == ""
          say "Password cannot be blank", :red
        else
          break
        end
      end

      say (<<-EOS).chop, :green

* See https://aws-portal.amazon.com/gp/aws/developer/account/index.html?ie=UTF8&action=access-key
* for access key id and secret access key
      EOS
      while true do
        aws_access_key_id = ask("AWS Access Key ID:", :bold)
        config['credentials']['aws_access_key_id'] = aws_access_key_id
        if aws_access_key_id == ""
          say "AWS Access Key ID cannot be blank", :red
        else
          break
        end
      end

      while true do
        aws_secret_access_key = ask("AWS Secret Access Key:", :bold)
        config['credentials']['aws_secret_access_key'] = aws_secret_access_key
        if aws_secret_access_key == ""
          say "AWS Secret Access Key cannot be blank", :red
        else
          break
        end
      end

      build_command = ask("Build Command: [#{config['build_command']}]:", :bold)
      config['build_command'] = build_command if build_command != ""

      say (<<-EOS).chop, :green

* This should refer to an SSH key pair that you have already generated. You may wish to generate a new key
* separate from what you may already be using for github or other systems.
* For a tutorial on this see: http://open.bsdcow.org/histerical/tutorials/ssh_pubkey_auth#1.2
      EOS
      while true do
        id_rsa_path = ask("SSH Private Key for EC2 Access [#{config['ec2_server_access']['id_rsa_path'].split('/').last}]:", :bold)
        config['ec2_server_access']['id_rsa_path'] = id_rsa_path if id_rsa_path != ""
        if config['ec2_server_access']['id_rsa_path'] != File.expand_path(config['ec2_server_access']['id_rsa_path'])
          config['ec2_server_access']['id_rsa_path'] = File.expand_path(File.join(ENV['HOME'], '.ssh', config['ec2_server_access']['id_rsa_path']))
        end
        if File.exist?(config['ec2_server_access']['id_rsa_path']) && File.exist?("#{config['ec2_server_access']['id_rsa_path']}.pub")
          break
        else
          say "Unable to find both #{config['ec2_server_access']['id_rsa_path']} and #{config['ec2_server_access']['id_rsa_path']}.pub", :red
        end
      end

      say (<<-EOS).chop, :green

* This needs to refer to an SSH Private Key that has been associated an account that has access to the git
* repository you entered above. On github this will be listed here: https://github.com/settings/ssh
      EOS
      while true do
        github_private_ssh_key_path = ask("SSH Private Key for Github [#{config['github_private_ssh_key_path'].split('/').last}]:", :bold)
        config['github_private_ssh_key_path'] = github_private_ssh_key_path if github_private_ssh_key_path != ""
        if config['github_private_ssh_key_path'] != File.expand_path(config['github_private_ssh_key_path'])
          config['github_private_ssh_key_path'] = File.expand_path(File.join(ENV['HOME'], '.ssh', config['github_private_ssh_key_path']))
        end
        if File.exist?(config['github_private_ssh_key_path'])
          break
        else
          say "Unable to find #{config['github_private_ssh_key_path']}", :red
        end
      end

      config_ci = YAML.load_file(Rails.root.join("config/ci.yml")) rescue {}
      config_ci.merge!(config)

      File.open(Rails.root.join("config/ci.yml"), "w") do |f|
        f << config_ci.to_yaml
      end

      say "\n\nconfig/ci.yml configured:\n#{File.read(Rails.root.join('config/ci.yml'))}\n"
      say "You can edit this file to change any additional defaults."
      say "Before continuing, be sure to push uncommitted changes to your git repository.", :green
      say "For next steps, see the lobot README.md"
    end
  end
end

