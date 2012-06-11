#!/usr/bin/env bash

source $HOME/.rvm/scripts/rvm && source .rvmrc

# install bundler if necessary
gem list --local bundler | grep bundler || gem install bundler || exit 1

# debugging info
echo USER=$USER && ruby --version && which ruby && which bundle

# conditionally install project gems from Gemfile
bundle check || bundle install || exit 1

test -e config/database.yml || (test -e config/database.yml.example && cp config/database.yml.example config/database.yml)
test -e config/database.yml || (test -e config/database.example.yml && cp config/database.example.yml config/database.yml)

RAILS_ENV=development rake db:version > /dev/null || rake db:create
RAILS_ENV=test rake db:version  > /dev/null || rake db:create

RAILS_ENV=development rake db:migrate test:prepare

rake ci:headlessly['rake -f `bundle show ci_reporter`/stub.rake ci:setup:rspec default'] --trace
