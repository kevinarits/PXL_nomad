#!/bin/bash

sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

sudo yum install nomad -y
sudo yum install consul -y

sudo rm -f /etc/nomad.d/nomad.hcl
sudo rm -f /etc/consul.d/consul.hcl

sudo mkdir /opt/nomad/agent1
sudo mkdir /opt/consul/agent1

cat << EOCCF >/etc/nomad.d/agent1.hcl
bind_addr = "192.168.1.3"

# Increase log verbosity
log_level = "DEBUG"

# Setup data dir
data_dir = "/opt/nomad/agent1"

# Give the agent a unique name. Defaults to hostname
name = "agent1"

# Enable the client
client {
    enabled = true
	servers = ["192.168.1.2:4647"]
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


cat << EOCCF >/etc/consul.d/agent1.hcl
data_dir = "/opt/consul/agent1"

client_addr = "0.0.0.0"

log_level = "DEBUG"

retry_join = ["192.168.1.2"]

ui = true

bind_addr = "192.168.1.3"
EOCCF

systemctl start nomad
systemctl start consul