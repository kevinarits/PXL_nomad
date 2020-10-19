#!/bin/bash

curl -O https://releases.hashicorp.com/nomad/0.12.5/nomad_0.12.5_linux_amd64.zip
unzip nomad_0.12.5_linux_amd64.zip
mv nomad /usr/bin/

mkdir -p /etc/nomad.d

cat << EOCCF >/etc/nomad.d/server.hcl
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

systemctl daemon-reload
systemctl start nomad