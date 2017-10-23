#!/bin/bash
# Version: 2.2.0
# Date: 2016-06-28

source config/include/colors.sh

DEFAULT_CONFIG="./config/lab_env.cfg"

if echo $* | grep -q "config="
then
  CONFIG=$(echo $* | grep -o "config=.*" | cut -d = -f 2 | cut -d \  -f 1)
else
  CONFIG="${DEFAULT_CONFIG}"
fi
 
if ! [ -e "${CONFIG}" ]
then
  echo
  echo -e "${RED}ERROR:  The configuration file $CONFIG doesn't exist.${NC}"
  echo
  exit 1
else
  #echo -e ${LTBLUE}CONFIG=${NC}${CONFIG}
  source ${CONFIG}
fi

if echo $* | grep -q "testonly"
then
  TEST_ONLY=y
else
  TEST_ONLY=n
fi

##############################################################################
#                          Global Variables
##############################################################################

source config/include/global_vars.sh

##############################################################################
#                          Functions
##############################################################################

#== Source Common Functions ==

source config/include/common_functions.sh

#== Source System Test Functions ==

source config/include/system_test_functions.sh

#== Source Helper Functions ==

source config/include/helper_functions.sh

#== Source Installation Functions ==

source config/include/install_functions.sh

#== Source Custom Functions ==

if ! [ -z "${CUSTOM_FUNCTIONS_FILE}" ]
then
  if [ -e ${CUSTOM_FUNCTIONS_FILE} ]
  then
    echo -e "${LTBLUE}Loading Custom Functions File ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    source ${CUSTOM_FUNCTIONS_FILE}
  fi
fi

##############################################################################
#                          Main Code Body
##############################################################################

if [ -z ${INST_FILES_DIR} ]
then
  INST_FILES_DIR=$(dirname ${0})
fi
  
cd ${INST_FILES_DIR}


echo -e "${LTCYAN}===========================================================================${NC}"
echo -e "${LTCYAN}  ${COURSE_NAME} - Lab Environment Installation"
echo -e "${LTCYAN}===========================================================================${NC}"
echo

#-------------------  Check System Configuration  ----------------------------

echo -e "${LTCYAN}---------------------------------------------------------------------------${NC}"
echo -e "${LTCYAN}                           Running System Tests"
echo -e "${LTCYAN}---------------------------------------------------------------------------${NC}"
echo
run_tests

case ${TEST_ONLY}
in
  y)
    exit
  ;;
esac

#----------------------  Perform installation  -------------------------------

echo -e "${LTCYAN}---------------------------------------------------------------------------${NC}"
echo -e "${LTCYAN}                      Installing Lab Environment Files"
echo -e "${LTCYAN}---------------------------------------------------------------------------${NC}"
echo

install_rpms

install_vmware

create_vmware_networks

create_libvirt_virtual_networks

create_new_vlans

create_new_bridges

create_directories

copy_iso_images

copy_cloud_images

copy_pdfs

copy_course_files

copy_lab_scripts

copy_removal_scripts

copy_libvirt_virtual_network_configs

install_ssh_keys

extract_register_libvirt_vms

create_initial_vm_snapshots

start_libvirt_vms

autobuild_libvirt_vms

print_multiple_machine_message

extract_vmware_vms

start_vmware_vms

if ! [ -z "${CUSTOM_INSTALL_COMMANDS_FILE}" ]
then
  if [ -e ${CUSTOM_INSTALL_COMMANDS_FILE} ]
  then
    echo -e "${LTBLUE}Running Custom Install Commands ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    source ${CUSTOM_INSTALL_COMMANDS_FILE}
  fi
fi

echo -e "${LTCYAN}=========================  Installation Complete  =========================${NC}"
echo
exit 0
