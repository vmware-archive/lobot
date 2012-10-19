describe_recipe "pivotal_ci::jenkins" do
  include MiniTest::Chef::Assertions
  include MiniTest::Chef::Context
  include MiniTest::Chef::Resources

  it "runs jenkins" do
    service("jenkins").must_be_running
  end

  it "creates the jenkins user" do
    user("jenkins").must_exist
  end
end

describe_recipe "pivotal_ci::default" do
  it "requires basic auth" do
    `curl -ks https://localhost/`.must_match /401 Authorization Required/
  end

  it "sets the right basic_auth credentials" do
    credentials = "#{node['nginx']['basic_auth_user']}:#{node['nginx']['basic_auth_password']}"
    `curl -ks --user #{credentials} https://localhost/`.must_match /jenkins/
  end
end