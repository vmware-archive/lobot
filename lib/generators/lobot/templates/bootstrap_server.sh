#!/bin/bash -e
RVM_0_12_3_SHA=d6b4de7cfec42f7ce33198f0bd82544af51e8aa5

env | grep -q "APP_USER=" || echo "Please set APP_USER environment variable"

# perl -e 'print crypt("password", "salt"),"\n"'
getent passwd $APP_USER >/dev/null 2>&1 || useradd $APP_USER -p DEADBEEFSCRYPTEDPASSWORD #sa3tHJ3/KuYvI would be password

# copy root's authorized keys to APP_USER
mkdir -p  /home/$APP_USER/.ssh
touch /home/$APP_USER/.ssh/authorized_keys
chmod 700 /home/$APP_USER/.ssh
chmod 600 /home/$APP_USER/.ssh/authorized_keys
chown -R $APP_USER /home/$APP_USER/.ssh

authorized_keys_string=`cat /root/.ssh/authorized_keys`
grep -sq "$authorized_keys_string" /home/$APP_USER/.ssh/authorized_keys || cat /root/.ssh/authorized_keys >> /home/$APP_USER/.ssh/authorized_keys


## enable ssh password auth
perl -p -i -e 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
/etc/init.d/sshd reload

# install epel
rpm -q epel-release-5-4.noarch || rpm -Uvh http://mirrors.kernel.org/fedora-epel/5/x86_64/epel-release-5-4.noarch.rpm

# install git
yum -y install git

# rvm prereqs
yum install -y gcc-c++ patch readline readline-devel zlib zlib-devel libffi-devel openssl-devel iconv-devel java

# passwordless sudo
sudo_string='ALL            ALL = (ALL) NOPASSWD: ALL'
grep "$sudo_string" /etc/sudoers || echo "$sudo_string" >> /etc/sudoers

cat <<'BOOTSTRAP_AS_USER' > /home/$APP_USER/bootstrap_as_user.sh
set -e

export APP_USER=$1
export RVM_0_12_3_SHA=$2
mkdir -p /home/$APP_USER/rvm/src
curl -Lskf http://github.com/wayneeseguin/rvm/tarball/$RVM_0_12_3_SHA | tar xvz -C/home/$APP_USER/rvm/src --strip 1
cd "/home/$APP_USER/rvm/src" && ./install

rvm_include_string='[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"'
grep "$rvm_include_string" ~/.bashrc || echo "$rvm_include_string" >> ~/.bashrc

cat <<'RVMRC_CONTENTS' > ~/.rvmrc
rvm_install_on_use_flag=1
rvm_trust_rvmrcs_flag=1
rvm_gemset_create_on_use_flag=1
RVMRC_CONTENTS
BOOTSTRAP_AS_USER

chmod a+x /home/$APP_USER/bootstrap_as_user.sh
su - $APP_USER /home/$APP_USER/bootstrap_as_user.sh $APP_USER $RVM_0_12_3_SHA
rm /home/$APP_USER/bootstrap_as_user.sh
