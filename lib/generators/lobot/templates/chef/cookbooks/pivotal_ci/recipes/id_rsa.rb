username = ENV['SUDO_USER'].strip

file "/home/#{username}/.ssh/id_rsa" do
  content CI_CONFIG['id_rsa_for_github_access']
  mode 0600
  only_if { CI_CONFIG['id_rsa_for_github_access'] }
  owner username
end

execute "add github to known hosts if necessary" do
  github_string = 'github.com,207.97.227.239 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ=='
  command "echo '#{github_string}' >> /home/#{username}/.ssh/known_hosts"
  not_if "grep '#{github_string}' /home/#{username}/.ssh/known_hosts"
end
