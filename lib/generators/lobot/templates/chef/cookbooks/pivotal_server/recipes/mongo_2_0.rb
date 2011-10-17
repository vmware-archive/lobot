include_recipe "pivotal_server::daemontools"

install_dir = "/usr/local/mongo"

user "mongo"

run_unless_marker_file_exists("mongo_2_0") do
  execute "download mongo" do
    command "mkdir -p #{install_dir} && curl -Lsf http://downloads.mongodb.org/linux/mongodb-linux-i686-2.0.0.tgz | tar xvz -C#{install_dir} --strip 1"
  end

  execute "mongo owns #{install_dir}/data" do
    command "mkdir -p #{install_dir}/data && chown -R mongo #{install_dir}/data"
  end
end

execute "create daemontools directory" do
  command "mkdir -p /service/mongo"
end

execute "create run script" do
  command "echo -e '#!/bin/sh\nexec /command/setuidgid mongo  /usr/local/mongo/bin/mongod --dbpath #{install_dir}/data' > /service/mongo/run"
  not_if "ls /service/mongo/run"
end

execute "make run script executable" do
  command "chmod 755 /service/mongo/run"
end
