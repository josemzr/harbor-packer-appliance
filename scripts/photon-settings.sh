#!/bin/bash -eux

##
## Misc configuration
##

echo '> Disable IPv6'
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf

echo '> Update package repos to VMware'
sed  -i 's/dl.bintray.com\/vmware/packages.vmware.com\/photon\/$releasever/g' /etc/yum.repos.d/photon.repo /etc/yum.repos.d/photon-updates.repo /etc/yum.repos.d/photon-extras.repo /etc/yum.repos.d/photon-debuginfo.repo

echo '> Applying latest Updates...'
tdnf -y update

echo '> Installing Additional Packages...'
tdnf install -y \
  less \
  logrotate \
  curl \
  wget \
  unzip \
  awk \
  tar \

echo '> Installing Docker Compose...'
curl -L "https://github.com/docker/compose/releases/download/1.28.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo '> Installing yq...'

wget https://github.com/mikefarah/yq/releases/download/v4.4.1/yq_linux_amd64 -O /usr/bin/yq
chmod +x /usr/bin/yq

echo '> Enable Docker in Systemd'
systemctl enable docker

echo '> Done'
