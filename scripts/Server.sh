#!/bin/bash

sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

sudo yum install nomad -y
sudo yum install consul -y

sudo rm -f /etc/nomad.d/nomad.hcl
sudo rm -f /etc/consul.d/consul.hcl

sudo mkdir /opt/nomad/server
sudo mkdir /opt/consul/server

cat << EOCCF >/etc/nomad.d/server.hcl
bind_addr = "192.168.1.2"

# Increase log verbosity
log_level = "DEBUG"

# Setup data dir
data_dir = "/opt/nomad/server"

# Give the agent a unique name. Defaults to hostname
name = "server"

# Enable the server
server {
  enabled = true

  # Self-elect, should be 3 or 5 for production
  bootstrap_expect = 1
}
EOCCF

cat << EOCCF >/etc/consul.d/server.hcl
data_dir = "/opt/consul/server"

client_addr = "0.0.0.0"

log_level = "DEBUG"

ui = true

bind_addr = "192.168.1.2"

server = true

bootstrap_expect=1

EOCCF

systemctl start nomad
systemctl start consul