#!/bin/bash -x

echo "Building Harbor Virtual Appliance ..."
rm -f output-vmware-iso/*

packer build -var-file=harbor-appliance-builder.json -var-file=harbor-version.json -var-file=harbor-appliance-version.json harbor-appliance.json

