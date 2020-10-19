Vagrant.configure("3") do |config|
  config.vm.provision "shell", inline: "hostname"
  config.vm.box = "centos/7"
  config.vm.provision "shell", path: "scripts/consul.sh"
  config.vm.provision "shell", path: "scripts/docker.sh"

  config.vm.define "server" do |server|
    server.vm.hostname = "SERVER"
    server.vm.provision "shell", path: "scripts/nomadServer.sh"
  end

  config.vm.define "agent1" do |agent1|
    agent1.vm.hostname = "AGENT1"
    agent1.vm.provision "shell", path: "scripts/nomadAgent1.sh"
  end
  
  config.vm.provider :lxc do |lxc, override|
    override.vm.box = "visibilityspots/centos-7.x-minimal"
  end
  
  config.vm.provider :virtualbox do |virtualbox, override|
    virtualbox.customize ["modifyvm", :id, "--memory", 2048]
  end

  config.vm.define "agent2" do |agent2|
    agent2.vm.hostname = "AGENT2"
    agent2.vm.provision "shell", path: "scripts/nomadAgent2.sh"
  end
  config.vm.provision "shell", path: "scripts/docker.sh"
  config.vm.provision "shell", path: "scripts/consul.sh"
end
