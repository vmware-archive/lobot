Lobot: Your Chief Administrative Aide on Cloud City
============================

![Lobot](http://cheffiles.pivotallabs.com/lobot/logo.png)

## Easily create your CI server on EC2

Lando Calrissian relies on Lobot to keep Cloud City afloat, and now you can rely on Lobot to get your continuous integration server running in the cloud. Lobot is a gem that will help you spin-up, bootstrap, and install Jenkins CI for your Rails app on Amazon EC2.

# Lobot 2.0 Warning

Please note these instructions are the for the *prerelease Lobot 2.0*.  Please report any issues you encounter by opening a github issue.

# What do I get?

* Commands for creating, starting, stopping, or destroying your CI server on EC2
* The full [Travis CI](http://travis-ci.org) environment on Ubuntu 12.04
* A Jenkins frontend for monitoring your builds

After you add `gem "lobot"` to your Gemfile, all you'll need to do is run the following commands:

    [lobot configure] - COMING SOON - See Setup for now.
    lobot create
    lobot bootstrap
    lobot add_build BobTheBuild git@github.com:you/some_repo.git master script/ci_build.sh
    lobot chef
    lobot trust_certificate     # only if you're on a mac

Read on for an explanation of what each one of these steps does.

## Install

Add lobot to your Gemfile, in the development group:

    gem "lobot", :group => :development

## Setup

Create a config/lobot.yml file in your project:

    ---
    server_ssh_key: ~/.ssh/id_rsa
    github_ssh_key: ~/.ssh/id_rsa
    aws_key: <your AWS Key>
    aws_secret: <your AWS Secret>
    node_attributes:
      travis_build_environment:
        user: jenkins
        group: nogroup
        home: /var/lib/jenkins
      nginx:
        basic_auth_user: ci
        basic_auth_password: password

See [https://aws-portal.amazon.com/gp/aws/developer/account/index.html?ie=UTF8&action=access-key](https://aws-portal.amazon.com/gp/aws/developer/account/index.html?ie=UTF8&action=access-key) to generate AWS key/secret.

Then, create a build script in `script/ci_build.sh`:

    #!/bin/bash -l
    source .rvmrc

    set -e

    gem install bundler --no-ri --no-rdoc && bundle install

    RAILS_ENV=test rake db:migrate
    rake

## Adjust Defaults (Optional)

In your config/lobot.yml, there are defaults set for values that have the recommened value. For example, the instance size used for EC2 is set to "c1.medium".

You can save on EC2 costs by using a tool like [projectmonitor](https://github.com/pivotal/projectmonitor) or ylastic to schedule when your instances are online.

## Commit and push your changes

At this point you will need to create a commit of the files generated or modified and push those changes to your remote git repository so Jenkins can execute the build script when it pulls down your repo for the first time.

If you must, you can do this on a branch.  Then later you can change the branch in lobot.yml later and rechef.

## Modify recipe list

You can modify the chef run list by setting the `recipes` key in config/lobot.yml.  The default is:

	["pivotal_ci::jenkins", "pivotal_ci::limited_travis_ci_environment", "pivotal_ci"]`

Because we're using the cookbooks from Travis CI, you can look through [all the recipes Travis has available](https://github.com/travis-ci/travis-cookbooks/), and add any that you need.

## Starting your lobot instance

1. Launch an instance, allocate and associates an elastic IP and updates config/lobot.yml:

        lobot create

2. Bootstrap the instance using the boostrap_server.sh script. The script installs ruby prerequisites and installs RVM:

        lobot bootstrap

3. Upload the contents of Lobot's cookbooks, create a soloistrc, and run chef:

        lobot chef

Your lobot instance should now be up and running. You will be able to access your CI server at: http://&lt;your instance address&gt;/ with the username and password you chose during configuration.
For more information about Jenkins CI, see [http://jenkins-ci.org](http://jenkins-ci.org).

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

* fog
* ci_reporter
* thor
* hashie
* net-ssh

## Testing

Lobot is tested using rspec, vagrant and test kitchen.  You will need to set environment variables with your AWS credentials to run tests which rely on ec2:

    export EC2_KEY=FOO
    export EC2_SECRET=BAR

# Contributing

We welcome pull requests.  Pull requests should have test coverage for quick consideration.  Please fork, make your changes on a branch, and open a pull request.

# License

Lobot is MIT Licensed and © Pivotal Labs.  See LICENSE.txt for details.
