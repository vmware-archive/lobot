# app_name
A short name for your application.  This will be used as the name of the build in jenkins.

# app_user
The user created to run jenkins.  This can be set to the same value as app_name if desired.

# git_location
The location of your remote git repository which Jenkins will poll and pull from on changes.  If it's a public project, use the http://github.com/user/project.git url.  If it's a private project, use the ssh form, git@github.com:user/project.git.

# basic_auth:
	- username: # The username you will use to access the Jenkins web interface
	  password: # The password you will use to access the Jenkins web interface
The basic auth field is an array of hashes containing the usernames and passwords you would like to be able to access jenkins.

# credentials:
Currently Lobot only supports managing EC2 servers. To start a new instance, the rake task needs to be able to connect to ec2 and ask it to launch a server.
##  aws_access_key_id:
The Access Key for your Amazon AWS account.  You can obtain it by visiting 
https://aws-portal.amazon.com/gp/aws/developer/account/index.html?ie=UTF8&action=access-key
##  aws_secret_access_key: The Secret Access Key for your Amazon AWS account
This will be available at the same URL.
##  provider: AWS
This tells Lobot to use Amazon web services.  Currently AWS is the only valid value.

# server:
The server section is where Lobot keeps track of the instance that it launches when you run rake ci:server_start
##  name:
The name is the server's machine name - either ip address or DNS name.  Usually you'll just run ci:server_start to populate it.
#  instance_id:
The instance_id is also saved, in order to facilitate stopping and starting instances.  Stopping" is AWS's term for shutting down an instance temporarily - when it is started, it will use the same EBS volume and continue where it left off.  However, it will receive a new ip address and DNS name.

# build_command: ./script/ci_build.sh
The build command is the shell script that Jenkins will execute to run your build.  While you could put this script is the Jenkins configuration, it's clearer to have it in a script directly checked into your project.

# ec2_server_access: 
	key_pair_name: myapp_ci
	id_rsa_path: ~/.ssh/id_rsa

The EC2 server access section is perhaps the most confusing field in the ci.yml file. This section tells Lobot what ssh keys to use to access the servers it spins up.  When you run rake ci:sever_start, Lobot first looks in your ec2 account to see if they key pair name you specified exists - if it doesn't, it uploads the specified #{id_rsa_path}.pub to amazon, and names it #{key_pair_name}.  It then launches the server, telling EC2 to use the key pair specified.

# id_rsa_for_github_access
id_rsa_for_github_access: |-
  -----BEGIN RSA PRIVATE KEY-----
  SSH KEY WITH ACCESS TO GITHUB GOES HERE
  -----END RSA PRIVATE KEY-----

This is the rsa key that jenkins will use when connecting to github. Note that it is indented as it's a multiline markdown string.