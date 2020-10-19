#!/bin/bash

sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

sudo yum install nomad -y

sudo rm -f /etc/nomad.d/nomad.hcl

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

systemctl start nomad