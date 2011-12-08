#!/bin/bash -e

env | grep -q "APP_USER=" || echo "Please set APP_USER environment variable"

# perl -e 'print crypt("password", "salt"),"\n"'
sudo getent passwd $APP_USER >/dev/null 2>&1 || sudo useradd $APP_USER -s /bin/bash -p DEADBEEFSCRYPTEDPASSWORD #sa3tHJ3/KuYvI would be password


sudo groupadd vagrant
sudo useradd vagrant -s /bin/bash -p DEADBEEFSCRYPTEDPASSWORD  -g vagrant -m

# copy root's authorized keys to APP_USER
sudo mkdir -p  /home/$APP_USER/.ssh
sudo touch /home/$APP_USER/.ssh/authorized_keys
sudo chmod 700 /home/$APP_USER/.ssh
sudo chmod 600 /home/$APP_USER/.ssh/authorized_keys
sudo chown -R $APP_USER /home/$APP_USER

authorized_keys_string=`cat /home/ubuntu/.ssh/authorized_keys`
sudo grep -sq "$authorized_keys_string" /home/$APP_USER/.ssh/authorized_keys || cat /home/ubuntu/.ssh/authorized_keys | sudo tee -a /home/$APP_USER/.ssh/authorized_keys

## enable ssh password auth
sudo perl -p -i -e 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config 
sudo restart ssh

# get the latest servers
sudo apt-get update -q

# install git
sudo apt-get install --install-suggests --assume-yes -q git 

# mri ruby prereqs
sudo apt-get install  --install-suggests --assume-yes -q build-essential openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion

# jruby
sudo apt-get install  --install-suggests --assume-yes -q curl g++ openjdk-6-jre-headless ant openjdk-6-jdk

curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer -o /tmp/rvm-installer
sudo chmod +x /tmp/rvm-installer
sudo /tmp/rvm-installer --version latest

cat <<'RVMRC_CONTENTS' | sudo tee /etc/rvmrc
rvm_install_on_use_flag=1
rvm_trust_rvmrcs_flag=1
rvm_gemset_create_on_use_flag=1
RVMRC_CONTENTS

sudo usermod -G root,admin,rvm $APP_USER

# passwordless sudo
sudo_string='ALL            ALL = (ALL) NOPASSWD: ALL'
sudo grep "$sudo_string" /etc/sudoers || echo "$sudo_string" | sudo tee -a /etc/sudoers
