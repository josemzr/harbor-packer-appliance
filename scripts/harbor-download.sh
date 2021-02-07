#!/bin/bash -eux

##
## Harbor download 
##

echo '> Downloading Harbor offline bundle...'
wget https://github.com/goharbor/harbor/releases/download/$HARBOR_VERSION/harbor-offline-installer-$HARBOR_VERSION.tgz -O /root/harbor.tgz

echo '> Extracting Harbor offline bundle...'
tar -xzvf /root/harbor.tgz && rm -rf /root/harbor.tgz
