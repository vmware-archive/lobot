default["jenkins"] = {}
default["jenkins"]["home"] = "/var/lib/jenkins"
default["jenkins"]["builds"] = [{
  "branch" => "master",
  "command" => "script/ci_build.sh",
  "name" => "NewProject",
  "repository" => "https://github.com/pivotal/lobot"
}]
