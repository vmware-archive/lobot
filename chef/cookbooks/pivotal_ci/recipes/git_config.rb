include_recipe "pivotal_ci::jenkins"

execute "set git user.email" do
  command "git config --global user.email '#{node["git"]["email"]}'"
  not_if "git config -l | grep 'user.email=#{node["git"]["email"]}'", :environment => {"HOME"=>node["jenkins"]["home"]}
  user "jenkins"
  environment({"HOME"=>node["jenkins"]["home"]})
  cwd node["jenkins"]["home"]
end

execute "set git user.name" do
  command "git config --global user.name '#{node["git"]["name"]}'"
  not_if "git config -l | grep 'user.name=#{node["git"]["name"]}'", :environment => {"HOME"=>node["jenkins"]["home"]}
  user "jenkins"
  environment({"HOME"=>node["jenkins"]["home"]})
  cwd node["jenkins"]["home"]
end
