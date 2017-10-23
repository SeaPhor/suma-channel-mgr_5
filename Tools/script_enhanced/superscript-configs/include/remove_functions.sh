##############  Remove Lab Env Functions ##################################
# version: 2.1.1
# date: 2015-07-07
#

remove_libvirt_networks() {
  if [ -z "${LIBVIRT_VNET_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Removing Libvirt virtual network(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VNET in ${LIBVIRT_VNET_LIST}
  do
      echo -e "${LTGREEN}COMMAND: ${GRAY}sudo virsh net-destroy ${VNET}${NC}"
      sudo virsh net-destroy ${VNET}
      echo -e "${LTGREEN}COMMAND: ${GRAY}sudo virsh net-undefine ${VNET}${NC}"
      sudo virsh net-undefine ${VNET}
  done
  echo
}

remove_new_bridges() {
  if [ -z "${BRIDGE_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Removing New Bridge(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for BRIDGE in ${BRIDGE_LIST}
  do
    local BRIDGE_NAME=$(echo ${BRIDGE} | cut -d , -f 1)
    local NODE_NUM=$(echo ${BRIDGE} | cut -d , -f 2)
    local BRIDGE_NET=$(echo ${BRIDGE} | cut -d , -f 3)
    local IFCFG_FILE="/etc/sysconfig/network/ifcfg-${BRIDGE_NAME}"
    echo 

    echo -e "${LTCYAN}Bridge: ${BRIDGE_NAME} ...${NC}"
    echo -e "${LTGREEN}COMMAND: ${GRAY}sudo /sbin/ifdown ${BRIDGE_NAME}${NC}"
    sudo /sbin/ifdown ${BRIDGE_NAME}
    echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${IFCFG_FILE}${NC}"
    sudo rm -rf ${IFCFG_FILE}
    echo
  done
}

remove_new_vlans() {
  if [ -z "${VLAN_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Removing New VLAN(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VLAN in ${VLAN_LIST}
  do
    local VLAN_NAME=$(echo ${VLAN} | cut -d , -f 1)
    local NODE_NUM=$(echo ${VLAN} | cut -d , -f 2)
    local VLAN_NET=$(echo ${VLAN} | cut -d , -f 3)
    local IFCFG_FILE="/etc/sysconfig/network/ifcfg-${VLAN_NAME}"
    echo 

    echo -e "${LTCYAN}VLAN: ${VLAN_NAME} ...${NC}"
    echo -e "${LTGREEN}COMMAND: ${GRAY}sudo /sbin/ifdown ${VLAN_NAME}${NC}"
    sudo /sbin/ifdown ${VLAN_NAME}
    echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${IFCFG_FILE}${NC}"
    sudo rm -rf ${IFCFG_FILE}
    echo
  done
}

remove_new_nics() {
  echo -e "${LTBLUE}Removing New NIC(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for IFCFG_FILE in $(ls /etc/sysconfig/network/ifcfg-*)
  do
    if sudo grep -q "created by install_lab_env" ${IFCFG_FILE}
    then
      local NIC_NAME=$(basename ${IFCFG_FILE} | sed 's/ifcfg-//g')
      echo -e "${LTGREEN}COMMAND: ${GRAY}sudo /sbin/ifdown ${NIC_NAME}${NC}"
      sudo /sbin/ifdown ${NIC_NAME}
      echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${IFCFG_FILE}${NC}"
      sudo rm -rf ${IFCFG_FILE}
    fi
  done
}

remove_iso_images() {
  if ! [ -e ${ISO_SRC_DIR} ]
  then
    return
  fi
  echo -e "${LTBLUE}Removing ISO images ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${ISO_DEST_DIR}/*${NC}"
  rm -rf ${ISO_DEST_DIR}/*
  echo
}

remove_cloud_images() {
  if ! [ -e ${IMAGE_SRC_DIR} ]
  then
    return
  fi
  echo -e "${LTBLUE}Remove Cloud images ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${IMAGE_DEST_DIR}/*${NC}"
  rm -rf ${IMAGE_DEST_DIR}/*
  echo
}

remove_course_files() {
  if [ -e ${HOME}/course_files ]
  then
    echo -e "${LTBLUE}Remove course files ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${HOME}/course_files/*${NC}"
    rm -rf ${HOME}/course_files/*
    #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
    #echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${HOME}/course_files/${COURSE_NUM}${NC}"
    #rm -rf ${HOME}/course_files/${COURSE_NUM}
    echo
  fi
}

remove_lab_scripts() {
  #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
  #if [ -d ${SCRIPTS_DEST_DIR}/${COURSE_NUM} ]
  #then
    echo -e "${LTBLUE}Removing lab scripts ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    if [ -e ${SCRIPTS_DEST_DIR}/${VM_AUTOBUILD_SCRIPT_DIR} ]
    then
      echo -e "${LTCYAN}VM autobuild scripts ...${NC}"
      echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${SCRIPTS_DEST_DIR}/${VM_AUTOBUILD_SCRIPT_DIR}${NC}"
      rm -rf ${SCRIPTS_DEST_DIR}/${VM_AUTOBUILD_SCRIPT_DIR}
      #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
      #echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${VM_AUTOBUILD_SCRIPT_DIR}${NC}"
      #rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${VM_AUTOBUILD_SCRIPT_DIR}
      echo
    fi
    
    if [ -e ${SCRIPTS_DEST_DIR}/${LAB_SCRIPT_DIR} ]
    then
      echo -e "${LTCYAN}Lab automation scripts ...${NC}"
      echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${SCRIPTS_DEST_DIR}/${LAB_SCRIPT_DIR}${NC}"
      rm -rf ${SCRIPTS_DEST_DIR}/${LAB_SCRIPT_DIR}
      #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
      #echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${LAB_SCRIPT_DIR}${NC}"
      #rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${LAB_SCRIPT_DIR}
      echo
    fi
    
    if [ -e ${SCRIPTS_DEST_DIR}/${DEPLOY_CLOUD_SCRIPT_DIR} ]
    then
      echo -e "${LTCYAN}Deploy cloud scripts ...${NC}"
      echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${SCRIPTS_DEST_DIR}/${DEPLOY_CLOUD_SCRIPT_DIR}${NC}"
      rm -rf ${SCRIPTS_DEST_DIR}/${DEPLOY_CLOUD_SCRIPT_DIR}
      #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
      #echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${DEPLOY_CLOUD_SCRIPT_DIR}${NC}"
      #rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${DEPLOY_CLOUD_SCRIPT_DIR}
      echo
    fi
    
    if [ -e ${LOCAL_VNET_CONFIG_DIR} ]
    then
      echo -e "${LTCYAN}Libvirt virtual network configs ...${NC}"
      echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${LOCAL_VNET_CONFIG_DIR}${NC}"
      rm -rf ${LOCAL_VNET_CONFIG_DIR}
      echo
    fi
    
    if [ -e ${SCRIPTS_DEST_DIR}/restore-virtualization-environment.sh ]
    then
      echo -e "${LTCYAN}restore-virtualization-environment.sh  script ...${NC}"
      echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${SCRIPTS_DEST_DIR}/restore-virtualization-environment.sh${NC}"
      rm -rf ${SCRIPTS_DEST_DIR}/restore-virtualization-environment.sh
      #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
      #echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/restore-virtualization-environment.sh${NC}"
      #rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/restore-virtualization-environment.sh
      echo
    fi
    
    #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
    #echo -e "${LTCYAN}${COURSE_NUM} scripts ...${NC}"
    #echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}${NC}"
    #rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}
    #echo

  #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
  #else
  #  echo "No lab scripts seem to have been installed."
  #fi
}
    
remove_removal_scripts() {
  #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
  #if [ -d ${SCRIPTS_DEST_DIR}/${COURSE_NUM} ]
  #then
    echo -e "${LTBLUE}Removing removal scripts ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    if [ -e ${SCRIPTS_DEST_DIR}/config ]
    then
      echo -e "${LTCYAN}Lab environment config ...${NC}"
      echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${SCRIPTS_DEST_DIR}/config${NC}"
      rm -rf ${SCRIPTS_DEST_DIR}/config
      #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
      #echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config${NC}"
      #rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config
      echo
    fi
    
    if [ -e ${SCRIPTS_DEST_DIR}/remove_lab_env.sh ]
    then
      echo -e "${LTCYAN}Lab environment removal script ...${NC}"
      echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${SCRIPTS_DEST_DIR}/remove_lab_env.sh${NC}"
      rm -rf ${SCRIPTS_DEST_DIR}/remove_lab_env.sh
      #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
      #echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/remove_lab_env.sh${NC}"
      #rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/remove_lab_env.sh
      echo
    fi
  #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
  #fi
}

remove_pdfs() {
  #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
  #if ! [ -e ${PDF_DEST_DIR}/${COURSE_NUM} ]
  #then
  #  return
  #fi
  echo -e "${LTBLUE}Removing PDF manuals and docs ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${PDF_DEST_DIR}/*${NC}"
  rm -rf ${PDF_DEST_DIR}/*
  #-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
  #echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${PDF_DEST_DIR}/${COURSE_NUM}${NC}"
  #rm -rf ${PDF_DEST_DIR}/${COURSE_NUM}
  echo
}

remove_libvirt_vms() {
  if [ -z "${LIBVIRT_VM_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Removing Libvirt virtual machines ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VM in ${LIBVIRT_VM_LIST}
  do
    echo -e "${LTCYAN}VM Name:${GREEN} ${VM}${NC}"
    echo -e "${LTCYAN}---------------------${NC}"
    echo -e "${LTGREEN}COMMAND: ${GRAY}sudo virsh destroy ${VM}${NC}"
    sudo virsh destroy ${VM}
    echo -e "${LTGREEN}COMMAND: ${GRAY}sudo virsh undefine --remove-all-storage --snapshots-metadata --wipe-storage ${VM}${NC}"
    sudo virsh undefine --remove-all-storage --snapshots-metadata --wipe-storage ${VM}
    echo
    echo -e "${LTCYAN}Deleting:${GREEN} ${VM_DEST_DIR}/${VM}${NC}"
    echo -e "${LTCYAN}-------------------------------------${NC}"
    echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${VM_DEST_DIR}/${VM}${NC}"
    rm -rf ${VM_DEST_DIR}/${VM}
  done

  echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${VM_DEST_DIR}${NC}"
  rm -rf ${VM_DEST_DIR}

  if ! [ -z ${LIBVIRT_AUTOBUILD_VM_CONFIG} ]
  then
    if [ -e ${LIBVIRT_AUTOBUILD_VM_CONFIG} ]
    then
      cd ${SCRIPTS_DEST_DIR}/${VM_AUTOBUILD_SCRIPT_DIR}/
      ./destroy-vms.sh config=${LIBVIRT_AUTOBUILD_VM_CONFIG}
    fi
  fi
  echo
}

remove_vmware_vms() {
  if [ -z "${VMWARE_VM_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Removing VMware virtual machines ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VM in $(vmrun list | grep -iv "Total running VMs.*")
  do
    echo -e "${LTCYAN}VM Name:${GREEN} ${VM}${NC}"
    echo -e "${LTCYAN}---------------------${NC}"
    echo -e "${LTGREEN}COMMAND: ${GRAY}vmrun stop ${VM}${NC}"
    vmrun stop ${VM}
    echo
    echo -e "${LTCYAN}Deleting: ${VM_DEST_DIR}/${VM}${NC}"
    echo -e "${LTCYAN}---------------------------------${NC}"
    echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${VM_DEST_DIR}/${VM}${NC}"
    rm -rf ${VM_DEST_DIR}/${VM}
  done

  echo -e "${LTGREEN}COMMAND: ${GRAY}rm -rf ${VM_DEST_DIR}${NC}"
  rm -rf ${VM_DEST_DIR}
  echo
}

remove_vmware_networks() {
  if [ -z "${VMWARE_VNET_LIST}" ]
  then
    return
  fi

  echo -e "${LTBLUE}Removing VMware networks ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"

  echo -e "${LTGREEN}COMMAND: ${GRAY}sudo vmware-networks --stop${NC}"
  sudo vmware-networks --stop
  echo

  for VMNET_NAME in ${VMWARE_VNET_LIST}
  do
    echo -e "${LTCYAN}Remove Network: ${VMNET_NAME}${NC}"
    echo -e "${LTCYAN}----------------------${NC}"

    echo -e "${LTGREEN}COMMAND: ${GRAY}sudo rm -rf /etc/vmware/${VMNET_NAME}${NC}"
    sudo rm -rf /etc/vmware/${VMNET_NAME}
  done

  echo -e "${LTGREEN}COMMAND: ${GRAY}sudo mv /etc/vmware/networking.orig /etc/vmware/networking${NC}"
  sudo mv /etc/vmware/networking.orig /etc/vmware/networking
  echo

  echo -e "${LTGREEN}COMMAND: ${GRAY}sudo chown root.root /etc/vmware/networking${NC}"
  sudo chown root.root /etc/vmware/networking
  echo -e "${LTGREEN}COMMAND: ${GRAY}sudo chmod 644 /etc/vmware/networking${NC}"
  sudo chmod 644 /etc/vmware/networking
  echo

  echo -e "${LTGREEN}COMMAND: ${GRAY}sudo vmware-networks --start${NC}"
  sudo vmware-networks --start
  echo
}

remove_vmware() {
  if ! [ -e /usr/bin/vmware-installer ]
  then
    return
  fi

  VMWARE_PROD="$(sudo /usr/bin/vmware-installer --console -l | tac | head -n 1 | awk '{ print $1 }')"

  echo -e "${LTBLUE}Removing VMware ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  echo -e "${LTGREEN}COMMAND: ${GRAY}sudo /usr/bin/vmware-installer --console -u ${VMWARE_PROD}${NC}"
  echo
  sudo /usr/bin/vmware-installer --console -u ${VMWARE_PROD} -I --required
  echo
  echo -e "${LTGREEN}COMMAND: ${GRAY}sudo rm -f /etc/vmware/license-ws*${NC}"
  sudo rm -f /etc/vmware/license-ws*
  echo
}

remove_ssh_keys() {
  case ${INSTALL_SSH_KEYS} in
    y|Y|yes|Yes|YES)
      if ! [ -z "${SSH_FILE_LIST}" ]
      then
        echo -e "${LTBLUE}Removing SSH keys ...${NC}"
        echo -e "${LTBLUE}---------------------------------------------------------${NC}"
        for FILE in ${SSH_FILE_LIST}
        do
          echo -e "${LTGREEN}COMMAND: ${GRAY}rm -f ~/.ssh/${FILE}${NC}"
          rm -f ~/.ssh/${FILE}
        done
        echo
      fi
    ;;
    *)
      return
    ;;
  esac
}
