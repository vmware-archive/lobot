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

directory "#{node["jenkins"]["home"]}/jobs/#{ENV['APP_NAME']}" do
  owner "jenkins"
end

template "#{node["jenkins"]["home"]}/jobs/#{ENV['APP_NAME']}/config.xml" do
  source "jenkins-job-config.xml.erb"
  owner "jenkins"
  notifies :restart, "service[jenkins]"
  variables(
    :git_location => CI_CONFIG['git_location'],
    :build_command => CI_CONFIG['build_command'],
    :branch => node['jenkins']['git_branch']
  )
end

(CI_CONFIG['additional_builds'] || []).each do |build|
  directory "#{node["jenkins"]["home"]}/jobs/#{build['build_name']}" do
    owner "jenkins"
  end

  template "#{node["jenkins"]["home"]}/jobs/#{build['build_name']}/config.xml" do
    source "jenkins-job-config.xml.erb"
    owner "jenkins"
    notifies :restart, "service[jenkins]"
    variables(
      :git_location => build['git_location'],
      :build_command => build['build_script'],
      :branch => build['git_branch'] || 'master'
    )
  end
end