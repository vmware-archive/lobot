namespace :ci do
  desc "stop(suspend) the CI Server"
  task :stop_server do
    puts "Stopping (suspending) the CI Server..."
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
  task :start_server do
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
    server.start
    server.wait_for { ready? }

    aws_connection.associate_address(server_config['instance_id'], server_config['elastic_ip']) if server_config['elastic_ip']
  end

  desc "Get build status"
  task :status do
    require 'nokogiri'
    aws_conf_location = File.join(Dir.pwd, 'config', 'ci.yml')
    ci_conf = YAML.load_file(aws_conf_location)

    jenkins_rss_feed = `curl --user #{ci_conf['basic_auth'][0]['username']}:#{ci_conf['basic_auth'][0]['password']} --anyauth --insecure https://#{ci_conf['server']['elastic_ip']}/rssAll`
    # jenkins_rss_feed = `curl -s --user #{ci_conf['basic_auth'][0]['username']}:#{ci_conf['basic_auth'][0]['password']} --anyauth --insecure https://#{ci_conf['server']['elastic_ip']}/rssAll`
    p jenkins_rss_feed
    if latest_build = Nokogiri::XML.parse(jenkins_rss_feed.downcase).css('feed entry:first').first
      title = latest_build.css("title").first.content
    else
      title = "not available yet"
    end
    status = !!(title =~ /success|stable|back to normal/)
    if status
      puts "Great Success (#{title})"
    else
      puts "Someone needs to fix the build (#{title})"
    end
    status ? exit(0) : exit(1)
  end

  desc "Print cimonitor and ccmenu setup information"
  task :info do
    ci_conf_location = File.join(Dir.pwd, 'config', 'ci.yml')
    ci_conf = YAML.load_file(ci_conf_location)

    if ci_conf['server']['elastic_ip']
      puts "CI Monitor Config:"
      puts "\tURL:\t\thttps://#{ci_conf['server']['elastic_ip']}/job/#{ci_conf['app_name']}/rssAll"
      puts "\tProject Type:\tHudson/Jenkins"
      puts "\tFeed Username:\t#{ci_conf['basic_auth'][0]['username']}"
      puts "\tFeed Password:\t#{ci_conf['basic_auth'][0]['password']}"
      puts "\t-- Lobot Setup --"
      puts "\tEC2 Instance ID:\t#{ci_conf['server']['instance_id']}"
      puts "\tEC2 Elastic IP Address:\t#{ci_conf['server']['elastic_ip']}"
      puts "\tEC2 Access Key ID:\t#{ci_conf['credentials']['aws_access_key_id']}"
      puts "\tEC2 Secret Access Key :\t#{ci_conf['credentials']['aws_secret_access_key']}"
      puts ""
      puts "CC Menu Config:"
      puts "\tURL:\thttps://#{ci_conf['basic_auth'][0]['username']}:#{ci_conf['basic_auth'][0]['password']}@#{ci_conf['server']['elastic_ip']}/cc.xml"
    else
      puts "EC2 instance information not available. Did you run rake ci:server_start?"
    end
  end
end
