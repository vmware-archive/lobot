namespace :ci do
  desc "Spin up CI server on amazon"
  task :server_start do
    require 'fog'
    require 'yaml'
    require 'socket'

    aws_conf_location = File.join(Dir.pwd, 'config', 'ci.yml')
    aws_conf = YAML.load_file(aws_conf_location)
    aws_credentials = aws_conf['credentials']
    ec2_server_access = aws_conf['ec2_server_access']
    server_config = aws_conf['server']

    security_group_name = server_config['security_group']

    aws_connection = Fog::Compute.new(
      :provider => aws_credentials['provider'],
      :aws_access_key_id => aws_credentials['aws_access_key_id'],
      :aws_secret_access_key => aws_credentials['aws_secret_access_key']
    )

    security_group = aws_connection.security_groups.get(security_group_name)

    if security_group.nil?
      puts "Could not find security group named '#{security_group_name}'.  Creating..."
      security_group = aws_connection.security_groups.new(:name => security_group_name, :description => 'ci servers group auto-created by lobot')
      security_group.save
      security_group.reload
      p security_group
    end

    PORTS_TO_OPEN = [22, 443, 80]
    PORTS_TO_OPEN.each do |port|
      is_in_security_group = !!security_group.ip_permissions.detect{|group| (group['fromPort']..group['toPort']).include?(port) && group['ipRanges'].detect{|range| range["cidrIp"]== "0.0.0.0/0" } }

      unless is_in_security_group
        puts "Allowing port #{port} into '#{security_group_name}' security group"
        security_group.authorize_port_range(port..port) 
      end
    end

    ec2_key_pair_name = ec2_server_access['key_pair_name'] || "ci"
    public_key_local_path = "#{ec2_server_access['id_rsa_path']}.pub"

    current_key_pair = aws_connection.key_pairs.get(ec2_key_pair_name)
    if current_key_pair
      puts "Using existing '#{ec2_key_pair_name}' keypair"
    else
      puts "Creating '#{ec2_key_pair_name}' keypair, uploading #{public_key_local_path} to aws"

      aws_connection.key_pairs.new(
        :name => ec2_key_pair_name,
        :public_key => File.read(File.expand_path("#{public_key_local_path}"))
      ).save
    end
    
    number_of_servers = aws_connection.servers.select{ |server| server.state == 'running' }.length
    puts "you have #{number_of_servers} server(s) already running in this account" if number_of_servers > 0
    
    puts "Launching server... (this costs money until you stop it)"
    server = aws_connection.servers.create(
      :image_id => 'ami-d4de25bd',
      :flavor_id =>  server_config['flavor_id'] || 'm1.large',
      :key_name => ec2_key_pair_name,
      :groups => [security_group_name]
    )
    
    unless aws_conf['server']['elastic_ip'] =~ /\d.\.\d.\.\d.\.\d./
      elastic_ip = aws_connection.addresses.create
      aws_conf['server']['elastic_ip'] = elastic_ip.public_ip
      puts "Allocated elastic IP address #{aws_conf['server']['elastic_ip']}"
    end
    
    server.wait_for { ready? }
    
    aws_connection.associate_address(server.id, aws_conf['server']['elastic_ip'])
    
    socket = false
    Timeout::timeout(120) do
      p "Server booted, waiting for SSH."
      until socket
        begin
          socket = TCPSocket.open(aws_conf['server']['elastic_ip'], 22)
        rescue Errno::ECONNREFUSED
          STDOUT << "."
          STDOUT.flush
          sleep 1
        end
      end
    end

    p server
    puts "Server is ready"
    
    p "Writing server instance_id(#{server.id}) and elastic IP(#{aws_conf['server']['elastic_ip']}) to ci.yml"
    aws_conf["server"].merge!("instance_id" => server.id)
    
    f = File.open(aws_conf_location, "w")
    f.write(aws_conf.to_yaml)
    f.close
  end
  
  desc "stop(suspend) the CI Server"
  task :stop do
    require 'fog'
    require 'yaml'
    require 'socket'

    aws_conf_location = File.join(Dir.pwd, 'config', 'ci.yml')
    aws_conf = YAML.load_file(aws_conf_location)
    aws_credentials = aws_conf['credentials']
    server_config = aws_conf['server']

    aws_connection = Fog::Compute.new(
      :provider => aws_credentials['provider'],
      :aws_access_key_id => aws_credentials['aws_access_key_id'],
      :aws_secret_access_key => aws_credentials['aws_secret_access_key']
    )
    
    aws_connection.servers.new(:id => server_config['instance_id']).stop
  end
  
  desc "start(resume) the CI Server"
  task :start do
    require 'fog'
    require 'yaml'
    require 'socket'

    aws_conf_location = File.join(Dir.pwd, 'config', 'ci.yml')
    aws_conf = YAML.load_file(aws_conf_location)
    aws_credentials = aws_conf['credentials']
    server_config = aws_conf['server']

    aws_connection = Fog::Compute.new(
      :provider => aws_credentials['provider'],
      :aws_access_key_id => aws_credentials['aws_access_key_id'],
      :aws_secret_access_key => aws_credentials['aws_secret_access_key']
    )
    
    server = aws_connection.servers.new(:id => server_config['instance_id'])
    # server.start
    server.wait_for { ready? }
    
    aws_connection.associate_address(server_config['instance_id'], server_config['elastic_ip']) if server_config['elastic_ip']
  end
  
  desc "open the CI interface in a browser"
  task :open do
    aws_conf_location = File.join(Dir.pwd, 'config', 'ci.yml')
    aws_conf = YAML.load_file(aws_conf_location)
    server_config = aws_conf['server']
    exec "open http://#{server_config['elastic_ip']}"
  end
  
  desc "ssh to CI"
  task :ssh do
    aws_conf_location = File.join(Dir.pwd, 'config', 'ci.yml')
    aws_conf = YAML.load_file(aws_conf_location)
    server_config = aws_conf['server']
    exec "ssh -i #{aws_conf['ec2_server_access']['id_rsa_path']} #{aws_conf['app_user']}@#{server_config['elastic_ip']}"
  end
  
  desc "Get build status"
  task :status do
    require 'nokogiri'
    aws_conf_location = File.join(Dir.pwd, 'config', 'ci.yml')
    ci_conf = YAML.load_file(aws_conf_location)
    
    jenkins_rss_feed = `curl -s --user #{ci_conf['basic_auth'][0]['username']}:#{ci_conf['basic_auth'][0]['password']} --anyauth http://#{ci_conf['server']['elastic_ip']}/rssAll`
    latest_build = Nokogiri::XML.parse(jenkins_rss_feed.downcase).css('feed entry:first').first
    status = !!(latest_build.css("title").first.content =~ /success|stable|back to normal/)
    if status
      p "Great Success"
    else
      p "Someone needs to fix the build"
    end
    status ? exit(0) : exit(1)
  end
end
