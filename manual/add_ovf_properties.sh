#!/bin/bash

OUTPUT_PATH="../output-vmware-iso"
OVF_PATH=${OUTPUT_PATH}

rm -f ${OUTPUT_PATH}/${PHOTON_APPLIANCE_NAME}.mf

sed "s/{{VERSION}}/${APPLIANCE_VERSION}/g" photon.xml.template > photon.xml

if [ "$(uname)" == "Darwin" ]; then
    sed -i .bak1 's/<VirtualHardwareSection>/<VirtualHardwareSection ovf:transport="com.vmware.guestInfo">/g' ${OVF_PATH}/${PHOTON_APPLIANCE_NAME}.ovf
    sed -i .bak2 "/    <\/vmw:BootOrderSection>/ r photon.xml" ${OVF_PATH}/${PHOTON_APPLIANCE_NAME}.ovf
    sed -i .bak3 '/^      <vmw:ExtraConfig ovf:required="false" vmw:key="nvram".*$/d' ${OVF_PATH}/${PHOTON_APPLIANCE_NAME}.ovf
    sed -i .bak4 "/^    <File ovf:href=\"${PHOTON_APPLIANCE_NAME}-file1.nvram\".*$/d" ${OVF_PATH}/${PHOTON_APPLIANCE_NAME}.ovf
    sed -i .bak5 "s/ovf:capacity=\"1\"/\ovf:capacity=\"${disk2size}\"/g" ${OVF_PATH}/${PHOTON_APPLIANCE_NAME}.ovf
    sed -i .bak6 's/ovf:fileRef="file2"//g' ${OVF_PATH}/${PHOTON_APPLIANCE_NAME}.ovf
    sed -i .bak7 '/vmw:ExtraConfig.*/d' ${OVF_PATH}/${PHOTON_APPLIANCE_NAME}.ovf
else
    sed -i 's/<VirtualHardwareSection>/<VirtualHardwareSection ovf:transport="com.vmware.guestInfo">/g' ${OVF_PATH}/${PHOTON_APPLIANCE_NAME}.ovf
    sed -i "/    <\/vmw:BootOrderSection>/ r photon.xml" ${OVF_PATH}/${PHOTON_APPLIANCE_NAME}.ovf
    sed -i '/^      <vmw:ExtraConfig ovf:required="false" vmw:key="nvram".*$/d' ${OVF_PATH}/${PHOTON_APPLIANCE_NAME}.ovf
    sed -i "/^    <File ovf:href=\"${PHOTON_APPLIANCE_NAME}-file1.nvram\".*$/d" ${OVF_PATH}/${PHOTON_APPLIANCE_NAME}.ovf
    sed -i 's#ovf:capacity="1"#ovf:capacity="${disk2size}"#g' ${OVF_PATH}/${PHOTON_APPLIANCE_NAME}.ovf
    sed -i 's/ovf:fileRef="file2"//g' ${OVF_PATH}/${PHOTON_APPLIANCE_NAME}.ovf
    sed -i '/vmw:ExtraConfig.*/d' ${OVF_PATH}/${PHOTON_APPLIANCE_NAME}.ovf
fi

ovftool ${OVF_PATH}/${PHOTON_APPLIANCE_NAME}.ovf ${OUTPUT_PATH}/${FINAL_PHOTON_APPLIANCE_NAME}.ova
rm -rf ${OUTPUT_PATH}/${PHOTON_APPLIANCE_NAME}.ovf ${OUTPUT_PATH}/${PHOTON_APPLIANCE_NAME}-disk1.vmdk ${OUTPUT_PATH}/${PHOTON_APPLIANCE_NAME}-disk2.vmdk ${OUTPUT_PATH}/${PHOTON_APPLIANCE_NAME}-file1.nvram
rm -f photon.xml
