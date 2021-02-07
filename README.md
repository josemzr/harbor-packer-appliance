# Harbor Packer Appliance


This is a project to develop a Packer template to have the [Harbor](https://github.com/goharbor/harbor) in an OVA format. Harbor deprecated the official OVA installation a while  ago, but it can still be useful to have a Harbor appliance for those situations when you require a fast to deploy image registry. **This project is not related to the official Harbor project and as such, it is not supported by the Harbor project maintainers.**

The OVA is based around Photon OS and can be built using [Packer](https://www.packer.io). It is based around the work by [William Lam](https://github.com/lamw/photonos-nfs-appliance) and [Timo Sugliani](https://github.com/tsugliani/packer-vsphere-debian-appliances). 

The following Packer templates will build an OVA using a VMware vSphere ESXi host (although it is easily modifiable to build from VMware Workstation or Fusion) from a Photon 3.0 image. After the creation, the VM will be customizable using OVF parameters, so network, root password and Harbor configuration will be assignable during deployment. If no network is configured during deployment, it will use DHCP.


---

**Requirements**

- A Linux or Mac environment (to be able to run the shell-local provisioner)
- A VMware ESXi host to use as builder prepared for Packer using [this guide](https://nickcharlton.net/posts/using-packer-esxi-6.html) 
- A DHCP-enabled network.
- [Packer 1.6.6](https://www.packer.io/downloads)
- [OVFTool](https://www.vmware.com/support/developer/ovf/) installed and configured in your PATH.

---

**Building**

To build this template, you will need to edit the harbor-appliance-builder.json file with your ESXi values:


```
{
  "builder_host": "packerbuild.sclab.local",
  "builder_host_username": "root",
  "builder_host_password": "VMware1!",
  "builder_host_datastore": "datastore1",
  "builder_host_portgroup": "VM Network"
}
```


Then run the build-harbor-appliance.sh script or execute the following commands:

```
rm -f output-vmware-iso/*

packer build -var-file=harbor-appliance-builder.json -var-file=harbor-version.json -var-file=harbor-appliance-version.json harbor-appliance.json
```

---


**Deployment Parameters**

The following network parameters can be configured when deploying the OVA in vSphere:

| Value          | Description              | Default value |
|----------------|--------------------------|---------------|
| Hostname       | Hostname for the VM.     | harbor        |
| IP Address     | IP address of the VM     | (DHCP)        |
| Netmask Prefix | Netmask in CIDR notation | (DHCP)        |
| Gateway        | Gateway of the VM        | (DHCP)        |
| DNS            | DNS Server of the VM     | (DHCP)        |
| DNS Domain     | DNS Domain of the VM     | (DHCP)        |

The password for the root user must be configured on deployment:

| Value         | Description                                  | Default value   |
|---------------|----------------------------------------------|-----------------|
| Root Password | Password to log into the system as root user | Mandatory value |

The following Harbor configuration parameters can be set during deployment:

| Value                                | Description                                           | Default value              |
|--------------------------------------|-------------------------------------------------------|----------------------------|
| Harbor Hostname                      | FQDN for Harbor                                       | Mandatory value            |
| Harbor Data Volume size              | Size of the volume in GB                              | 60 GB                      |
| Harbor HTTPS certificate             | HTTPS certificate in PEM format                       | Auto generated certificate |
| Harbor HTTPS certificate Private Key | Private key for the certificate in PEM format         | Auto generated certificate |
| Harbor admin password                | Harbor admin password                                 | Harbor12345                |
| Harbor database password             | Harbor integrated PostgreSQL password                 | root123                    |
| Harbor HTTP Proxy (optional)         | HTTP Proxy for Harbor                                 |                            |
| Harbor HTTPS Proxy (optional)        | HTTPS proxy for Harbor                                |                            |
| Harbor No Proxy (optional)           | Locations to exclude from Harbor HTTP and HTTPS_PROXY |                            |

An additional flag can be configured for virtual machine deployment debugging:

| Value | Description                                                | Default value |
|-------|------------------------------------------------------------|---------------|
| Debug | Enables logging to /var/log/photon-customization-debug.log | False         |

---

**Acknowledgements**


This project is possible because of the great work done in the [packer-vsphere-debian-appliances](https://github.com/tsugliani/packer-vsphere-debian-appliances) project and the amazing [Netshoot](https://github.com/nicolaka/netshoot) by Nicolaka. Also, Robert Guske contributed to the previous project, Netshoot-OVA.
