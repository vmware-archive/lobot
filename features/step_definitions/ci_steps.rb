def system!(str)
  raise "Command Failed: #{str}" unless system(str)
end

Given /^I the temp directory is clean$/ do
  system!("rm -rf /tmp/lobot-test")
  system!("mkdir -p /tmp/lobot-test")
end

Given /^I am in the temp directory$/ do
  Dir.chdir('/tmp/lobot-test')
end

When /^I create a new Rails project using a Rails template$/ do
  system!("git clone git@github.com:pivotalprivate/rails3-templates.git")
  system!("ls -la")
  system!("echo -e '\nyes\nno\nno\nno\nno\nno\nno' | rails new testapp -m rails3-templates/main.rb")
end

When /^I put Lobot in the Gemfile$/ do
  lobot_path = File.expand_path('../../', File.dirname(__FILE__))
  system!(%{echo "gem 'lobot', :path => '#{lobot_path}'" >> testapp/Gemfile})
end

When /^I run bundle install$/ do
  system!("cd testapp && bundle install")
  system!('cd testapp && bundle exec gem list | grep lobot')
end

When /^I run the Lobot generator$/ do
  system!('cd testapp && rails generate lobot:install')
  system!('ls testapp | grep -s soloistrc')
end

When /^I enter my info into the ci\.yml file$/ do
  secrets = YAML.load_file(File.expand_path('../config/secrets.yml', File.dirname(__FILE__)))
  
  ci_conf_location = 'testapp/config/ci.yml'
  ci_yml = YAML.load_file(ci_conf_location)
  ci_yml.merge!(
  'app_name' => 'testapp',
  'app_user' => 'testapp-user',
  'git_location' => 'git@github.com:pivotalprivate/ci-smoke.git',
  'basic_auth' => [{ 'username' => 'testapp', 'password' => 'testpass' }],
  'credentials' => { 'aws_access_key_id' => secrets['aws_access_key_id'], 'aws_secret_access_key' => secrets['aws_secret_access_key'], 'provider' => 'AWS' },
  'id_rsa' => secrets['id_rsa']
  )
  File.open(ci_conf_location, "w") do |f|
    YAML.dump(ci_yml, f)
  end
end

When /^I push to git$/ do
  system! "echo 'config/ci.yml' >> testapp/.gitignore"
  system! "cd testapp && git add ."
  system! "cd testapp && git commit -m'initial commit'"
  system! "cd testapp && git remote add origin git@github.com:pivotalprivate/ci-smoke.git"
  system! "cd testapp && git push --force -u origin master"
end

When /^I run the server setup$/ do
  system! "cd testapp && rake ci:server_start"
end

When /^I bootstrap$/ do
  system! "cd testapp && cap ci bootstrap"
end

When /^I deploy$/ do
  system! "cd testapp && cap ci chef"
end

Then /^CI IS GREEN$/ do
  Timeout::timeout(300) do
    until system("cd testapp && rake ci:status")
      sleep 5
    end
  end
end
