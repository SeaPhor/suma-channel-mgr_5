##############  Lab Env Install and Configure Functions ######################
# version: 2.1.1
# date: 2015-07-07
#

create_directories() {
  if ! [ -d ${ISO_DEST_DIR} ]
  then
    echo -e "${LTBLUE}Creating directory for ISO images ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    echo -e "${LTGREEN}COMMAND: ${GRAY}sudo mkdir -p ${ISO_DEST_DIR}${NC}"
    sudo mkdir -p ${ISO_DEST_DIR}
    echo -e "${LTGREEN}COMMAND: ${GRAY}sudo chmod -R 2777 ${ISO_DEST_DIR}${NC}"
    sudo chmod -R 2777 ${ISO_DEST_DIR}
    echo
  fi

  if ! [ -d ${IMAGE_DEST_DIR} ]
  then
    echo -e "${LTBLUE}Creating directory for Cloud images ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    echo -e "${LTGREEN}COMMAND: ${GRAY}sudo mkdir -p ${IMAGE_DEST_DIR}${NC}"
    sudo mkdir -p ${IMAGE_DEST_DIR}
    echo -e "${LTGREEN}COMMAND: ${GRAY}sudo chmod -R 2777 ${IMAGE_DEST_DIR}${NC}"
    sudo chmod -R 2777 ${IMAGE_DEST_DIR}
    echo
  fi

  if ! [ -d ${VM_DEST_DIR} ]
  then
    echo -e "${LTBLUE}Creating directory for virtual machines ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    echo -e "${LTGREEN}COMMAND: ${GRAY}sudo mkdir -p ${VM_DEST_DIR}${NC}"
    sudo mkdir -p ${VM_DEST_DIR}
    echo -e "${LTGREEN}COMMAND: ${GRAY}sudo chmod -R 2777 ${VM_DEST_DIR}${NC}"
    sudo chmod -R 2777 ${VM_DEST_DIR}
    echo
  fi

  if ! [ -d ${SCRIPTS_DEST_DIR} ]
  then
    echo -e "${LTBLUE}Creating directory for lab automation scripts ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    echo -e "${LTGREEN}COMMAND: ${GRAY}mkdir -p ${SCRIPTS_DEST_DIR}${NC}"
    mkdir -p ${SCRIPTS_DEST_DIR}
    #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
    #echo -e "${LTGREEN}COMMAND: ${GRAY}mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}${NC}"
    #mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}
    echo -e "${LTGREEN}COMMAND: ${GRAY}chmod -R 2777 ${SCRIPTS_DEST_DIR}${NC}"
    chmod -R 2777 ${SCRIPTS_DEST_DIR}
    echo
  fi

  if ! [ -d ${PDF_DEST_DIR} ]
  then
    echo -e "${LTBLUE}Creating directory for PDF manuals and docs ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    echo -e "${LTGREEN}COMMAND: ${GRAY}mkdir -p ${PDF_DEST_DIR}${NC}"
    mkdir -p ${PDF_DEST_DIR}
    #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
    #echo -e "${LTGREEN}COMMAND: ${GRAY}mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}${NC}"
    #echo -e "${LTGREEN}COMMAND: ${GRAY}mkdir -p ${PDF_DEST_DIR}/${COURSE_NUM}${NC}"
    #mkdir -p ${PDF_DEST_DIR}/${COURSE_NUM}
    echo -e "${LTGREEN}COMMAND: ${GRAY}chmod -R g+s ${PDF_DEST_DIR}${NC}"
    chmod -R g+s ${PDF_DEST_DIR}
    echo
  fi
}

