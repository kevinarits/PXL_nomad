#!/bin/bash

curl -O https://releases.hashicorp.com/nomad/0.12.5/nomad_0.12.5_linux_amd64.zip
unzip nomad_0.12.5_linux_amd64.zip
mv nomad /usr/bin/

mkdir -p /etc/nomad.d

cat << EOCCF >/etc/consul.d/agent2.hcl
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

systemctl daemon-reload
systemctl start nomad