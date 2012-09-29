include_recipe 'pivotal_ci::jenkins'

directory "#{node["jenkins"]["home"]}/plugins" do
  owner "jenkins"
end

['git', 'ansicolor'].each do |plugin|
  execute "download #{plugin} plugin" do
    command "curl -Lsf http://mirrors.jenkins-ci.org/plugins/#{plugin}/latest/#{plugin}.hpi -o #{node["jenkins"]["home"]}/plugins/#{plugin}.hpi"
    not_if { File.exists?("#{node["jenkins"]["home"]}/plugins/#{plugin}.hpi") }
    user "jenkins"
    notifies :restart, "service[jenkins]"
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
    :build_command => CI_CONFIG['build_command']
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
      :build_command => build['build_script']
    )
  end
end