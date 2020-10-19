#!/bin/bash

sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

sudo yum install nomad -y

sudo rm -f /etc/nomad.d/nomad.hcl

cat << EOCCF >/etc/nomad.d/agent2.hcl
bind_addr = "192.168.1.0"

# Increase log verbosity
log_level = "DEBUG"

# Setup data dir
data_dir = "/opt/nomad/agent2"

# Give the agent a unique name. Defaults to hostname
name = "agent2"

# Enable the client
client {
    enabled = true
}

# Modify our port to avoid a collision with server
ports {
    http = 5657
}
EOCCF

systemctl start nomad