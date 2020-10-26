# Nomad consul (Team 3)

The aim of this project is to provide a development environment based on [consul](https://www.consul.io) and [nomad](https://www.nomadproject.io) to manage container based microservices.

The following steps should make that clear;

bring up the environment by using [vagrant](https://www.vagrantup.com) which will create centos 7 virtualbox machine or lxc container.

The proved working vagrant providers used on an [ArchLinux](https://www.archlinux.org/) system are
* [vagrant-lxc](https://github.com/fgrehm/vagrant-lxc)
* [vagrant-libvirt](https://github.com/vagrant-libvirt/)
* [virtualbox](https://www.virtualbox.org/)

```bash
    $ vagrant up --provider lxc
    OR
    $ vagrant up --provider libvirt
    OR
    $ vagrant up --provider virtualbox
```

Once it is finished, you should be able to connect to the vagrant environment through SSH and interact with Nomad:

```bash
    $ vagrant ssh
    [vagrant@nomad ~]$
```

# Documentatie

In deze documentatie gaan wij onze configuratie laten zien voor onze nomad/consul cluster.

## Vagrantfile 

In vagrantfile wordt de standaard configuratie meegegeven voor het aanmaken van de centos7 VMs. Hier worden 3 VMs aangemaakt, namelijk 1 server en 2 agents. Per VM is er een specifiek script meegegeven die wordt uitgevoerd bij het aanmaken van de VM. Ook wordt er een specifiek ip meegegeven per VM.
Daarnaast worden er ook algemene scripts megegeven die worden uitgevoerd op alle VMs, dit zijn het docker en job script.

```
VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.provision "shell", inline: "hostname"
  config.vm.box = "centos/7"

  config.vm.define "server" do |server|
    server.vm.hostname = "SERVER"
    server.vm.provision "shell", path: "scripts/Server.sh"
    server.vm.network "private_network", ip: "192.168.1.2"
  end

  config.vm.define "agent1" do |agent1|
    agent1.vm.hostname = "AGENT1"
    agent1.vm.provision "shell", path: "scripts/Agent1.sh"
    agent1.vm.network "private_network", ip: "192.168.1.3"
  end

  config.vm.define "agent2" do |agent2|
    agent2.vm.hostname = "AGENT2"
    agent2.vm.provision "shell", path: "scripts/Agent2.sh"
    agent2.vm.network "private_network", ip: "192.168.1.4"
  end
  
  config.vm.provider :virtualbox do |virtualbox, override|
    virtualbox.customize ["modifyvm", :id, "--memory", 2048]
  end
  
  config.vm.provider :lxc do |lxc, override|
    override.vm.box = "visibilityspots/centos-7.x-minimal"
  end
  
  config.vm.provision "shell", path: "scripts/docker.sh"
  config.vm.provision "shell", path: "scripts/job.sh"
end
```

## Server script

Het eerste wat we hier doen is het binnenhalen van de hashicorp repository, hierin zitten nomad en consul die nodig zijn voor de installatie. Nadat beide zijn geïnstalleerd, zullen er al standaard files zijn aangemaakt waarin we de configuratie zouden moeten doen. Wij hebben de files verwijdert van nomad en zelf een nieuwe file aangemaakt.

We starten met de nomad configuratie in /etc/nomad.d/server.hcl die we zelf aangemaakt hebben. Hierin geven we het bind address mee dat ons ip van de server zelf is. Daarnaast geven we nog een data directory en naam mee. Tenslotte geven we aan dat dit een server moet zijn.

Nu gaan we de consul configuratie doen in /etc/consul.d/consul.hcl die we ook zelf hebben aangemaakt. Hierin geven we ook het bind address en een data directory mee. We geven  weer aan dat dit een server moet zijn. Ook geven we mee dat er een user interface moet zijn.

Tenslotte gaan we beide services opstarten met systemctl.

```
#!/bin/bash

sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

sudo yum install nomad -y
sudo yum install consul -y

sudo rm -f /etc/nomad.d/nomad.hcl


cat << EOCCF >/etc/nomad.d/server.hcl
bind_addr = "192.168.1.2"

# Increase log verbosity
log_level = "DEBUG"

# Setup data dir
data_dir = "/opt/nomad"

# Give the agent a unique name. Defaults to hostname
name = "server"

# Enable the server
server {
  enabled = true

  # Self-elect, should be 3 or 5 for production
  bootstrap_expect = 1
}
EOCCF

cat << EOCCF >/etc/consul.d/consul.hcl
data_dir = "/opt/consul"

client_addr = "0.0.0.0"

ui = true

server = true

bootstrap_expect=1

bind_addr = "192.168.1.2"

EOCCF

systemctl start nomad
systemctl start consul
```

## Agent1 script

De eerste stappen die we uitvoeren zijn hetzelfde. Het verandert pas vanaf dat we beginnen met de configuratie van nomad en consul. 

We starten nu in /etc/nomad.d/agent1.hcl voor de configuratie van nomad. Hier geven we weer het bind address, de data directory en een naam mee. Daarnaast geven we aan dat het een client is, waarbij we ook het ip van de server meegeven zodat deze bij de nomad cluster aansluit.

Voor de configuratie van consul werken we in /etc/consul.d/consul.hcl. Hier geven we weer het bind address, de data directory en het ip van de server die we willen joinen. we zorgen ook weer voor een user interface.

Nu gaan we weer beide services opstarten met systemctl.

```
#!/bin/bash

sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

sudo yum install nomad -y
sudo yum install consul -y

sudo rm -f /etc/nomad.d/nomad.hcl


cat << EOCCF >/etc/nomad.d/agent1.hcl
bind_addr = "192.168.1.3"

# Increase log verbosity
log_level = "DEBUG"

# Setup data dir
data_dir = "/opt/nomad"

# Give the agent a unique name. Defaults to hostname
name = "agent1"

# Enable the client
client {
    enabled = true
	servers = ["192.168.1.2"]
}

# Disable the dangling container cleanup to avoid interaction with other clients
plugin "docker" {
  config {
    gc {
      dangling_containers {
        enabled = false
      }
    }
  }
}

EOCCF


cat << EOCCF >/etc/consul.d/consul.hcl
data_dir = "/opt/consul"

client_addr = "0.0.0.0"

retry_join = ["192.168.1.2"]

ui = true

bind_addr = "192.168.1.3"
EOCCF

systemctl start nomad
systemctl start consul
```

## Agent2 script

Dit script is volledig hetzelde als het script van agent1, alleen zijn hier de naam en het bind address aangepast naar die van agent2.

```
#!/bin/bash

sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

sudo yum install nomad -y
sudo yum install consul -y

sudo rm -f /etc/nomad.d/nomad.hcl

cat << EOCCF >/etc/nomad.d/agent2.hcl
bind_addr = "192.168.1.4"

# Increase log verbosity
log_level = "DEBUG"

# Setup data dir
data_dir = "/opt/nomad"

# Give the agent a unique name. Defaults to hostname
name = "agent2"

# Enable the client
client {
    enabled = true
	servers = ["192.168.1.2"]
}

# Disable the dangling container cleanup to avoid interaction with other clients
plugin "docker" {
  config {
    gc {
      dangling_containers {
        enabled = false
      }
    }
  }
}

EOCCF

cat << EOCCF >/etc/consul.d/consul.hcl
data_dir = "/opt/consul"

client_addr = "0.0.0.0"

retry_join = ["192.168.1.2"]

ui = true

bind_addr = "192.168.1.4"

EOCCF

systemctl start nomad
systemctl start consul
```

## Job script

Hier maken we een eenvoudige webserver job aan. We maken eerst de map /opt/nomad/ aan, en hierin steken we onze job onder de naam job.nomad.

Dit script wordt uitgevoerd op alle VMs.

```
sudo mkdir /opt/nomad/
cat << EOCCF >/opt/nomad/job.nomad
job "webserver" {
  datacenters = ["dc1"]
  type = "service"
  
  group "webserver" {
  
    task "webserver" {
      driver = "docker"

      config {
        image = "httpd"
		force_pull = true
		port_map = {
		  webserver_web = 80
		} 
		logging {
		  type = "journald"
		  config {
		    tag = "WEBSERVER"
		 }
		}	
      }
	  
	  service {
	    name = "webserver"
	    port = "webserver_web"
	  } 

      resources {
        network {
          port "webserver_web" {
            static = "8000"
          }
        }
      }
    }
  }
}
EOCCF
```

## Docker script

Met dit script gaan we docker installeren. We halen eerst de juiste repo af zodat we docker kunnen installeren.
Daarna installeren we nog eerst de juiste dependecies. Tenslotte starten we docker op.

Ook dit script wordt uitgevoerd op alle VMs.

```
#!/bin/bash

yum install -y yum-utils
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

yum install -y docker-ce docker-ce-cli containerd.io

systemctl enable docker
systemctl start docker
```

## Nomad user interface

![LinuxPE1](https://user-images.githubusercontent.com/43812350/97183190-c0fc5a00-179d-11eb-8252-30ed350ed59c.png)


![LinuxPE2](https://user-images.githubusercontent.com/43812350/97183225-cfe30c80-179d-11eb-8561-de58ecbb4916.png)


![LinuxPE3](https://user-images.githubusercontent.com/43812350/97183255-d96c7480-179d-11eb-87a2-ee651aa3cd63.png)

## Bronvermelding

Slides Lessen

https://learn.hashicorp.com/collections/consul/getting-started

https://learn.hashicorp.com/collections/nomad/get-started

https://learn.hashicorp.com/tutorials/nomad/get-started-cluster?in=nomad/get-started
