Vagrant::Config.run do |config|
  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/#{config.vm.box}.box"
  config.vm.network :hostonly, "192.168.33.10"

  config.vm.provision :shell, :inline => "sudo mkdir /etc/skel/.ssh"

  config.vm.provision :shell do |shell|
    shell.inline = "echo $@ | sudo tee /etc/skel/.ssh/authorized_keys"
    ssh_key = File.join(File.dirname(__FILE__), 'spec', 'fixtures', 'ssh_keys', 'vagrant_test_key.pub')
    shell.args = File.read(ssh_key)
  end

  config.vm.provision :shell, :inline => "sudo useradd -m ubuntu -G sudo,admin -s /bin/bash"
end