create_libvirt_virtual_networks() {
  if [ -z "${LIBVIRT_VNET_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Creating Libvirt virtual network(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VNET in ${LIBVIRT_VNET_LIST}
  do
    if ! sudo virsh net-list | grep -q ${VNET}
    then
      echo -e "${LTGREEN}COMMAND: ${GRAY}sudo virsh net-define ${VNET_CONFIG_DIR}/${VNET}.xml${NC}"
      sudo virsh net-define ${VNET_CONFIG_DIR}/${VNET}.xml
      echo -e "${LTGREEN}COMMAND: ${GRAY}sudo virsh net-autostart ${VNET}${NC}"
      sudo virsh net-autostart ${VNET}
      echo -e "${LTGREEN}COMMAND: ${GRAY}sudo virsh net-start ${VNET}${NC}"
      sudo virsh net-start ${VNET}
    elif [ "$(sudo virsh net-list | grep  ${VNET} | awk '{ print $2 }')" != active ]
    then
      echo -e "${LTGREEN}COMMAND: ${GRAY}sudo virsh net-autostart ${VNET}${NC}"
      sudo virsh net-autostart ${VNET}
      if [ "$(sudo virsh net-list | grep  ${VNET} | awk '{ print $3 }')" != yes ]
      then
        echo -e "${LTGREEN}COMMAND: ${GRAY}sudo virsh net-start ${VNET}${NC}"
        sudo virsh net-start ${VNET}
      fi
    fi
  done
  echo
}

create_new_vlans() {
  if [ -z "${VLAN_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Creating New VLAN(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VLAN in ${VLAN_LIST}
  do
    local VLAN_NAME=$(echo ${VLAN} | cut -d , -f 1)
    local NODE_NUM=$(echo ${VLAN} | cut -d , -f 2)
    local VLAN_NET=$(echo ${VLAN} | cut -d , -f 3)
    local VLAN_ETHERDEV=$(echo ${VLAN} | cut -d , -f 4)
    local VLAN_ID=$(echo ${VLAN} | cut -d , -f 5)

    configure_new_vlan ${VLAN_NAME} ${NODE_NUM} ${VLAN_NET} ${VLAN_ETHERDEV} ${VLAN_ID}
    echo
  done
}

create_new_bridges() {
  if [ -z "${BRIDGE_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Creating New Bridge(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for BRIDGE in ${BRIDGE_LIST}
  do
    local BRIDGE_NAME=$(echo ${BRIDGE} | cut -d , -f 1)
    local NODE_NUM=$(echo ${BRIDGE} | cut -d , -f 2)
    local BRIDGE_NET=$(echo ${BRIDGE} | cut -d , -f 3)
    local BRIDGE_ETHERDEV=$(echo ${BRIDGE} | cut -d , -f 4)

    configure_new_bridge ${BRIDGE_NAME} ${NODE_NUM} ${BRIDGE_NET} ${BRIDGE_ETHERDEV}
    echo
  done
}

create_vmware_networks() {
  if [ -e /usr/bin/vmware ]
  then
    if [ -z "${VMWARE_VNET_LIST}" ]
    then
      return
    fi
    echo -e "${LTBLUE}Creating VMware networks ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
     
    echo -e "${LTGREEN}COMMAND: ${GRAY}sudo vmware-networks --stop${NC}"
    sudo vmware-networks --stop
    echo

    echo -e "${LTGREEN}COMMAND: ${GRAY}sudo cp /etc/vmware/networking /etc/vmware/networking.orig${NC}"
    sudo cp /etc/vmware/networking /etc/vmware/networking.orig
    echo
     
    for VMNET_NAME in ${VMWARE_VNET_LIST}
    do
      if [ -e ${VMWARE_INSTALLER_DIR}/${VMNET_NAME}.tgz ] || [ -e ${VMWARE_INSTALLER_DIR}/${VMNET_NAME}.tbz ] || [ -e ${VMWARE_INSTALLER_DIR}/${VMNET_NAME}.tar.gz ] || [ -e ${VMWARE_INSTALLER_DIR}/${VMNET_NAME}.tar.bz2 ] || [ -e ${VMWARE_INSTALLER_DIR}/${VMNET_NAME}.7z ] || [ -e ${VMWARE_INSTALLER_DIR}/${VMNET_NAME}.7z.001 ] || [ -e ${VMWARE_INSTALLER_DIR}/${VMNET_NAME}.zip ]
      then
     
        echo
        echo -e "${LTCYAN}Create Network: ${GREEN}${VMNET_NAME}${NC}"
        echo -e "${LTCYAN}----------------------${NC}"

        local ARCHIVE_TYPE=$(get_archive_type ${VMWARE_INSTALLER_DIR}/${VMNET_NAME})
        extract_archive_sudo "${VMWARE_INSTALLER_DIR}/${VMNET_NAME}" /etc/vmware ${ARCHIVE_TYPE}
        echo
     
        echo -e "${LTGREEN}COMMAND: ${GRAY}sudo chown -R root.root /etc/vmware/${VMNET_NAME}${NC}"
        sudo chown -R root.root /etc/vmware/${VMNET_NAME}
        echo
     
        if [ -e /etc/vmware/${VMNET_NAME}/nat.mac ]
        then
          echo -e "${LTGREEN}COMMAND: ${GRAY}sudo chmod 666 /etc/vmware/${VMNET_NAME}/nat.mac${NC}"
          sudo chmod 666 /etc/vmware/${VMNET_NAME}/nat.mac
          echo
        fi
     
        if [ -e /etc/vmware/${VMNET_NAME}/nat/nat.conf ]
        then
          echo -e "${LTGREEN}COMMAND: ${GRAY}sudo chmod 665 /etc/vmware/${VMNET_NAME}/nat/nat.conf${NC}"
          sudo chmod 665 /etc/vmware/${VMNET_NAME}/nat/nat.conf
          echo
        fi
     
        #echo -e "${LTGREEN}COMMAND: ${GRAY}cd -${NC}"
        #cd -
        echo
     
        echo -e "${LTGREEN}COMMAND: ${GRAY}cp /etc/vmware/networking /tmp/${NC}"
        cp /etc/vmware/networking /tmp/
        echo -e "${LTGREEN}COMMAND: ${GRAY}cat ${VMWARE_INSTALLER_DIR}/networking.${VMNET_NAME} >> /tmp/networking${NC}"
        cat ${VMWARE_INSTALLER_DIR}/networking.${VMNET_NAME} >> /tmp/networking
        echo -e "${LTGREEN}COMMAND: ${GRAY}sudo mv /tmp/networking /etc/vmware/${NC}"
        sudo mv /tmp/networking /etc/vmware/
        echo
     
        echo -e "${LTGREEN}COMMAND: ${GRAY}sudo chown root.root /etc/vmware/networking${NC}"
        sudo chown root.root /etc/vmware/networking
        echo -e "${LTGREEN}COMMAND: ${GRAY}sudo chmod 644 /etc/vmware/networking${NC}"
        sudo chmod 644 /etc/vmware/networking
        echo
      fi
    done
    
    echo -e "${LTGREEN}COMMAND: ${GRAY}sudo vmware-networks --start${NC}"
    sudo vmware-networks --start
    echo
  fi
}

copy_libvirt_virtual_network_configs() {
  if [ -z "${LIBVIRT_VNET_LIST}" ]
  then
    return
  fi
  if ! [ -d ${LOCAL_VNET_CONFIG_DIR} ]
  then
    echo -e "${LTBLUE}Creating directory for Libvirt network configs ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    echo -e "${LTGREEN}COMMAND: ${GRAY}mkdir -p ${LOCAL_VNET_CONFIG_DIR}${NC}"
    mkdir -p ${LOCAL_VNET_CONFIG_DIR} 
  fi
  echo -e "${LTGREEN}COMMAND: ${GRAY}cp ${VNET_CONFIG_DIR}/*.xml ${LOCAL_VNET_CONFIG_DIR}${NC}"
  cp ${VNET_CONFIG_DIR}/*.xml ${LOCAL_VNET_CONFIG_DIR}
  echo
}

copy_iso_images() {
  if ! [ -e ${ISO_SRC_DIR} ]
  then
    return
  fi
  echo -e "${LTBLUE}Copying ISO images ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  #echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R ${ISO_SRC_DIR}/* ${ISO_DEST_DIR}/${NC}"
  #cp -R ${ISO_SRC_DIR}/* ${ISO_DEST_DIR}/ > /dev/null 2>@1
  echo -e "${LTGREEN}COMMAND: ${GRAY}rsync -a ${ISO_SRC_DIR}/* ${ISO_DEST_DIR}/${NC}"
  rsync -a ${ISO_SRC_DIR}/* ${ISO_DEST_DIR}/ > /dev/null 2>@1
  echo
}

copy_cloud_images() {
  if ! [ -e ${IMAGE_SRC_DIR} ]
  then
    return
  fi
  echo -e "${LTBLUE}Copying Cloud images ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  #echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R ${IMAGE_SRC_DIR}/* ${IMAGE_DEST_DIR}/${NC}"
  #cp -R ${IMAGE_SRC_DIR}/* ${IMAGE_DEST_DIR}/ > /dev/null 2>@1
  echo -e "${LTGREEN}COMMAND: ${GRAY}rsync -a ${IMAGE_SRC_DIR}/* ${IMAGE_DEST_DIR}/${NC}"
  rsync -a ${IMAGE_SRC_DIR}/* ${IMAGE_DEST_DIR}/ > /dev/null 2>@1
  echo
}

copy_removal_scripts() {
  echo -e "${LTBLUE}Copying removal scripts ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  echo -e "${LTCYAN}Lab environment config ...${NC}"
  echo -e "${LTGREEN}COMMAND: ${GRAY}mkdir -p ${SCRIPTS_DEST_DIR}/config/${NC}"
  mkdir -p ${SCRIPTS_DEST_DIR}/config/
  echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R config/lab_env*.cfg ${SCRIPTS_DEST_DIR}/config/${NC}"
  cp -R config/lab_env*.cfg ${SCRIPTS_DEST_DIR}/config/ > /dev/null 2>@1
  echo
  echo -e "${LTCYAN}Lab environment removal scripts ...${NC}"
  echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R remove_lab_env.sh ${SCRIPTS_DEST_DIR}/${NC}"
  cp -R remove_lab_env.sh ${SCRIPTS_DEST_DIR}/ > /dev/null 2>@1
  echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R config/include ${SCRIPTS_DEST_DIR}/config${NC}"
  cp -R config/include ${SCRIPTS_DEST_DIR}/config > /dev/null 2>@1
  echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R config/custom-functions.sh ${SCRIPTS_DEST_DIR}/config${NC}"
  cp -R config/custom-functions.sh ${SCRIPTS_DEST_DIR}/config > /dev/null 2>@1
  echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R config/custom-remove-commands.sh ${SCRIPTS_DEST_DIR}/config${NC}"
  cp -R config/custom-remove-commands.sh ${SCRIPTS_DEST_DIR}/config > /dev/null 2>@1

  #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
  #echo -e "${LTGREEN}COMMAND: ${GRAY}mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}${NC}"
  #echo -e "${LTGREEN}COMMAND: ${GRAY}mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/${NC}"
  #mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/
  #echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R config/lab_env*.cfg ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/${NC}"
  #cp -R config/lab_env*.cfg ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/ > /dev/null 2>@1
  #echo
  #echo -e "${LTCYAN}Lab environment removal scripts ...${NC}"
  #echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R remove_lab_env.sh ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${NC}"
  #cp -R remove_lab_env.sh ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/ > /dev/null 2>@1
  #echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R config/include ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config${NC}"
  #cp -R config/include ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config > /dev/null 2>@1
  #echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R config/custom-functions.sh ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config${NC}"
  #cp -R config/custom-functions.sh ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config > /dev/null 2>@1
  #echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R config/custom-remove-commands.sh ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config${NC}"
  #cp -R config/custom-remove-commands.sh ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config > /dev/null 2>@1
  echo
}

copy_lab_scripts() {
  if [ -e ${SCRIPTS_SRC_DIR} ]
  then
    echo -e "${LTBLUE}Copying lab scripts ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"

    if [ -e ${SCRIPTS_SRC_DIR}/restore-virtualization-environment.sh ]
    then
      echo -e "${LTCYAN}restore-virtualization-environment.sh script ...${NC}"
      echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R ${SCRIPTS_SRC_DIR}/restore-virtualization-environment.sh ${SCRIPTS_DEST_DIR}${NC}"
      cp -R ${SCRIPTS_SRC_DIR}/restore-virtualization-environment.sh ${SCRIPTS_DEST_DIR}
      echo -e "${LTGREEN}COMMAND: ${GRAY}chmod +x ${SCRIPTS_DEST_DIR}/restore-virtualization-environment.sh${NC}"
      chmod +x ${SCRIPTS_DEST_DIR}/restore-virtualization-environment.sh

      #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
      #echo -e "${LTGREEN}COMMAND: ${GRAY}mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}${NC}"
      #mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}
      #
      #echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R ${SCRIPTS_SRC_DIR}/${COURSE_NUM}/restore-virtualization-environment.sh ${SCRIPTS_DEST_DIR}${NC}"
      #cp -R ${SCRIPTS_SRC_DIR}/restore-virtualization-environment.sh ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/
      #echo -e "${LTGREEN}COMMAND: ${GRAY}chmod +x ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/restore-virtualization-environment.sh${NC}"
      #chmod +x ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/restore-virtualization-environment.sh

      echo
    fi

    if [ -e ${SCRIPTS_SRC_DIR}/${VM_AUTOBUILD_SCRIPT_DIR} ]
    then
      echo -e "${LTCYAN}VM autobuild scripts ...${NC}"
      echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R ${SCRIPTS_SRC_DIR}/${VM_AUTOBUILD_SCRIPT_DIR} ${SCRIPTS_DEST_DIR}${NC}"
      cp -R ${SCRIPTS_SRC_DIR}/${VM_AUTOBUILD_SCRIPT_DIR} ${SCRIPTS_DEST_DIR} > /dev/null 2>@1
      
      echo -e "${LTGREEN}COMMAND: ${GRAY}chmod +x ${SCRIPTS_DEST_DIR}/${VM_AUTOBUILD_SCRIPT_DIR}/*.sh${NC}"
      chmod +x ${SCRIPTS_DEST_DIR}/${VM_AUTOBUILD_SCRIPT_DIR}/*.sh > /dev/null 2>@1
      
      echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R ${VM_AUTOBUILD_CONFIG_DIR}/*.cfg ${SCRIPTS_DEST_DIR}/${VM_AUTOBUILD_SCRIPT_DIR}${NC}"
      cp -R ${VM_AUTOBUILD_CONFIG_DIR}/*.cfg ${SCRIPTS_DEST_DIR}/${VM_AUTOBUILD_SCRIPT_DIR} > /dev/null 2>@1

      #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
      #echo -e "${LTGREEN}COMMAND: ${GRAY}mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}${NC}"
      #mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}
      #
      #echo -e "${LTCYAN}VM autobuild scripts ...${NC}"
      #echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R ${SCRIPTS_SRC_DIR}/${VM_AUTOBUILD_SCRIPT_DIR} ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${NC}"
      #cp -R ${SCRIPTS_SRC_DIR}/${VM_AUTOBUILD_SCRIPT_DIR} ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/ > /dev/null 2>@1
      #
      #echo -e "${LTGREEN}COMMAND: ${GRAY}chmod +x ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${VM_AUTOBUILD_SCRIPT_DIR}/*.sh${NC}"
      #chmod +x ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${VM_AUTOBUILD_SCRIPT_DIR}/*.sh > /dev/null 2>@1
      #
      #echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R ${VM_AUTOBUILD_CONFIG_DIR}/*.cfg ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${VM_AUTOBUILD_SCRIPT_DIR}/${NC}"
      #cp -R ${VM_AUTOBUILD_CONFIG_DIR}/*.cfg ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${VM_AUTOBUILD_SCRIPT_DIR}/ > /dev/null 2>@1

      echo
    fi

    if [ -e ${SCRIPTS_SRC_DIR}/${LAB_SCRIPT_DIR} ]
    then
      echo -e "${LTCYAN}Lab automation scripts ...${NC}"
      echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R ${SCRIPTS_SRC_DIR}/${LAB_SCRIPT_DIR} ${SCRIPTS_DEST_DIR}${NC}"
      cp -R ${SCRIPTS_SRC_DIR}/${LAB_SCRIPT_DIR} ${SCRIPTS_DEST_DIR} > /dev/null 2>@1
      
      echo -e "${LTGREEN}COMMAND: ${GRAY}chmod +x ${SCRIPTS_DEST_DIR}/${LAB_SCRIPT_DIR}/*.sh${NC}"
      chmod +x ${SCRIPTS_DEST_DIR}/${LAB_SCRIPT_DIR}/*.sh > /dev/null 2>@1
      
      echo -e "${LTGREEN}COMMAND: ${GRAY}chmod +x ${SCRIPTS_DEST_DIR}/${LAB_SCRIPT_DIR}/*/*.sh${NC}"
      chmod +x ${SCRIPTS_DEST_DIR}/${LAB_SCRIPT_DIR}/*/*.sh > /dev/null 2>@1

      #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
      #echo -e "${LTGREEN}COMMAND: ${GRAY}mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}${NC}"
      #mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}
      #
      #echo -e "${LTCYAN}Lab automation scripts ...${NC}"
      #echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R ${SCRIPTS_SRC_DIR}/${LAB_SCRIPT_DIR} ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${NC}"
      #cp -R ${SCRIPTS_SRC_DIR}/${LAB_SCRIPT_DIR} ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/ > /dev/null 2>@1
      #
      #echo -e "${LTGREEN}COMMAND: ${GRAY}chmod +x ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${LAB_SCRIPT_DIR}/*.sh${NC}"
      #chmod +x ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${LAB_SCRIPT_DIR}/*.sh > /dev/null 2>@1
      #
      #echo -e "${LTGREEN}COMMAND: ${GRAY}chmod +x ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${LAB_SCRIPT_DIR}/*/*.sh${NC}"
      #chmod +x ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${LAB_SCRIPT_DIR}/*/*.sh > /dev/null 2>@1

      echo
    fi

    if [ -e ${SCRIPTS_SRC_DIR}/${DEPLOY_CLOUD_SCRIPT_DIR} ]
    then
      echo -e "${LTCYAN}Deploy cloud scripts ...${NC}"
      echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R ${SCRIPTS_SRC_DIR}/${DEPLOY_CLOUD_SCRIPT_DIR} ${SCRIPTS_DEST_DIR}${NC}"
      cp -R ${SCRIPTS_SRC_DIR}/${DEPLOY_CLOUD_SCRIPT_DIR} ${SCRIPTS_DEST_DIR} > /dev/null 2>@1
      
      echo -e "${LTGREEN}COMMAND: ${GRAY}chmod +x ${SCRIPTS_DEST_DIR}/${DEPLOY_CLOUD_SCRIPT_DIR}/*.sh${NC}"
      chmod +x ${SCRIPTS_DEST_DIR}/${DEPLOY_CLOUD_SCRIPT_DIR}/*.sh > /dev/null 2>@1
      
      echo -e "${LTGREEN}COMMAND: ${GRAY}chmod +x ${SCRIPTS_DEST_DIR}/${DEPLOY_CLOUD_SCRIPT_DIR}/*/*.sh${NC}"
      chmod +x ${SCRIPTS_DEST_DIR}/${DEPLOY_CLOUD_SCRIPT_DIR}/*/*.sh > /dev/null 2>@1

      #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
      #echo -e "${LTGREEN}COMMAND: ${GRAY}mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}${NC}"
      #mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}
      #
      #echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R ${SCRIPTS_SRC_DIR}/${DEPLOY_CLOUD_SCRIPT_DIR}/ ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${NC}"
      #cp -R ${SCRIPTS_SRC_DIR}/${DEPLOY_CLOUD_SCRIPT_DIR} ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/ > /dev/null 2>@1
      #
      #echo -e "${LTGREEN}COMMAND: ${GRAY}chmod +x ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${DEPLOY_CLOUD_SCRIPT_DIR}/*.sh${NC}"
      #chmod +x ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${DEPLOY_CLOUD_SCRIPT_DIR}/*.sh > /dev/null 2>@1
      # 
      #echo -e "${LTGREEN}COMMAND: ${GRAY}chmod +x ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${DEPLOY_CLOUD_SCRIPT_DIR}/*/*.sh${NC}"
      #chmod +x ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${DEPLOY_CLOUD_SCRIPT_DIR}/*/*.sh > /dev/null 2>@1
    fi

    echo
  fi
}

copy_pdfs() {
  if ! [ -e ${PDF_SRC_DIR} ]
  then
    return
  fi
  echo -e "${LTBLUE}Copying PDF manuals and docs ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R ${PDF_SRC_DIR}/* ${PDF_DEST_DIR}/${NC}"
  cp -R ${PDF_SRC_DIR}/* ${PDF_DEST_DIR}/
  #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
  #echo -e "${LTGREEN}COMMAND: ${GRAY}mkdir -p ${PDF_DEST_DIR}/${COURSE_NUM}${NC}"
  #mkdir -p ${PDF_DEST_DIR}/${COURSE_NUM}
  #echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R ${PDF_SRC_DIR}/* ${PDF_DEST_DIR}/${COURSE_NUM}/${NC}"
  #cp -R ${PDF_SRC_DIR}/* ${PDF_DEST_DIR}/${COURSE_NUM}/
  echo
}

copy_course_files() {
  if [ -e ./course_files ]
  then
    echo -e "${LTBLUE}Copying course files ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    echo -e "${LTGREEN}COMMAND: ${GRAY}mkdir -p ${HOME}/course_files/${NC}"
    mkdir -p ${HOME}/course_files/
    echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R course_files/* ${HOME}/course_files/${NC}"
    cp -R course_files/* ${HOME}/course_files/ > /dev/null 2>@1
    #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
    #echo -e "${LTGREEN}COMMAND: ${GRAY}mkdir -p ${HOME}/course_files/${COURSE_NUM}/${NC}"
    #mkdir -p ${HOME}/course_files/${COURSE_NUM}
    #echo -e "${LTGREEN}COMMAND: ${GRAY}cp -R course_files/* ${HOME}/course_files/${COUSE_NUM}/${NC}"
    #cp -R course_files/* ${HOME}/course_files/${COURSE_NUM}/ > /dev/null 2>@1
    echo
  fi
}

install_ssh_keys() {
  case ${INSTALL_SSH_KEYS} in
    y|Y|yes|Yes|YES)
      if ! [ -z "${SSH_FILE_LIST}" ]
      then
        echo -e "${LTBLUE}Installing SSH keys ...${NC}"
        echo -e "${LTBLUE}---------------------------------------------------------${NC}"
        echo -e "${LTGREEN}COMMAND: ${GRAY}mkdir -p ~/.ssh/${NC}"
        mkdir -p ~/.ssh/
        for FILE in ${SSH_FILE_LIST}
        do
          echo -e "${LTGREEN}COMMAND: ${GRAY}cp ${CONFIG_SRC_DIR}/ssh/${FILE} ~/.ssh/${NC}"
          cp ${CONFIG_SRC_DIR}/ssh/${FILE} ~/.ssh/
        done
        echo
        test -e ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/id_*
        test -e ~/.ssh/known_hosts && chmod 644 ~/.ssh/known_hosts
        chmod 644 ~/.ssh/*.pub
      fi
    ;;
    *)
      return
    ;;
  esac
}

extract_register_libvirt_vms() {
  if [ -z "${LIBVIRT_VM_LIST}" ]
  then
    return
  fi

  echo -e "${LTBLUE}Extracting and registering Libvirt virtual machines ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VM in ${LIBVIRT_VM_LIST}
  do
    echo -e "${LTCYAN}VM Name:${GREEN} ${VM}${NC}"
    echo -e "${LTCYAN}---------------------${NC}"

    local ARCHIVE_TYPE=$(get_archive_type ${VM_SRC_DIR}/${VM})

    extract_archive "${VM_SRC_DIR}/${VM}" ${VM_DEST_DIR} ${ARCHIVE_TYPE}

    echo

    edit_libvirt_domxml

    case ${MULTI_LAB_MACHINE}
    in
      y|Y|yes|Yes|YES|t|T|true|True|TRUE)
        local VM_CONFIG="${VM}-${MULTI_LM_EXT}.xml"
      ;;
      *)
        local VM_CONFIG="${VM}.xml"
      ;;
    esac

    case ${MULTI_LAB_MACHINE}
    in
      y|Y|yes|Yes|YES|t|T|true|True|TRUE)
        if [ -e ${VM_DEST_DIR}/"${VM}"/"${VM_CONFIG}" ]
        then
          echo -e "${LTGREEN}COMMAND: ${GRAY}sudo virsh define ${VM_DEST_DIR}/"${VM}"/"${VM_CONFIG}"${NC}"
          sudo virsh define ${VM_DEST_DIR}/"${VM}"/"${VM_CONFIG}"
        fi
        echo
      ;;
      *)
        if [ -e ${VM_DEST_DIR}/"${VM}"/"${VM_CONFIG}" ]
        then
          echo -e "${LTGREEN}COMMAND: ${GRAY}sudo virsh define ${VM_DEST_DIR}/"${VM}"/"${VM_CONFIG}"${NC}"
          sudo virsh define ${VM_DEST_DIR}/"${VM}"/"${VM_CONFIG}"
        fi
        echo
      ;;
    esac
  done
  echo
}

create_initial_vm_snapshots() {
  case ${LIBVIRT_CREATE_INITIAL_SNAPSHOT} in
    Y|y|yes|Yes)
      echo -e "${LTBLUE}Creating initial Libvirt virtual machine snapshots ...${NC}"
      echo -e "${LTBLUE}---------------------------------------------------------${NC}"
      for VM in ${LIBVIRT_VM_LIST}
      do
        create_vm_snapshot ${VM} ${LIBVIRT_INITIAL_SNAPSHOT_NAME}
      done
    ;;
    *)
      return
    ;;
  esac
}

start_libvirt_vms() {
  if [ -z "${LIBVIRT_START_VM_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Starting Libvirt virtual machines ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VM in ${LIBVIRT_START_VM_LIST}
  do
    echo -e "${LTCYAN}VM Name:${GREEN}${VM}${NC}"
    echo -e "${LTCYAN}---------------------${NC}"
    echo -e "${LTGREEN}COMMAND: ${GRAY}sudo virsh start ${VM}${NC}"
    sudo virsh start ${VM}
    echo
  done
  echo
}

autobuild_libvirt_vms() {
  if [ -z "${LIBVIRT_AUTOBUILD_VM_CONFIG}" ]
  then
    return
  fi

  if [ -e ${LIBVIRT_AUTOBUILD_VM_CONFIG} ]
  then
    echo -e "${LTBLUE}Autobuilding Libvirt virtual machines ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    cd ${SCRIPTS_DEST_DIR}/${VM_AUTOBUILD_SCRIPT_DIR}/
    ./create-vms.sh config=${LIBVIRT_AUTOBUILD_VM_CONFIG}
  fi
}

print_multiple_machine_message() {
  if ! [ -z "${BRIDGE_LIST}" ]
  then
    local NODE_NUM="$(echo ${BRIDGE_LIST} | awk '{ print $1 }' | cut -d , -f 2)"

    echo -e "${ORANGE}---------------------------------------------------------------- ${NC}"
    echo
    echo -e "${ORANGE} It appears that you are using multiple lab machines in your ${NC}"
    echo -e "${ORANGE} lab environment with this being lab machine #${NODE_NUM}${NC}"
    echo
    echo -e "${ORANGE} Ensure that you run the install_lab_env.sh script on the other${NC}"
    echo -e "${ORANGE} lab machine(s) using the config file that corresponds to each machine${NC}"
    echo
    echo -e "${ORANGE} Example: ${GRAY}bash ./install_lab_env.sh config=${GREEN}<node_specific_config_file>${NC}"
    #echo
    #echo -e "${ORANGE} Enter the following command(s) on the other lab machine(s):${NC}"
    #echo
    #for BRIDGE in ${BRIDGE_LIST}
    #do
    #  local BRIDGE_NAME="$(echo ${BRIDGE} | cut -d , -f 1)"
    #  local NODE_NUM=""
    #  local BRIDGE_NET="$(echo ${BRIDGE} | cut -d , -f 3)"
    #  echo -e "${GRAY}  configure-new-bridge ${BRIDGE_NAME} <node number> ${BRIDGE_NET}${NC}"
    #done
    #echo
    #echo -e "${ORANGE} Where <node number> is the number of the lab machine ${NC}"
    #echo -e "${ORANGE}  (i.e. 2 for the second lab machine, 3 for the third, ...).${NC}"
    #echo -e "${ORANGE} ${NC}"
    #echo -e "${ORANGE} Make sure you use the multinode specific create-vms.cfg files${NC}"
    #echo -e "${ORANGE} when auto building your additional lab VMs.${NC}"
    #echo
    #echo -e "${ORANGE} IMPORTANT:${NC}"
    #echo -e "${ORANGE}   If you are using the autobuild-libvirt-vms feature of this${NC}"
    #echo -e "${ORANGE}   script, this should have been done before running this script${NC}"
    #echo -e "${ORANGE}   on lab machine #${NODE_NUM} If it wasn't, you may need to manually run${NC}"
    #echo -e "${ORANGE}   the create-vms.sh script again.${NC}"
    echo
    echo -e "${ORANGE}---------------------------------------------------------------- ${NC}"
    echo
  fi
}

extract_vmware_vms() {
  if [ -z "${VMWARE_VM_LIST}" ]
  then
    return
  fi

  echo -e "${LTBLUE}Extracting VMware virtual machines ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VM in ${VMWARE_VM_LIST}
  do
    echo -e "${LTCYAN}VM Name:${GREEN}${VM}${NC}"
    echo -e "${LTCYAN}---------------------${NC}"

    local ARCHIVE_TYPE=$(get_archive_type ${VM_SRC_DIR}/)

    extract_archive "${VM_SRC_DIR}/${VM}" ${VM_DEST_DIR} ${ARCHIVE_TYPE}

    echo
  done
}

start_vmware_vms() {
  if [ -z "${VMWARE_START_VM_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Starting VMware virtual machines ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VM in ${VMWARE_START_VM_LIST}
  do
    echo -e "${LTCYAN}VM Name:${GREEN}${VM}${NC}"
    echo -e "${LTCYAN}---------------------${NC}"
    echo -e "${LTGREEN}COMMAND: ${GRAY}vmrun start ${VM_DEST_DIR}/${VM}${NC}"
    vmrun start ${VM_DEST_DIR}/${VM}
    echo
  done
  echo
}
