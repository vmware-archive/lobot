include_recipe "pivotal_server::daemontools"

src_dir = "/usr/local/src/mysql"
install_dir = "/usr/local/mysql"
mysql_root_password = "password"
mysql_user_name = "app_user"
mysql_user_password = "password"

{
  "bison" => "2.3-2.1",
  "ncurses-devel" => "5.5-24.20060715"
}.each do |package_name, version_string|
  package package_name do
    action :install
    version version_string
  end
end

user "mysql"

run_unless_marker_file_exists("mysql_5_1_with_innodb") do
  execute "download mysql src" do
    command "mkdir -p #{src_dir} && curl -Lsf http://mysql.he.net/Downloads/MySQL-5.1/mysql-5.1.57.tar.gz |  tar xvz -C#{src_dir} --strip 1"
  end

  execute "configure" do
    command "./configure --prefix=/usr/local/mysql  --with-plugins=innobase,myisam"
    cwd src_dir
  end

  execute "make" do
    command "make"
    cwd src_dir
  end

  execute "make install" do
    command "make install"
    cwd src_dir
  end

  execute "mysql owns #{install_dir}" do
    command "chown -R mysql #{install_dir}"
  end

  execute "install db" do
    command "#{install_dir}/bin/mysql_install_db --user=mysql"
    cwd install_dir
  end
end

file "/etc/ld.so.conf.d/mysql-64.conf" do
  content "/usr/local/mysql/lib/mysql/"
end

execute "add mysql to ldconf" do
  command "/sbin/ldconfig"
end

template "/etc/my.cnf" do
  source "my-conf.erb"
  owner "mysql"
  mode "0644"
end

execute "create daemontools directory" do
  command "mkdir -p /service/mysql"
end

execute "create run script" do
  command "echo -e '#!/bin/sh\nexec /command/setuidgid mysql  /usr/local/mysql/libexec/mysqld' > /service/mysql/run"
  not_if "ls /service/mysql/run"
end

execute "make run script executable" do
  command "chmod 755 /service/mysql/run"
end

ruby_block "wait for mysql to come up" do
  block do
    Timeout::timeout(60) do
      until system("ls /tmp/mysql.sock")
        sleep 1
      end
    end
  end
end

execute "set the root mysql password" do
  command "#{install_dir}/bin/mysqladmin -uroot password #{mysql_root_password}"
  not_if "#{install_dir}/bin/mysql -uroot -p#{mysql_root_password} -e 'show databases'"
end

execute "create app_user user" do
  command "#{install_dir}/bin/mysql -u root -p#{mysql_root_password} -D mysql -r -B -N -e \"CREATE USER '#{mysql_user_name}'@'localhost'\""
  not_if "#{install_dir}/bin/mysql -u root -p#{mysql_root_password} -D mysql -r -B -N -e \"SELECT * FROM user where User='#{mysql_user_name}' and Host = 'localhost'\" | grep -q #{mysql_user_name}"
end

execute "set password for app_user" do
  command "#{install_dir}/bin/mysql -u root -p#{mysql_root_password} -D mysql -r -B -N -e \"SET PASSWORD FOR '#{mysql_user_name}'@'localhost' = PASSWORD('#{mysql_user_password}')\""
end

execute "grant user all rights (this maybe isn't a great idea)" do
  command "#{install_dir}/bin/mysql -u root -p#{mysql_root_password} -D mysql -r -B -N -e \"GRANT ALL on *.* to '#{mysql_user_name}'@'localhost'\""
end

execute "insert time zone info" do
  command "#{install_dir}/bin/mysql_tzinfo_to_sql /usr/share/zoneinfo | #{install_dir}/bin/mysql -uroot -p#{mysql_root_password} mysql"
end
