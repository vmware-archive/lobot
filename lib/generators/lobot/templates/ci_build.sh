#!/usr/bin/env bash

source $HOME/.rvm/scripts/rvm && source .rvmrc

# install bundler if necessary
gem list --local bundler | grep bundler || gem install bundler || exit 1

# debugging info
echo USER=$USER && ruby --version && which ruby && which bundle

# conditionally install project gems from Gemfile
bundle check || bundle install || exit 1

RAILS_ENV=development rake db:version > /dev/null || rake db:create
RAILS_ENV=test rake db:version  > /dev/null || rake db:create

RAILS_ENV=development rake db:migrate test:prepare

rake ci:headlessly['rake spec'] && rake ci:headlessly['rake jasmine:ci']