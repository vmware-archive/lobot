require 'yaml'
aws_conf_location = File.expand_path('../../ci.yml', __FILE__)
server_config = YAML.load_file(aws_conf_location)["server"]
ci_server = server_config['elastic_ip']
ssh_port = server_config['ssh_port'] || 22

role :ci, "#{ci_server}:#{ssh_port}"
