# Documentatie Ansible (Team 3)

In deze documentatie gaan wij onze configuratie laten zien van ansible in onze cluster.

## Vagrantfile 

In de vagrantfile wordt er meegegeven dat er 3 CentOS virtuele machines moeten aangemaakt worden in onze omgeving, namelijk 1 server en 2 agents. We starten even met een shell script om Ansible te gaan installeren en te kunnen gebruiken voor de installaties op de Virtuele machines. Hierna maken we de server VM aan en geven we deze een IP mee (192.168.1.2). In deze server gaan we een Ansible provision schrijven. Hier geven we de config file, de playbook en de host/group vars mee. De configuratie van deze specifieke files zullen worden aangehaald verder in deze README. Voor de 2 Agents is in principe hetzelfde van toepassing, alleen dat we natuurlijk een ander playbook en andere host/group vars meegeven, namelijk die van de agents.

```
# -*- mode: ruby -*-
# vi: set ft=ruby :
VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vbguest.auto_update = false
  config.vm.provision "shell", path: "installAnsible.sh"
  config.vm.box = "centos/7"

  config.vm.define "server" do |server|
    server.vm.hostname = "SERVER"
    server.vm.network "private_network", ip: "192.168.1.2"
	
	server.vm.provision "ansible_local" do |ansible|
      ansible.config_file = "ansible/ansible.cfg"
      ansible.playbook = "ansible/plays/server.yml"
      ansible.groups = {
        "servers" => ["server"],
#        "servers:vars" => {"crond__content" => "servers_value"}
      }
      ansible.host_vars = {
#        "server" => {"crond__content" => "server_value"}
      }
#      ansible.verbose = '-vvv'
    end
  end

  config.vm.define "agent1" do |agent1|
    agent1.vm.hostname = "AGENT1"
    agent1.vm.network "private_network", ip: "192.168.1.3"
	
	agent1.vm.provision "ansible_local" do |ansible|
      ansible.config_file = "ansible/ansible.cfg"
      ansible.playbook = "ansible/plays/agent.yml"
      ansible.groups = {
        "agents" => ["agent1"],
#        "agents:vars" => {"crond__content" => "agents_value"}
      }
      ansible.host_vars = {
#        "agent1" => {"crond__content" => "agent1_value"}
      }
#      ansible.verbose = '-vvv'
    end
  end

  config.vm.define "agent2" do |agent2|
    agent2.vm.hostname = "AGENT2"
    agent2.vm.network "private_network", ip: "192.168.1.4"
	
	agent2.vm.provision "ansible_local" do |ansible|
      ansible.config_file = "ansible/ansible.cfg"
      ansible.playbook = "ansible/plays/agent.yml"
      ansible.groups = {
        "agents" => ["agent2"],
#        "agents:vars" => {"crond__content" => "agents_value"}
      }
      ansible.host_vars = {
#        "agent2" => {"crond__content" => "agent2_value"}
      }
#      ansible.verbose = '-vvv'
    end
  end
  
  config.vm.provider :virtualbox do |virtualbox, override|
    virtualbox.customize ["modifyvm", :id, "--memory", 2048]
  end
  
  config.vm.provider :lxc do |lxc, override|
    override.vm.box = "visibilityspots/centos-7.x-minimal"
  end

end
```

## Ansible script

Omdat Ansible niet verkrijgbaar is op Windows hebben we gekozen om lokaal in de VM Ansible te gaan installeren zodat we Ansible tasks en dergelijke kunnen uitvoeren.

```
#!/bin/bash

sudo yum install epel-release -y
sudo yum install ansible -y
```

## Server playbook

In een Ansible playbook geef je simpelweg Ansible configuratie en deployment mee, in ons geval deployen wij 3 software roles die geinstalleerd moeten worden op de virtuele machine van de server VM. Ook geven we mee met 'become' dat de Ansible playbook hogere rechten verkrijgt voor de installaties.

```
---
- name: playbook for server vm
  hosts: servers
  become: yes

  roles:
    - role: software/consul
    - role: software/docker
    - role: software/nomad
```

## Agent playbook

De agent playbook is hetzelfde alleen dat bij hosts 'servers' aangepast moet worden naar 'agents' zodat we kunnen aangeven in de vagrantfile dat het om een agent gaat en niet een server VM.

```
---
- name: playbook for agent vm
  hosts: agents
  become: yes

  roles:
    - role: software/consul
    - role: software/docker
    - role: software/nomad
```

## Taakverdeling

Tijdens het maken van de opdracht hebben wij voor het grootste gedeelte samengewerkt met behulp van screensharen op Teams.

## Bronvermelding

Slides Lessen

https://docs.ansible.com/ansible/latest/collections/ansible/builtin/service_module.html

https://docs.ansible.com/ansible/latest/scenario_guides/guide_vagrant.html

https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html
