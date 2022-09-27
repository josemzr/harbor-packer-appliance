#!/bin/bash

# Bootstrap script

set -euo pipefail

    HOSTNAME_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.hostname")
    IP_ADDRESS_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.ipaddress")
    NETMASK_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.netmask")
    GATEWAY_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.gateway")
    DNS_SERVER_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.dns")
    DNS_DOMAIN_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.domain")
    ROOT_PASSWORD_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.root_password")

    HOSTNAME=$(echo "${HOSTNAME_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    IP_ADDRESS=$(echo "${IP_ADDRESS_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    NETMASK=$(echo "${NETMASK_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}' | cut -d '(' -f 1)
    GATEWAY=$(echo "${GATEWAY_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    DNS_SERVER=$(echo "${DNS_SERVER_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    DNS_DOMAIN=$(echo "${DNS_DOMAIN_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    ROOT_PASSWORD=$(echo "${ROOT_PASSWORD_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')

    HARBOR_HOSTNAME_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.harbor_hostname")
    HARBOR_HTTPS_CERTIFICATE_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.harbor_https_certificate")
    HARBOR_HTTPS_PRIVATE_KEY_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.harbor_https_private_key")
    HARBOR_ADMIN_PASSWORD_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.harbor_admin_password")
    HARBOR_DB_PASSWORD_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.harbor_db_password")
    HARBOR_HTTP_PROXY_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.harbor_http_proxy")
    HARBOR_HTTPS_PROXY_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.harbor_https_proxy")
    HARBOR_NO_PROXY_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.harbor_no_proxy")
    ADD_TLS_CERTIFICATE_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.add_tls_certificate")

    HARBOR_HOSTNAME=$(echo "${HARBOR_HOSTNAME_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    HARBOR_HTTPS_CERTIFICATE=$(echo "${HARBOR_HTTPS_CERTIFICATE_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    HARBOR_HTTPS_PRIVATE_KEY=$(echo "${HARBOR_HTTPS_PRIVATE_KEY_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')  
    HARBOR_ADMIN_PASSWORD=$(echo "${HARBOR_ADMIN_PASSWORD_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    HARBOR_DB_PASSWORD=$(echo "${HARBOR_DB_PASSWORD_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    HARBOR_HTTP_PROXY=$(echo "${HARBOR_HTTP_PROXY_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    HARBOR_HTTPS_PROXY=$(echo "${HARBOR_HTTPS_PROXY_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    HARBOR_NO_PROXY=$(echo "${HARBOR_NO_PROXY_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    ADD_TLS_CERTIFICATE=$(echo "${ADD_TLS_CERTIFICATE_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')

configureHarbor(){

    echo -e "\e[92mConfiguring Harbor..." > /dev/console
    #Change default data volume to the newly created volume

    yq eval '.data_volume = "/mnt/harbor"' -i /root/harbor/harbor.yml.tmpl
    
    #If the Harbor Hostname variable is not set, configure it with the system hostname
    [ -z "${HARBOR_HOSTNAME}" ] && hostname=${HOSTNAME} yq eval '.hostname = env(hostname)' -i /root/harbor/harbor.yml.tmpl || harbor_hostname=${HARBOR_HOSTNAME} yq eval '.hostname = env(harbor_hostname)' -i /root/harbor/harbor.yml.tmpl    
    
    #Check if the Harbor Hostname is an IP address or DNS FQDN (useful to add SANs to the certificate)
    if [[ "$HARBOR_HOSTNAME" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]; then
    IP_SAN=1
  else
    IP_SAN=0
    fi
    
    #If HTTPS certificates aren't provided, generate self-signed certificates
    if [ -z "$HARBOR_HTTPS_CERTIFICATE" ] || [ -z "$HARBOR_HTTPS_PRIVATE_KEY" ]
    then
      [ -z "${HARBOR_HOSTNAME}" ] && sed -i "s#TO_BE_REPLACED#${HOSTNAME}#g" /root/create-ca-and-certs.sh || sed -i "s#TO_BE_REPLACED#${HARBOR_HOSTNAME}#g" /root/create-ca-and-certs.sh
    # Adding the appliance IP address as a SAN in the self-signed cert
    #If interface has DHCP, get IP address with ifconfig oneliner
    if [ -z "${IP_ADDRESS}" ]
    then
      IP_ADDRESS=$(ifconfig eth0 | grep 'inet addr' | awk -F'[: ]+' '{ print $4 }')
      sed -i "s#IP_ADDRESS_SAN_TBR#${IP_ADDRESS}#g" /root/create-ca-and-certs.sh
    fi
    #If interface has static, use the IP_ADDRESS property to add IP as SAN:
    sed -i "s#IP_ADDRESS_SAN_TBR#${IP_ADDRESS}#g" /root/create-ca-and-certs.sh
    # If the Harbor Hostname is an IP address, don't add a DNS SANs in the cert, just leave the IP address of the appliance. If it is a DNS FQDN, add it to the SANs.
      [ ${IP_SAN} = 0 ] && sed -i "s#HARBOR_HOSTNAME_SAN_TBR#${HARBOR_HOSTNAME}#g" /root/create-ca-and-certs.sh || sed -i "/HARBOR_HOSTNAME_SAN_TBR/d" /root/create-ca-and-certs.sh
      /root/create-ca-and-certs.sh
      CERT_NAME=$(grep -ri "CERT_NAME=" /root/create-ca-and-certs.sh | cut -f2 -d"=")
      CERT_PATH="/root/certs/cert/${CERT_NAME}.crt"
      CERT_KEY_PATH="/root/certs/cert/${CERT_NAME}.key"
      cert_path=${CERT_PATH} yq eval '.https.certificate = env(cert_path)' -i /root/harbor/harbor.yml.tmpl
      cert_key_path=${CERT_KEY_PATH} yq eval '.https.private_key = env(cert_key_path)' -i /root/harbor/harbor.yml.tmpl
    # Add the self-signed CA to the system store
      cp /root/certs/ca/platform_ca.crt /etc/ssl/certs
      /bin/rehash_ca_certificates.sh
    else
      mkdir /root/certs
      # Parsing the certificate from the OVF properties, as carriage returns are converted into spaces, so they need to be formatted
      echo ${HARBOR_HTTPS_CERTIFICATE} | sed -e 's/BEGIN /BEGIN_/g' -e 's/PRIVATE /PRIVATE_/g' -e 's/END /END_/g' -e 's/ /\n/g' -e 's/BEGIN_/BEGIN /g' -e 's/PRIVATE_/PRIVATE /g' -e 's/END_/END /g' > /root/certs/${HARBOR_HOSTNAME}.crt
      echo ${HARBOR_HTTPS_PRIVATE_KEY} | sed -e 's/BEGIN /BEGIN_/g' -e 's/PRIVATE /PRIVATE_/g' -e 's/END /END_/g' -e 's/ /\n/g' -e 's/BEGIN_/BEGIN /g' -e 's/PRIVATE_/PRIVATE /g' -e 's/END_/END /g' > /root/certs/${HARBOR_HOSTNAME}.key
      CERT_PATH="/root/certs/${HARBOR_HOSTNAME}.crt"
      CERT_KEY_PATH="/root/certs/${HARBOR_HOSTNAME}.key"
      cert_path=${CERT_PATH} yq eval '.https.certificate = env(cert_path)' -i /root/harbor/harbor.yml.tmpl
      cert_key_path=${CERT_KEY_PATH} yq eval '.https.private_key = env(cert_key_path)' -i /root/harbor/harbor.yml.tmpl      
    fi

    #Set Harbor initial password
    [ -z "${HARBOR_ADMIN_PASSWORD}" ] && yq eval '.harbor_admin_password = "Harbor12345"' -i /root/harbor/harbor.yml.tmpl || harbor_admin_password=${HARBOR_ADMIN_PASSWORD} yq eval '.harbor_admin_password = env(harbor_admin_password)' -i /root/harbor/harbor.yml.tmpl

    #Set Harbor DB password
    [ -z "${HARBOR_DB_PASSWORD}" ] && yq eval '.database.password = "root123"' -i /root/harbor/harbor.yml.tmpl || harbor_db_password=${HARBOR_DB_PASSWORD} yq eval '.database.password = env(harbor_db_password)' -i /root/harbor/harbor.yml.tmpl

    #Set Harbor proxy configuration
    
    [ -n "${HARBOR_HTTP_PROXY}" ] && harbor_http_proxy=${HARBOR_HTTP_PROXY} yq eval '.proxy.http_proxy = env(harbor_http_proxy)' -i /root/harbor/harbor.yml.tmpl
    [ -n "${HARBOR_HTTPS_PROXY}" ] && harbor_https_proxy=${HARBOR_HTTPS_PROXY} yq eval '.proxy.https_proxy = env(harbor_https_proxy)' -i /root/harbor/harbor.yml.tmpl
    [ -n "${HARBOR_NO_PROXY}" ] && harbor_no_proxy=${HARBOR_NO_PROXY} yq eval '.proxy.no_proxy = env(harbor_no_proxy)' -i /root/harbor/harbor.yml.tmpl

    #Install Harbor
    mv /root/harbor/harbor.yml.tmpl /root/harbor/harbor.yml
    /root/harbor/install.sh --with-trivy --with-chartmuseum --with-notary
    
    #Copy Harbor CA to /mnt/harbor/ca_download
    
    cp /root/certs/ca/platform_ca.crt /mnt/harbor/ca_download/ca.crt
    chmod 444 /mnt/harbor/ca_download/ca.crt
    
    #Enable Harbor as a Systemd Service

    cat > /etc/systemd/system/harbor.service << __HARBOR_SYSTEMD__
[Unit]
Description=Harbor Service
After=network.target docker.service

[Service]
Type=simple
WorkingDirectory=/root/harbor
ExecStart=/usr/local/bin/docker-compose -f /root/harbor/docker-compose.yml start
ExecStop=/usr/local/bin/docker-compose -f /root/harbor/docker-compose.yml stop
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
__HARBOR_SYSTEMD__

systemctl enable harbor
}

configureDataDisk() {
    echo -e "\e[92mConfiguring Harbor data disk ..." > /dev/console

    mkdir -p /mnt/harbor

    DISK=/dev/sdb
    printf "o\nn\np\n1\n\n\nw\n" | fdisk "${DISK}"
    mkfs.ext3 -L harbor "${DISK}1"
    mount -o defaults "${DISK}1" /mnt/harbor
    echo ""${DISK}1"     /mnt/harbor         ext3 defaults 0 2" >> /etc/fstab
}

configureDHCP() {
    echo -e "\e[92mConfiguring network using DHCP..." > /dev/console
    cat > /etc/systemd/network/${NETWORK_CONFIG_FILE} << __CUSTOMIZE_PHOTON__
[Match]
Name=e*

[Network]
DHCP=yes
IPv6AcceptRA=no
__CUSTOMIZE_PHOTON__
}

configureStaticNetwork() {

    echo -e "\e[92mConfiguring Static IP Address ..." > /dev/console
    cat > /etc/systemd/network/${NETWORK_CONFIG_FILE} << __CUSTOMIZE_PHOTON__
[Match]
Name=e*

[Network]
Address=${IP_ADDRESS}/${NETMASK}
Gateway=${GATEWAY}
DNS=${DNS_SERVER}
Domain=${DNS_DOMAIN}
__CUSTOMIZE_PHOTON__
}

configureHostname() {
    echo -e "\e[92mConfiguring hostname ..." > /dev/console
    [ -z "${HOSTNAME}" ] && HOSTNAME=harbor hostnamectl set-hostname harbor  || hostnamectl set-hostname ${HOSTNAME}
    echo "${IP_ADDRESS} ${HOSTNAME}" >> /etc/hosts
}

restartNetwork() {
    echo -e "\e[92mRestarting Network ..." > /dev/console
    systemctl restart systemd-networkd
}

configureRootPassword() {
    echo -e "\e[92mConfiguring root password ..." > /dev/console
    echo "root:${ROOT_PASSWORD}" | /usr/sbin/chpasswd
}

createCustomizationFlag() {
    # Ensure that we don't run the customization again
    touch /root/ran_customization
}

addCertStore() {
    # Adding additional TLS certificate to the system datastore in case it is needed (i.e to connect to an upstream HTTPS proxy for TLS introspection)
    echo -e "\e[92mAdding additional TLS certificate ..." > /dev/console
    if [ -n "${ADD_TLS_CERTIFICATE}" ]; then
        echo ${ADD_TLS_CERTIFICATE} | sed -e 's/BEGIN /BEGIN_/g' -e 's/PRIVATE /PRIVATE_/g' -e 's/END /END_/g' -e 's/ /\n/g' -e 's/BEGIN_/BEGIN /g' -e 's/PRIVATE_/PRIVATE /g' -e 's/END_/END /g' > /etc/ssl/certs/add_tls_cert.crt
        /bin/rehash_ca_certificates.sh
    else
        echo "Additional TLS certificate not present. Skipping..."
    fi
}

if [ -e /root/ran_customization ]; then
    exit
else
    NETWORK_CONFIG_FILE=$(ls /etc/systemd/network | grep .network)

    DEBUG_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.debug")
    DEBUG=$(echo "${DEBUG_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
    LOG_FILE=/var/log/bootstrap.log
    if [ ${DEBUG} == "True" ]; then
        LOG_FILE=/var/log/photon-customization-debug.log
        set -x
        exec 2> ${LOG_FILE}
        echo
        echo "### WARNING -- DEBUG LOG CONTAINS ALL EXECUTED COMMANDS WHICH INCLUDES CREDENTIALS -- WARNING ###"
        echo "### WARNING --             PLEASE REMOVE CREDENTIALS BEFORE SHARING LOG            -- WARNING ###"
        echo
    fi

# Leaving blank IP address or gateway will force DHCP
if [ -z "${IP_ADDRESS}" ] || [ -z "${GATEWAY}" ]; then

    configureDHCP
    configureHostname
    restartNetwork
    configureRootPassword
    configureDataDisk
    configureHarbor
    addCertStore
    createCustomizationFlag

    else

    configureStaticNetwork
    configureHostname
    restartNetwork
    configureRootPassword
    configureDataDisk
    configureHarbor
    addCertStore
    createCustomizationFlag

    fi
fi
