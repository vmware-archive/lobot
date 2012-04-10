include_recipe "pivotal_server::daemontools"
include_recipe "pivotal_server::libxml_prereqs"

src_dir = "/usr/local/src/postgres"
install_dir = "/usr/local/pgsql"

# mysql_root_password = "password"
# mysql_user_name = "app_user"
# mysql_user_password = "password"

# {
#   "cmake" => "2.6.4-5.el5.2",
#   "bison" => "2.3-2.1",
#   "ncurses-devel" => "5.5-24.20060715"
# }.each do |package_name, version_string|
#   package package_name do
#     action :install
#     version version_string
#   end
# end

user "postgres"

run_unless_marker_file_exists("postgres_9_0_4") do
  execute "download postgres src" do
    command "mkdir -p #{src_dir} && curl -Lsf http://ftp.postgresql.org/pub/source/v9.1.2/postgresql-9.1.2.tar.bz2 |  tar xvj -C#{src_dir} --strip 1"
  end

  execute "config" do
    command "./configure --disable-debug --enable-thread-safety --with-gssapi --with-krb5 --with-openssl --with-libxml --with-libxslt --with-perl --bindir=/usr/local/bin"
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

  directory "#{install_dir}/data/" do
    owner "postgres"
  end

  execute "init db" do
    command "initdb -E UTF8 #{install_dir}/data/"
    user "postgres"
  end
end


execute "create daemontools directory" do
  command "mkdir -p /service/postgres"
end

template "/service/postgres/run" do
  source "postgres-run-script.erb"
  mode 0755
end

file "/etc/ld.so.conf.d/postgres-64.conf" do
  content "/usr/local/pgsql/lib"
end

execute "add postgres to ldconf" do
  command "/sbin/ldconfig"
end

ruby_block "wait for postgres to come up" do
  block do
    Timeout::timeout(60) do
      until system("ls /tmp/.s.PGSQL.5432")
        sleep 1
      end
    end
  end
end
