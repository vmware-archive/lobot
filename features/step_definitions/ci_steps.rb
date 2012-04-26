Given /^the temp directory is clean$/ do
  system!("rm -rf /tmp/lobot-test")
  system!("mkdir -p /tmp/lobot-test")
end

Given /^I am in the temp directory$/ do
  Dir.chdir(LOBOT_TEMP_DIRECTORY)
end

When /^I create a new Rails project$/ do
  system!("rvm ruby-1.9.3-p125 do rvm gemset create testapp")
  system!("rails new testapp")
  system!("cd testapp && echo 'rvm use ruby-1.9.3-p125@testapp' > .rvmrc")
end

When /^I vendor Lobot$/ do
  lobot_dir = File.expand_path('../../', File.dirname(__FILE__))
  system! "cd #{lobot_dir} && rake build"
  system! "mkdir -p testapp/vendor/cache/"
  system! "cp #{lobot_dir}/pkg/lobot-#{Lobot::VERSION}.gem testapp/vendor/cache/"
end

When /^I put Lobot in the Gemfile$/ do
  lobot_path = File.expand_path('../../', File.dirname(__FILE__))
  system!(%{echo "gem 'lobot'" >> testapp/Gemfile})
end

When /^I add a gem with an https:\/\/github.com source$/ do
  system!(%{echo "gem 'greyhawkweather', :git => 'https://github.com/verdammelt/Greyhawk-Weather.git'" >> testapp/Gemfile})
  system!("cd testapp && bundle install")
end

When /^I run bundle install$/ do
  system("cd testapp && gem uninstall lobot")
  system("cd testapp && gem install bundler")
  system!("cd testapp && bundle install")
  system!('cd testapp && bundle exec gem list | grep lobot')
end

When /^I run the Lobot generator for "([^"]*)"$/ do |build_server_name|
  system!("cd testapp && rails generate lobot:install #{build_server_name}")
  system!('ls testapp | grep -s soloistrc')
end

When /^I enter my info into the ci\.yml file$/ do
  hostname = `hostname`.strip
  secrets_file = File.expand_path('../config/secrets.yml', File.dirname(__FILE__))
  raise "Missing #{secrets_file}, needed for AWS test." unless File.exist?(secrets_file)
  secrets = YAML.load_file(secrets_file)
  raise "Missing AWS secret access key" unless secrets["aws_secret_access_key"].to_s != ""
  raise "Missing AWS access key id" unless secrets["aws_access_key_id"].to_s != ""
  raise "Missing github private key path" unless secrets["github_private_ssh_key_path"].to_s != ""

  raise "Missing private SSH key for AWS!" unless File.exist?(File.expand_path("~/.ssh/id_github_current"))
  ci_conf_location = 'testapp/config/ci.yml'
  ci_yml = YAML.load_file(ci_conf_location)
  ci_yml.merge!(
    'app_name' => 'testapp',
    'app_user' => 'testapp-user',
    'git_location' => 'git@github.com:pivotalprivate/ci-smoke.git',
    'basic_auth' => [{ 'username' => 'testapp', 'password' => 'testpass' }],
    'credentials' => { 'aws_access_key_id' => secrets['aws_access_key_id'], 'aws_secret_access_key' => secrets['aws_secret_access_key'], 'provider' => 'AWS' },
    'ec2_server_access' => {'key_pair_name' => "lobot_cucumber_key_pair_#{hostname}", 'id_rsa_path' => '~/.ssh/id_github_current'},
    'github_private_ssh_key_path' => secrets["github_private_ssh_key_path"]
  )
  # ci_yml['server']['name']  = '' # This can be used to merge in a server which is already running if you want to skip the setup steps while iterating on a test
  File.open(ci_conf_location, "w") do |f|
    f << ci_yml.to_yaml
    f << File.read(secrets_file)
  end
end

When /^I make changes to be committed$/ do
  lobot_dir = File.expand_path('../../', File.dirname(__FILE__))
  system! "rm testapp/vendor/cache/*"
  system! "cp #{lobot_dir}/pkg/lobot-#{Lobot::VERSION}.gem testapp/vendor/cache/"
  system! "echo 'config/ci.yml' >> testapp/.gitignore"
  ["headless", "rspec-rails", "jasmine"].each do |gem|
    system!(%{echo "gem '#{gem}'" >> testapp/Gemfile})
  end
  system!("cd testapp && bundle install")
  system!("cd testapp && bundle exec jasmine init .")
  system!(%{cd testapp && echo "task :default => 'jasmine:ci'" >> Rakefile})

  spec_contents = <<-RUBY
  require 'rspec'

  describe "The World" do
    it "should be green and blue" do
      the_world = ["green", "blue"]
      the_world.should include("green")
      the_world.should include("blue")
    end
  end
  RUBY

  File.open("testapp/spec/hello_world_spec.rb", "w") do |file|
    file.write(spec_contents)
  end
end

When /^I push to git$/ do
  system! "cd testapp && git init"
  system! "cd testapp && git add ."
  system! "cd testapp && git commit -m'initial commit'"
  system "cd testapp && git remote rm origin" # Ignore failures
  system! "cd testapp && git remote add origin git@github.com:pivotalprivate/ci-smoke.git"
  system! "cd testapp && git push --force -u origin master"
end

When /^I start the server$/ do
  system! "cd testapp && bundle exec rake ci:create_server"
end

When /^I bootstrap$/ do
  system!("cd testapp && bundle install")
  system! "cd testapp && bundle exec cap ci bootstrap"
end

When /^I deploy$/ do
  system! "cd testapp && cap ci chef"
end

Then /^CI is green$/ do
  Timeout::timeout(300) do
    until system("cd testapp && bundle exec rake ci:status")
      sleep 5
    end
  end
end

Then /^rake reports ci tasks as being available$/ do
  `cd testapp && bundle exec rake -T`.should include("ci:start_server")
end

Then /^TeamCity is installed$/ do
  ci_conf_location = 'testapp/config/ci.yml'
  ci_yml = YAML.load_file(ci_conf_location)

  Timeout::timeout(400) do
    until system("wget http://#{ci_yml['server']['elastic_ip']}:8111")
      sleep 5
    end
  end
end

