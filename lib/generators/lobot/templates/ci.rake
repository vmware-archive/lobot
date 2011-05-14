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
      security_group.authorize_port_range(port..port) unless is_in_security_group(security_group, port)
    end

    aws_connection.key_pairs.new(:name => "ci", :public_key => File.read(ID_RSA_LOCATION)).save unless aws_connection.key_pairs.get('ci')

    p "Launching server..."
    server = aws_connection.servers.create(
      :image_id => 'ami-e67e8d8f',
      :flavor_id =>  'm1.large',
      :key_name => 'ci'
    )
    server.wait_for { ready? }
    
    p server
    p "Server is ready"
    
    p "Writing server public IP (#{server.dns_name}) to ci.yml"
    aws_conf.merge!("ci_server" => { "public_ip" => server.dns_name })

    f = File.open(aws_conf_location, "w")
    f.write(aws_conf.to_yaml)
    f.close
  end
  
  desc "open the CI interface in a browser"
  task :open do
    aws_conf_location = File.expand_path('../../../config/ci.yml', __FILE__)
    aws_conf = YAML.load_file(aws_conf_location)
    exec "open http://#{aws_conf['ci_server']['public_ip']}"
  end
  
  desc "ssh to CI"
  task :ssh do
    aws_conf_location = File.expand_path('../../../config/ci.yml', __FILE__)
    aws_conf = YAML.load_file(aws_conf_location)
    exec "ssh #{aws_conf['app_user']}@#{aws_conf['ci_server']['public_ip']}"
  end
  
  desc "Get build status"
  task :status do
    require 'nokogiri'
    ci_conf_location = File.expand_path('../../../config/ci.yml', __FILE__)
    ci_conf = YAML.load_file(ci_conf_location)
    
    hudson_rss_feed = `curl -s --user #{ci_conf['basic_auth'][0]['username']}:#{ci_conf['basic_auth'][0]['password']} --anyauth http://#{ci_conf['ci_server']['public_ip']}/rssAll`
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