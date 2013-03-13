#!/bin/bash -le

source .rvmrc

# install bundler if necessary
set -e

gem install bundler --no-ri --no-rdoc && bundle install

# debugging info
echo USER=$USER && ruby --version && which ruby && which bundle

bundle exec rspec spec
