include_recipe "pivotal_server::daemontools"
include_recipe "pivotal_ci::xvfb"
include_recipe "pivotal_ci::git_config"

username = ENV['SUDO_USER'].strip
user_home = ENV['HOME']

install_dir = "#{user_home}"
tar_location = "#{install_dir}/teamcity.tar.gz"

execute "download teamcity" do
  command "mkdir -p #{install_dir} && curl -Lsf http://download.jetbrains.com/teamcity/TeamCity-7.0.2a.tar.gz -o #{tar_location}"
  user username
  not_if { File.exists?(tar_location) }
end

execute "unpack teamcity" do
  command "cd #{install_dir} && tar xfz #{tar_location} && mkdir -p #{install_dir}/TeamCity/logs"
  user username
  group username
  not_if { File.exists?("#{install_dir}/TeamCity") }
end

template "/etc/init.d/teamcity" do
  source "teamcity-initd.erb"
  variables(
    :username => username
  )
  mode 0755
end

execute "Start TeamCity" do
  # while this runs successfully, it doesn't successfully start TeamCity.  Rebooting instead.
  command "/etc/init.d/teamcity start"
end

execute "Adding TeamCity to init.d" do
  command "chkconfig --add teamcity"
end

execute "Reboot the instance to bring up TeamCity" do
  command "sudo reboot"
end
