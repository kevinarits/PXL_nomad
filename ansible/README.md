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

## Software roles (consul)
### Consul handlers

In de handler van consul geven we mee dat de service moet herstarten. Deze handler wordt later gebruikt in de task file na het enablen van de service.

```
---
- name: restart consul
  service:
    name: consul
    state: restarted
```

### Consul tasks

In de task van consul starten we met het toevoegen van de hashicorp repository, waarna we consul installeren. Vervolgens gaan we het script van consul toevoegen aan de hand van de template die later aan bod komt. We geven hierbij de juiste owner en groep mee met de juiste rechten. Tenslotte enablen we de service en geven we mee dat de consul handler uitgevoerd moet worden.

```
---
- name: add repo
  command: yum-config-manager --add-repo=https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

- name: install consul
  yum:
    name: consul
    state: installed
  
- name: add consul script
  template:
    src: consul.sh.j2
    dest: /etc/consul.d/consul.hcl
    owner: "consul"
    group: "consul"
    mode: u=rwx,g=r,o=r
  
- name: Enable service consul
  service:
    name: consul
    enabled: yes
  notify: restart consul
```

### Consul templates

In de template van consul geven we de configuratie mee die we in de consul.hcl file gaan stoppen. We starten eerst met het meegeven van de variabelen die voor alle vm's hetzelfde zijn zoals de data directory, het client adress, ui. We zorgen ook dat de vm het juiste bind adress meekrijgt. Daarna gaan we via een if condition kijken of de vm een server moet zijn of een client. Als het een server moet zijn, geven we mee dat de server variabele true moet zijn en dat we bootstrap_expect instellen op 1. Als het een client is geven we mee welke server deze moet proberen te joinen.

```
#!/bin/bash
# {{ ansible_managed }}


data_dir = "/opt/consul"
client_addr = "0.0.0.0"
ui = true
bind_addr = "{{ ansible_eth1.ipv4.address }}"


{% if ansible_hostname == 'SERVER' %}
server = true
bootstrap_expect = 1
{% else %}
retry_join = ["192.168.1.2"]
{% endif %}
```

## Software roles (docker)
### Docker handlers

In de handler van docker geven we mee dat de service moet herstarten. Deze handler wordt later gebruikt in de task file na het enablen van de service.

```
---
- name: restart docker
  service:
    name: docker
    state: restarted
```

### Docker tasks

In de task van docker starten we met het toevoegen van de hashicorp repository, waarna we alle juiste docker dependencies installeren. Daarna enablen we de service en geven we mee dat de docker handler uitgevoerd moet worden.

```
---
- name: add repo
  command: yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo

- name: install docker-ce
  yum:
    name: docker-ce
    state: installed
  
- name: install docker-ce-cli
  yum:
    name: docker-ce-cli
    state: installed

- name: install containerd.io
  yum:
    name: containerd.io
    state: installed
  
- name: Enable service docker
  service:
    name: docker
    enabled: yes  
  notify: restart docker
```

## Software roles (nomad)
### Nomad handlers

In de handler van nomad geven we mee dat de service moet herstarten. Deze handler wordt later gebruikt in de task file na het enablen van de service.

```
---
- name: restart nomad
  service:
    name: nomad
    state: restarted
```

### Nomad tasks

In de task van nomad starten we met het toevoegen van de hashicorp repository, waarna we nomad installeren. Vervolgens gaan we het script van nomad toevoegen aan de hand van de template die later aan bod komt. We geven hierbij de juiste owner en groep mee met de juiste rechten. Tenslotte enablen we de service en geven we mee dat de nomad handler uitgevoerd moet worden.

```
---
- name: add repo
  command: yum-config-manager --add-repo=https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
    
- name: install nomad
  yum:
    name: nomad
    state: installed
  
- name: add nomad script
  template:
    src: nomad.sh.j2
    dest: /etc/nomad.d/nomad.hcl
    owner: "root"
    group: "root"
    mode: u=rwx,g=r,o=r
  
- name: Enable service nomad
  service:
    name: nomad
    enabled: yes
  notify: restart nomad
```

### Nomad templates

In de template van consul geven we de configuratie mee die we in de nomad.hcl file gaan stoppen. We starten eerst met het meegeven van de variabelen die voor alle vm's hetzelfde zijn zoals de data directory en het log level. We zorgen ook dat de vm het juiste bind adress meekrijgt. Daarna gaan we via een if condition kijken of de vm een server moet zijn of een client. Als het een server moet zijn, geven we de juiste naam mee en geven we mee dat de server variabele true moet zijn en dat we bootstrap_expect instellen op 1. Als het een client is geven we mee welke server deze moet proberen te joinen, dat in client de enabled variabele true moet zijn, dat we de docker plugin goed meegeven en dat de naam van de juiste client wordt meegegeven.

```
#!/bin/bash
# {{ ansible_managed }}


bind_addr = "{{ ansible_eth1.ipv4.address }}"
log_level = "DEBUG"
data_dir = "/opt/nomad"


{% if ansible_hostname == 'SERVER' %}
name = "server"
server {
	enabled = true
	bootstrap_expect = 1
}
	
{% else %}
client {
	enabled = true
	servers = ["192.168.1.2"]
}
plugin "docker" {
	config {
		gc {
			dangling_containers {
				enabled = false
			}
		}
	}
}
	

{% if ansible_hostname == 'AGENT1' %}
name= "agent1"
{% endif %}
	

{% if ansible_hostname == 'AGENT2' %}
name= "agent2"
{% endif %}


{% endif %}
```

## Taakverdeling

Tijdens het maken van de opdracht hebben wij voor het grootste gedeelte samengewerkt met behulp van screensharen op Teams.

## Bronvermelding

Slides Lessen

https://docs.ansible.com/ansible/latest/collections/ansible/builtin/service_module.html

https://docs.ansible.com/ansible/latest/scenario_guides/guide_vagrant.html

https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html
