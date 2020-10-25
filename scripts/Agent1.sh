#!/bin/bash

sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

sudo yum install nomad -y
sudo yum install consul -y

sudo rm -f /etc/nomad.d/nomad.hcl
sudo rm -f /etc/consul.d/consul.hcl

cat << EOCCF >/etc/nomad.d/agent1.hcl
bind_addr = "192.168.1.2"

# Increase log verbosity
log_level = "DEBUG"

# Setup data dir
data_dir = "/opt/nomad/agent1"

# Give the agent a unique name. Defaults to hostname
name = "agent1"

# Enable the client
client {
    enabled = true
}

EOCCF


cat << EOCCF >/etc/consul.d/agent1.hcl
data_dir = "/opt/consul/agent1"

client_addr = "0.0.0.0"

log_level = "DEBUG"

retry_join = ["192.168.1.1"]

ui = true

bind_addr = "192.168.1.2"
EOCCF

systemctl start nomad
systemctl start consul