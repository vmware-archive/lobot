describe_recipe "pivotal_ci::jenkins" do
  it "runs jenkins" do
    service("jenkins").must_be_running
  end

  it "creates the jenkins user" do
    user("jenkins").must_exist
  end
end