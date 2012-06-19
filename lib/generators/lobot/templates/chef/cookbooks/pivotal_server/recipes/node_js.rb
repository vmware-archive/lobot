directory Chef::Config[:file_cache_path] do
  owner "root"
  group "root"
  mode 0777
  action :create
  recursive true
end

git "#{Chef::Config[:file_cache_path]}/node_js" do
  repository "git://github.com/joyent/node.git"
  revision "627f379f2273341426ab3d5cb7eb4d5c148d500a"
  action :sync
end

script "compile & install node" do
  interpreter "bash"
  cwd "/tmp/node_js"
  code "./configure && make install"
  not_if "which node"
end



