include_recipe 'pivotal_ci::jenkins'

directory "#{node["jenkins"]["home"]}/plugins" do
  owner "jenkins"
end

jenkins_plugin = Proc.new do |resource, plugin, url|
  resource.command "curl -Lsf #{url} -o #{node["jenkins"]["home"]}/plugins/#{plugin}.hpi"
  resource.not_if { File.exists?("#{node["jenkins"]["home"]}/plugins/#{plugin}.hpi") }
  resource.user "jenkins"
  resource.notifies :restart, "service[jenkins]"
end

execute "download lobot plugin" do
  jenkins_plugin.call(self, "lobot", "http://cheffiles.pivotallabs.com/lobot/lobot.hpi")
end

['git-client', 'git', 'ansicolor', 'xvfb'].each do |plugin|
  execute "download #{plugin} plugin" do
    jenkins_plugin.call(self, plugin, "http://mirrors.jenkins-ci.org/plugins/#{plugin}/latest/#{plugin}.hpi")
  end
end

template "#{node["jenkins"]["home"]}/org.jenkinsci.plugins.xvfb.XvfbBuildWrapper.xml" do
  source "org.jenkinsci.plugins.xvfb.XvfbBuildWrapper.xml.erb"
  owner "jenkins"
  notifies :restart, "service[jenkins]"
end

node["jenkins"]["builds"].each do |build|
  directory "#{node["jenkins"]["home"]}/jobs/#{build['name']}" do
    owner "jenkins"
  end

  require "cgi"
  template "#{node["jenkins"]["home"]}/jobs/#{build['name']}/config.xml" do
    source "jenkins-job-config.xml.erb"
    owner "jenkins"
    notifies :restart, "service[jenkins]"
    junit_publisher = build['junit_publisher'].nil? ? true : build['junit_publisher']
    variables(
      :branch => build['branch'],
      :command => build['command'],
      :repository => build['repository'],
      :junit_publisher => junit_publisher
    )
  end
end
