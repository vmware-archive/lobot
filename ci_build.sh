#!/bin/bash

source $HOME/.rvm/scripts/rvm && source .rvmrc

# install bundler if necessary
gem list --local bundler | grep bundler || gem install bundler || exit 1

# debugging info
echo USER=$USER && ruby --version && which ruby && which bundle

# conditionally install project gems from Gemfile
bundle check || bundle install || exit 1

# remove known_hosts2 - ec2 recycles ips
# known_hosts is owned by root and trusts github
rm ~/.ssh/known_hosts2

cp ~/secrets.yml features/config/

bundle exec rake default --trace