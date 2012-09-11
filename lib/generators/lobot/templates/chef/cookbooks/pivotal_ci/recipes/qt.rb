execute "rpm -ivh http://software.freivald.com/centos/software.freivald.com-1.0.0-1.noarch.rpm" do
  not_if "yum list software.freivald.com.noarch"
end

execute "yum -y install qt4.x86_64" do
  not_if "yum list qt | grep -q installed"
end

execute "yum -y install qt4-devel.x86_64" do
  not_if "yum list qt-devel | grep -q installed"
end