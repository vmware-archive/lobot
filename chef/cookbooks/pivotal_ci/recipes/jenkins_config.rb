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

['git', 'ansicolor'].each do |plugin|
  execute "download #{plugin} plugin" do
    jenkins_plugin.call(self, plugin, "http://mirrors.jenkins-ci.org/plugins/#{plugin}/latest/#{plugin}.hpi")
  end
end

node["jenkins"]["builds"].each do |build|
  directory "#{node["jenkins"]["home"]}/jobs/#{build['name']}" do
    owner "jenkins"
  end

  template "#{node["jenkins"]["home"]}/jobs/#{build['name']}/config.xml" do
    source "jenkins-job-config.xml.erb"
    owner "jenkins"
    notifies :restart, "service[jenkins]"
    variables(
      :branch => build['branch'],
      :command => build['command'],
      :repository => build['repository']
    )
  end
end
