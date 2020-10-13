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
    agent1.vm.provision "shell", path: "scripts/nomadAgent.sh"
  end

  config.vm.define "agent2" do |agent2|
    agent2.vm.hostname = "AGENT2"
    agent2.vm.provision "shell", path: "scripts/nomadAgent.sh"
  end
end
