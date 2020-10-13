#!/bin/bash

curl -O https://releases.hashicorp.com/nomad/0.12.5/nomad_0.12.5_linux_amd64.zip
unzip nomad_0.12.5_linux_amd64.zip
mv nomad /usr/bin/

nomad agent -dev