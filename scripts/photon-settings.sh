#!/bin/bash -eux

##
## Misc configuration
##

echo '> Disable IPv6'
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf

echo '> Applying latest Updates...'
tdnf -y update

echo '> Installing Additional Packages...'
tdnf install -y \
  parted \
  less \
  logrotate \
  curl \
  wget \
  unzip \
  awk \
  tar \
  openssl-c_rehash \

echo '> Installing Docker Compose...'
curl -L "https://github.com/docker/compose/releases/download/1.28.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Bitnami Charts Syncer
echo '> Installing Charts Syncer...'
wget -O /tmp/charts-syncer.tar.gz https://github.com/bitnami-labs/charts-syncer/releases/download/v0.9.0/charts-syncer_0.9.0_linux_x86_64.tar.gz
tar -xzvf /tmp/charts-syncer.tar.gz -C /tmp
rm -rf /tmp/charts-syncer.tar.gz
chmod +x /tmp/charts-syncer
mv /tmp/charts-syncer /usr/local/bin

echo '> Installing Carvel tools...'
curl -L https://carvel.dev/install.sh | bash

echo '> Installing yq...'

wget https://github.com/mikefarah/yq/releases/download/v4.4.1/yq_linux_amd64 -O /usr/bin/yq
chmod +x /usr/bin/yq

echo '> Enable Docker in Systemd'
systemctl enable docker

echo '> Done'
