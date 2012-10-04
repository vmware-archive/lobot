namespace :ci do
  desc "Spin up CI server on amazon"
  task :create_server do
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

    PORTS_TO_OPEN = [22, 443, 80, 8111 ] + (9000...9010).to_a
    PORTS_TO_OPEN.each do |port|
      is_in_security_group = !!security_group.ip_permissions.detect{|group| (group['fromPort']..group['toPort']).include?(port) && group['ipRanges'].detect{|range| range["cidrIp"]== "0.0.0.0/0" } }

      unless is_in_security_group
        puts "Allowing port #{port} into '#{security_group_name}' security group"
        security_group.authorize_port_range(port..port)
      end
    end

    ec2_key_pair_name = ec2_server_access['key_pair_name'] || "ci"
    public_key_local_path = File.expand_path("#{ec2_server_access['id_rsa_path']}.pub")

    current_key_pair = aws_connection.key_pairs.get(ec2_key_pair_name)
    if current_key_pair
      puts "Using existing '#{ec2_key_pair_name}' keypair"
    else
      raise "Unable to upload keypair, missing #{public_key_local_path}!" unless File.exist?(public_key_local_path)
      puts "Creating '#{ec2_key_pair_name}' keypair, uploading #{public_key_local_path} to aws"

      aws_connection.key_pairs.new(
        :name => ec2_key_pair_name,
        :public_key => File.read("#{public_key_local_path}")
      ).save
    end

    number_of_servers = aws_connection.servers.select{ |server| server.state == 'running' }.length
    puts "you have #{number_of_servers} server(s) already running in this account" if number_of_servers > 0

    puts "Launching server... (this costs money until you stop it)"
    server = aws_connection.servers.create(
      :image_id => 'ami-a29943cb',
      :flavor_id =>  server_config['flavor_id'] || 'c1.medium',
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
    Timeout.timeout(180) do
      print "Server booted, waiting for SSH to come up on #{aws_conf['server']['elastic_ip']}: "
      until socket
        begin
          Timeout.timeout(5) do
            socket = TCPSocket.open(aws_conf['server']['elastic_ip'], 22)
          end
        rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Timeout::Error, Errno::EHOSTUNREACH
        end
        putc "."
        sleep 1
      end
    end
    puts ""

    puts "Server is ready:"
    p server

    puts "Writing server instance_id(#{server.id}) and elastic IP(#{aws_conf['server']['elastic_ip']}) to ci.yml"
    aws_conf["server"].merge!("instance_id" => server.id)

    f = File.open(aws_conf_location, "w")
    f.write(aws_conf.to_yaml)
    f.close
  end

  desc "terminate the CI Server and release IP"
  task :destroy_server do
    puts "Terminating the CI Server and releasing IP..."
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

    aws_connection.release_address(aws_conf['server']['elastic_ip'])
    aws_connection.servers.new(:id => server_config['instance_id']).destroy
  end

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

  # desc "open the CI interface in a browser"
  # task :open do
  #   aws_conf_location = File.join(Dir.pwd, 'config', 'ci.yml')
  #   aws_conf = YAML.load_file(aws_conf_location)
  #   server_config = aws_conf['server']
  #   exec "open https://#{server_config['elastic_ip']}"
  # end
  # 
  # desc "ssh to CI"
  # task :ssh do
  #   aws_conf_location = File.join(Dir.pwd, 'config', 'ci.yml')
  #   aws_conf = YAML.load_file(aws_conf_location)
  #   server_config = aws_conf['server']
  #   ssh_port = server_config['ssh_port'] || 22
  #   cmd = "ssh -i #{aws_conf['ec2_server_access']['id_rsa_path']} ubuntu@#{server_config['elastic_ip']} -p #{ssh_port}"
  #   puts cmd
  #   exec cmd
  # end

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

  # desc "Run a command with a virtual frame buffer"
  # task :headlessly, :command do |task, args|
  #   # headless is your friend on linux - http://www.aentos.com/blog/easy-setup-your-cucumber-scenarios-using-headless-gem-run-selenium-your-ci-server
  #   begin
  #     Headless
  #   rescue NameError
  #     puts "Headless not available, did you add it to your Gemfile?"
  #     exit 1
  #   end
  #   unless args[:command]
  #     puts "Usage: rake ci:headlessly[command] <additional options>"
  #     exit 1
  #   end
  #   exit_code = 1
  #   Headless.ly(:display => 42) do |headless|
  #     begin
  #       command = args[:command].gsub(/^['"](.*)['"]$/, "\\1")
  #       system(command)
  #       exit_code = $?.exitstatus
  #     ensure
  #       headless.destroy
  #     end
  #   end
  #   exit exit_code
  # end

  #aliases
  desc "maybe"
  task "server:create" => "ci:create_server"
  task "server:start" => "ci:start_server"
  task "server:destroy" => "ci:destroy_server"
  task "server:stop" => "ci:stop_server"
end
