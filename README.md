Lobot: Your Chief Administrative Aide on Cloud City
============================

![Lobot](http://i.imgur.com/QAkd7.jpg)
###A "one click" solution for deploying CI to EC2

Lando Calrissian relies on Lobot to keep Cloud City afloat, and now you can rely on Lobot to keep your continuous integration server running in the cloud. Lobot is a gem that will help you spin-up, bootstrap, and install Jenkins for CI for your Rails app on Amazon EC2.

# What do I get?

* rake tasks for starting a CI instance
* capistrano tasks for bootstrapping and deploying to an EC2 instance
* chef recipes for configuring a Centos server to run Jenkins and build Rails projects.

all you'll need to do is:

    rails g lobot:install
    edit config/ci.yml
    rake ci:server_start && cap ci bootstrap && cap ci chef

## Install

Add lobot to your Gemfile

    gem "lobot"

## Generate
Lobot is a Rails 3 generator.  Rails 2 can be made to work, but you will need to copy the template files into your project.

    rails g lobot:install

## Setup

Edit config/ci.yml

    --- 
    app_name: # a short name for your application
    app_user: # the user created to run your CI process
    git_location: # The location of your remote git repository which Jenkins will poll and pull from on changes.
    basic_auth: 
    - username: # The username you will use to access the Jenkins web interface
      password: # The password you will use to access the Jenkins web interface
    credentials: 
      aws_access_key_id: # The Access Key for your Amazon AWS account
      aws_secret_access_key: The Secret Access Key for your Amazon AWS account
      provider: AWS # leave this one alone
    server: 
      name: run 'rake ci:server_start to populate'
      instance_id: run 'rake ci:server_start to populate'
    build_command: ./cruise_build.sh
    ec2_server_access: 
      key_pair_name: myapp_ci
      id_rsa_path: ~/.ssh/id_rsa
    id_rsa_for_github_access: |-
      -----BEGIN RSA PRIVATE KEY-----
      SSH KEY WITH ACCESS TO GITHUB GOES HERE
      -----END RSA PRIVATE KEY-----
      
For security, you can add ci.yml to your .gitignore file and store a ci.yml.example without authentication credentials in your repository

## Dependencies

* fog
* capistrano
* capistrano-ext
* rvm (the gem - it configures capistrano to use RVM on the server)

# Tests

Lobot is tested using rspec, generator_spec and cucumber.  Cucumber provides a full integration test which can generate a rails application, push it to github, start a server and bring up CI for the generated project.  You'll need a git repository(which should not have any code you care about) and an AWS account to run the spec.  It costs about $0.50 and takes about half an hour.  It does not clean up after itself, so be sure to terminate the server when you're done, or it will cost substantially more than $0.50.  Use the secrets.yml.example to create a secrets.yml file with your accounts.

# Contributing

Lobot is in its infancy and we welcome pull requests.  Pull requests should have test coverage for quick consideration.

# License

Lobot is MIT Licensed and © Pivotal Labs.  See LICENSE.txt for details.
