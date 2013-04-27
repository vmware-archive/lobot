# Lobot: Your Chief Administrative Aide on Cloud City

Moved to [ciborg](https://github.com/pivotal/ciborg).

![Lobot](http://cheffiles.pivotallabs.com/lobot/logo.png)

[![Code Climate](https://codeclimate.com/github/pivotal/lobot.png)](https://codeclimate.com/github/pivotal/lobot)
[![Build Status](https://travis-ci.org/pivotal/lobot.png?branch=master)](https://travis-ci.org/pivotal/lobot)


## Easily create your CI server on EC2

Lando Calrissian relies on Lobot to keep Cloud City afloat, and now you can rely on Lobot to get your continuous integration server running in the cloud. Lobot is a gem that will help you spin-up, bootstrap, and install Jenkins CI for your Rails app on Amazon EC2.

# What do I get?

* Commands for creating, starting, stopping, or destroying your CI server on EC2
* The full [Travis CI](http://travis-ci.org) environment on Ubuntu 12.04
* A Jenkins frontend for monitoring your builds

```
Tasks:
  lobot add_build <name> <repository> <branch> <command>  # Adds a build to Lobot
  lobot bootstrap          # Configures Lobot's master node
  lobot certificate        # Dump the certificate
  lobot chef               # Uploads chef recipes and runs them
  lobot config             # Dumps all configuration data for Lobot
  lobot create             # Create a new Lobot server using EC2
  lobot create_vagrant     # Creates a vagrant instance
  lobot destroy_ec2        # Destroys all the lobot resources on EC2
  lobot help [TASK]        # Describe available tasks or one specific task
  lobot open               # Open a browser to Lobot
  lobot setup              # Sets up lobot through a series of questions
  lobot ssh                # SSH into Lobot
  lobot trust_certificate  # Adds the current master's certificate to your OSX keychain
```

Read on for an explanation of what each one of these steps does.

## Install

    gem install lobot

Lobot runs independently of your project and is not a dependency.

## Setup

If this is your first time running `lobot` and you do not have configuration file, yet, run:

    lobot setup

It will ask you a series of questions that will get you up and running.

## Adjust Defaults (Optional)

If you don't like the default, Rails-centric, build script you can create your own:

```sh
#!/bin/bash -le

source .rvmrc

# install bundler if necessary
set -e

gem install bundler --no-ri --no-rdoc && bundle install

# debugging info
echo USER=$USER && ruby --version && which ruby && which bundle

bundle exec rake spec
```

In your config/lobot.yml, there are defaults set for recommended values. For example, the EC2 instance size is set to "c1.medium".

You can save on EC2 costs by using a tool like [projectmonitor](https://github.com/pivotal/projectmonitor) or ylastic to schedule when your instances are online.

## Commit and push your changes

At this point you will need to create a commit of the files generated or modified and push those changes to your remote git repository so Jenkins can execute the build script when it pulls down your repo for the first time.

If you must, you can do this on a branch.  Then later you can change the branch in lobot.yml later and rechef.

## Modify recipe list

You can modify the chef run list by setting the `recipes` key in config/lobot.yml.  The default is:

	["pivotal_ci::jenkins", "pivotal_ci::limited_travis_ci_environment", "pivotal_ci"]`

Because we're using the cookbooks from Travis CI, you can look through [all the recipes Travis has available](https://github.com/travis-ci/travis-cookbooks/), and add any that you need.

## Manually starting your lobot instance

1. Launch an instance, allocate and associates an elastic IP and updates config/lobot.yml:

        lobot create

2. Bootstrap the instance using the boostrap_server.sh script. The script installs ruby prerequisites and installs RVM:

        lobot bootstrap

3. Upload the contents of Lobot's cookbooks, create a soloistrc, and run chef:

        lobot chef

Your lobot instance should now be up and running. You will be able to access your CI server at: http://&lt;your instance address&gt;/ with the username and password you chose during configuration. Or, if you are on a Mac, run `lobot open`. For more information about Jenkins CI, see [http://jenkins-ci.org](http://jenkins-ci.org).

## Custom Chef Recipes

If you need to write your own chef recipes to install your project's dependencies, you can add a cookbooks directory to
the root of your project.  Make sure to delete the cookbook_paths section from your lobot.yml (to use the default values),
or add ./chef/project-cookbooks to the cookbook_paths section.

So, to have a bacon recipe, you should have cookbooks/pork/recipes/bacon.rb file in your repository.

## Troubleshooting

Shell access for your instance

    lobot ssh

Terminate all Lobot instances on your account and deallocate their elastic IPs

    lobot destroy_ec2

## Color

Lobot installs the ansicolor plugin, however you need to configure rspec to generate colorful output. One way is to include `--color` in your .rspec and update your spec_helper.rb to include

``` ruby
RSpec.configure do |config|
 config.tty = true
end
```

## Dependencies

* ci_reporter
* fog
* godot
* haddock
* hashie
* httpclient
* net-ssh
* thor

## Forking

Please be aware that Lobot uses git submodules.  In order to git source Lobot in your `Gemfile`, you will need the following line:

    gem "lobot", :github => "pivotal/lobot", :submodules => true

## Testing

Lobot is tested using rspec, vagrant and test kitchen.  You will need to set environment variables with your AWS credentials to run tests which rely on ec2:

    export EC2_KEY=FOO
    export EC2_SECRET=BAR

# Contributing

We welcome pull requests.  Pull requests should have test coverage for quick consideration.  Please fork, make your changes on a branch, and open a pull request.

# License

Lobot is MIT Licensed and © Pivotal Labs.  See LICENSE.txt for details.
