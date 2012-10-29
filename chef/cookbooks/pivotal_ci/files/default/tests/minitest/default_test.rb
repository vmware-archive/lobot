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

  it "configures the xvfb plugin" do
    file("/var/lib/jenkins/org.jenkinsci.plugins.xvfb.XvfbBuildWrapper.xml").must_exist
  end
end

describe_recipe "pivotal_ci::default" do
  def wait_for(match, options="")
    Timeout.timeout(10) do
      sleep 1 until `curl #{options} -ks https://localhost/` =~ match
      true
    end
  rescue Timeout::Error
    false
  end

  it "requires basic auth" do
    wait_for(/401 Authorization Required/).must_equal true
  end

  it "sets the right basic_auth credentials" do
    credentials = "#{node['nginx']['basic_auth_user']}:#{node['nginx']['basic_auth_password']}"
    wait_for(/jenkins/, "--user #{credentials}").must_equal true
  end
end