describe_recipe "pivotal_ci::nginx" do
  it "requires basic auth" do
    `curl -ks https://localhost/`.must_match /401 Authorization Required/
  end

  it "sets the right basic_auth credentials" do
    credentials = "#{node['nginx']['basic_auth_user']}:#{node['nginx']['basic_auth_password']}"
    `curl -ks --user #{credentials} https://localhost/`.must_match /jenkins/
  end
end