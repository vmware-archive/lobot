execute "install xvfb" do
  command "yum -y install xorg-x11-server-Xvfb"
end

execute "install firefox" do
  command "yum -y install firefox"
end
