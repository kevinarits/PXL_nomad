Vagrant.configure("3") do |config|
  config.vm.provision "shell", inline: "hostname"
  config.vm.box = "centos/7"

  config.vm.define "server" do |server|
    server.vm.hostname = "SERVER"
    server.vm.provision "shell", path: "scripts/nomadServer.sh"
	server.vm.network "private_network", ip: "192.168.1.1"
  end

  config.vm.define "agent1" do |agent1|
    agent1.vm.hostname = "AGENT1"
    agent1.vm.provision "shell", path: "scripts/nomadAgent1.sh"
	agent1.vm.network "private_network", ip: "192.168.1.2"
  end

  config.vm.define "agent2" do |agent2|
    agent2.vm.hostname = "AGENT2"
    agent2.vm.provision "shell", path: "scripts/nomadAgent2.sh"
	agent2.vm.network "private_network", ip: "192.168.1.3"
  end
  
  config.vm.provider :virtualbox do |virtualbox, override|
    virtualbox.customize ["modifyvm", :id, "--memory", 2048]
  end
  
  config.vm.provider :lxc do |lxc, override|
    override.vm.box = "visibilityspots/centos-7.x-minimal"
  end
  
  config.vm.provision "shell", path: "scripts/docker.sh"
  config.vm.provision "shell", path: "scripts/consul.sh"
end
