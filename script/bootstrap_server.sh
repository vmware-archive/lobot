#!/bin/bash

set -e

packages="git build-essential openssl libreadline6 libreadline6-dev libreadline5 curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev autoconf libc6-dev libncurses5-dev automake libtool bison subversion pkg-config"

for package in $packages
do
  if ! dpkg --get-selections | grep "^$package\s" > /dev/null
  then
    to_install="$to_install $package"
  fi
done

if [ ! -z "$to_install" ]
then
	sudo apt-get install -y $to_install
fi

test -d /usr/local/rvm || curl -L https://get.rvm.io | sudo bash -s stable

sudo tee /etc/profile.d/rvm.sh > /dev/null <<RVMSH_CONTENT
[[ -s "/usr/local/rvm/scripts/rvm" ]] && source "/usr/local/rvm/scripts/rvm"
RVMSH_CONTENT

sudo tee /etc/rvmrc > /dev/null <<RVMRC_CONTENTS
rvm_install_on_use_flag=1
rvm_trust_rvmrcs_flag=1
rvm_gemset_create_on_use_flag=1
RVMRC_CONTENTS

sudo usermod ubuntu -a -G rvm
