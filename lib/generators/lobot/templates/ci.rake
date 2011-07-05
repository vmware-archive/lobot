namespace :ci do
  desc "Spin up CI server on amazon"
  task :server_start do
    require 'fog'
    require 'yaml'

    SECURITY_GROUP_NAME = "default"
    PORTS_TO_OPEN = [22, 443, 80]
    ID_RSA_LOCATION = '/Users/pivotal/.ssh/id_rsa.pub'

    aws_conf_location = File.expand_path('../../../config/ci.yml', __FILE__)
    aws_conf = YAML.load_file(aws_conf_location)
    aws_credentials = aws_conf['credentials']

    aws_connection = Fog::Compute.new(
      :provider => aws_credentials['provider'],
      :aws_access_key_id => aws_credentials['aws_access_key_id'],
      :aws_secret_access_key => aws_credentials['aws_secret_access_key']
    )

    security_group = aws_connection.security_groups.get(SECURITY_GROUP_NAME)

    def is_in_security_group(security_group, port)
      !!security_group.ip_permissions.detect{|group| (group['fromPort']..group['toPort']).include?(port) && group['ipRanges'].detect{|range| range["cidrIp"]== "0.0.0.0/0" } }
    end

    PORTS_TO_OPEN.each do |port|
      unless is_in_security_group(security_group, port)
        puts "Allowing port #{port} into '#{SECURITY_GROUP_NAME}' security group"
        security_group.authorize_port_range(port..port) 
      end
    end

    current_key_pair = aws_connection.key_pairs.get('ci')    
    if current_key_pair
      puts "Using existing 'ci' keypair"
    else
      puts "Creating 'ci' keypair, uploading #{aws_conf['ec2_server_access']['id_rsa_path']}.pub to aws"
      aws_connection.key_pairs.new(:name => "ci", :public_key => File.read(File.expand_path("#{aws_conf['ec2_server_access']['id_rsa_path']}.pub"))).save
    end
    
    number_of_servers = aws_connection.servers.select{ |server| server.state == 'running' }.length
    puts "you have #{number_of_servers} server(s) already running in this account" if number_of_servers > 0
    
    puts "Launching server... (this costs money until you stop it)"
    server = aws_connection.servers.create(
      :image_id => 'ami-d4de25bd',
      :flavor_id =>  'm1.large',
      :key_name => 'ci'
    )
    server.wait_for { ready? }
    sleep 15 # Server ready? seems to mean 'almost ready'.  Sleep value is arbitrary at the moment
        
    p server
    puts "Server is ready"
    
    p "Writing server public IP (#{server.dns_name}) to ci.yml"
    aws_conf.merge!("server" => { "name" => server.dns_name, "instance_id" => server.id })
    
    f = File.open(aws_conf_location, "w")
    f.write(aws_conf.to_yaml)
    f.close
  end
  
  desc "open the CI interface in a browser"
  task :open do
    aws_conf_location = File.expand_path('../../../config/ci.yml', __FILE__)
    aws_conf = YAML.load_file(aws_conf_location)
    exec "open http://#{aws_conf['server']['name']}"
  end
  
  desc "ssh to CI"
  task :ssh do
    aws_conf_location = File.expand_path('../../../config/ci.yml', __FILE__)
    aws_conf = YAML.load_file(aws_conf_location)
    exec "ssh #{aws_conf['app_user']}@#{aws_conf['server']['name']}"
  end
  
  desc "Get build status"
  task :status do
    require 'nokogiri'
    ci_conf_location = File.expand_path('../../../config/ci.yml', __FILE__)
    ci_conf = YAML.load_file(ci_conf_location)
    
    hudson_rss_feed = `curl -s --user #{ci_conf['basic_auth'][0]['username']}:#{ci_conf['basic_auth'][0]['password']} --anyauth http://#{ci_conf['server']['name']}/rssAll`
    latest_build = Nokogiri::XML.parse(hudson_rss_feed.downcase).css('feed entry:first').first
    status = !!(latest_build.css("title").first.content =~ /success|stable|back to normal/)
    if status
      p "Great Success"
    else
      p "Someone needs to fix the build"
    end
    status ? exit(0) : exit(1)
  end
end