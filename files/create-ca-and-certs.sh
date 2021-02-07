#!/bin/bash

# Define specifics for this CA
CA_NAME=platform_ca
CA_CERT_SUBJ='/C=US/ST=California/L=Palo Alto/O=ACME/OU=ACME/CN=Harbor'

CERT_NAME=TO_BE_REPLACED
CERT_CSR_SUBJ='/C=US/ST=California/L=Palo Alto/O=ACME/OU=ACME/CN=TO_BE_REPLACED'

mkdir /root/certs
cd /root/certs
# Clean up old entries - omit this if you will be creating several certs from the same CA
rm *.csr *.pem *.crt *.cert *.key certindex* serial* *.conf
rm -rf ./ca
rm -rf ./cert
# Serial holds the next available cert serial number and is updated after each cert gen
echo "000a" > serial

# The CA records the certificates it signs here
touch certindex

# Create folder structure
mkdir ./ca
mkdir ./cert
# Create a self-signed root certificate
# NOTE: -nodes eliminates a passphrase; for infrastructure nodes
# NOTE: omit this line if you will be using the same CA to sign more certificates
eval "openssl req \
      -newkey rsa:2048 -keyout ./ca/${CA_NAME}.key \
      -x509 -days 3650 -nodes -out ./ca/${CA_NAME}.crt \
      -subj \"$CA_CERT_SUBJ\""

# Create a wildcard certificate signing request
eval "openssl req \
      -newkey rsa:1024 -keyout ./cert/${CERT_NAME}.key \
      -nodes -out ./cert/${CERT_NAME}.csr \
      -subj \"$CERT_CSR_SUBJ\""

# create an openssl.cfg for this CA used when signing the CSR
cat > ./ca/$CA_NAME.conf <<__EOF__
[ ca ]
default_ca = $CA_NAME

[ $CA_NAME ]
unique_subject = no
new_certs_dir = .
certificate = ./ca/${CA_NAME}.crt
database = certindex
private_key = ./ca/${CA_NAME}.key
serial = serial
default_days = 3650
default_md = sha1
policy = ${CA_NAME}_policy
x509_extensions = ${CA_NAME}_extensions

[ ${CA_NAME}_policy ]
commonName = supplied
stateOrProvinceName = supplied
countryName = supplied
emailAddress = optional
organizationName = supplied
organizationalUnitName = optional

[ ${CA_NAME}_extensions ]
basicConstraints = CA:false
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always
keyUsage = digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth,clientAuth

__EOF__

# Sign the generated certificates with the new CA. 
# This will produce a file called CERT_NAME.cert in the current directory.
# It will also create new versions of the serial and certindex files, 
# moving the old versions to backup files. A .pem file will also be 
# created based on the serial number in the serial file - identical to CERT_NAME.cert
# NOTE: Batch mode automatically certifies any CSRs passed in, without prompting.
eval "openssl ca -batch -config ./ca/${CA_NAME}.conf -notext -in ./cert/${CERT_NAME}.csr -out ./cert/${CERT_NAME}.crt"

# Create a .pem file for use with SSL off-loading on the host server (HAProxy)
cat ./cert/${CERT_NAME}.crt ./cert/${CERT_NAME}.key > ./cert/${CERT_NAME}.pem


