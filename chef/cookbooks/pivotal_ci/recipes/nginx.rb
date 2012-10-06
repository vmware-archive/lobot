include_recipe "pivotal_ci::ssl_certificate"

package "nginx" do
  version "1.1.19-1"
end

template "/etc/nginx/nginx.conf" do
  source "nginx-conf.erb"
  mode 0744
end

template "/etc/nginx/htpasswd" do
  source "nginx-htaccess.erb"
  mode 0644
end

service "nginx" do
  action :start
end