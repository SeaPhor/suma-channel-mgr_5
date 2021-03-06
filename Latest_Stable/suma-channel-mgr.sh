#!/bin/bash
#
#####################################################################
#####	Full changelog and revision history at bottom of script
#####################################################################
#
#####################################################################
#####                   GNU/GPL Info                                
#####################################################################
#
gpl_info () {
    cat <<EOT
${LTCYN}
####c4#############################################################################
###                                                                             ###
##                      GNU/GPL Info                                             ##
##        channellock-promote.sh ver-1.1 - Alpha/Beta begun 15 March 2015	 ##
##        channellock-promote.sh ver-4.1 - Production release 11 December 2015	 ##
##      Forked to suma-channel-mgr.sh ver-5.0 on 19 December 2017                ##
##      Released under GPL v2.0, See www.gnu.org for full license info           ##
##      Copyright (C) 2015  Shawn Miller                                         ##
##              EMAIL- shawn@woodbeeco.com                                       ##
##                   - seaphor@woodbeeco.com                                     ##
##  This program is free software; you can redistribute it and/or modify         ##
##    it under the terms of the GNU General Public License as published by       ##
##    the Free Software Foundation; either version 2 of the License, or          ##
##    (at your option) any later version.                                        ##
##                                                                               ##
##    This program is distributed in the hope that it will be useful,            ##
##    but WITHOUT ANY WARRANTY; without even the implied warranty of             ##
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              ##
##    GNU General Public License for more details.                               ##
##                                                                               ##
##    See this complete License at:                                              ##
##    https://github.com/SeaPhor/suma-channel-mgr_5/blob/master/LICENSE          ##
###                                                                             ###
####w#################################b######################################c#####${RESET}
EOT
}
#
#####################################################################
#####   Setting Script Variables
#####################################################################
#
    SCRIPT_RELEASE="5.1.0-01"
    SCRIPT_RELEASE_DATE="03 Sep 2018"
    PROGNAME=$(basename $0)
    MYOPT="$1"
    REPOPATH=${HOME}/suma-channel-mgr_5
    LTSTSTAB=$REPOPATH/Latest_Stable
    PROGPATH=${HOME}/bin
    BADPATH=false
    MYCREDFIL=$PROGPATH/.creds.sh
    SYNCLOG=${HOME}/reposync.log
    TDATE=`date +%Y-%m-%d`
    RDATE=`date +%Y%m%d`
    LDATE=`date +%d-%b-%Y`
    MDATE=`date +%H:%M`
    HOSTA=`hostname`
    INITRUN=false
    TMPLATDIR=/srv/www/htdocs/pub/bootstrap
    TMPLATFIL=/srv/www/htdocs/pub/bootstrap/template.sh
    touch /tmp/tmp.sumatmp
    EMAILMSGZ=/tmp/tmp.sumatmp
    echo "Running $PROGNAME $1 Initial Process for $RDATE $2" > $EMAILMSGZ
###	Cleanup logs
    if [[ "`find ~/reposync.log -size +1M`" != "" ]]; then
        mv $SYNCLOG ${HOME}/reposync_$LDATE-log.log
        touch $SYNCLOG
    fi
    find ${HOME}/reposync_*-log.log -mtime +90 -exec rm {} \; 2>/dev/null
#
#####################################################################
#####	Setting color variables
#####################################################################
#
BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`
LTBLK=`tput setaf 8`
LTRED=`tput setaf 9`
LTGRN=`tput setaf 10`   
LTYLLW=`tput setaf 11`   
LTBLU=`tput setaf 12`   
LTMAG=`tput setaf 13`   
LTCYN=`tput setaf 14`   
LTWHT=`tput setaf 15`   
ULINE=`tput smul`
NULINE=`tput rmul`
BGBLU=`tput setab 4`
BGYLLW=`tput setab 3`
BGLYLLW=`tput setab 11`
BOLD=`tput bold`
RESET=`tput sgr0`
#
#####################################################################
#####	Checking for root, setting error exit
#####################################################################
#
[[ "$UID" == "0" ]] && : || { echo -e "\n${BOLD}${LTRED}  ${PROGNAME} - you are not root, please run as root! or do 'sudo !!'\n${RESET}"; exit 1; }
#
#####################################################################
#####	Checking for PATH
#####################################################################
#
if [[ ! -L $PROGPATH/$PROGNAME ]]; then
    BADPATH=true
    printf "Script PATH Not Recommended" >> $EMAILMSGZ
fi
chk_path () {
    if [[ ! -L $PROGPATH/$PROGNAME ]]; then
        BADPATH=true
        SCRPTNAME='suma-channel-mgr.sh'
        VERNAME='suma-channel-mgr'
    cat <<EOT
${LTBLU}
    #################################################################
      This process is designed to always have the latest release
      It is best that your cloned repo be at ~/suma-channel-mgr_5
      And that you create a sym-link to the Latest, as in so:
      'cd ~/bin' and create a sym-link to:
      ~/suma-channel-mgr_5/Latest_Stable/suma-channel-mgr.sh
    #################################################################
    Add [ignore] to the end of your command to not see this notice${RESET}
EOT
    sleep 15
    echo ""
    fi
}
#
#####################################################################
#####   Adjusted for portability, check for required spacewalk-utils
#####################################################################
#
req_depends () {
    cat <<EOT
${BOLD}${YELLOW}Requirements-${RESET}${LTCYN}
    This LifeCycleManagement process requires the SUMA Admin account username
  and password to be issued, for security and portability purposes this
  requires a local credentials file [Default = ~/bin/.creds.sh], this file is
  'sourced' for the user/pass required VARIABLES-
  The 'spacecmd' call also requires it's own credentials file in ~/.mgr-sync-
    There is also a package dependancy 'spacewalk-utils' to be installed from
  your SUSE Manager Server repositories.${RESET}
EOT
}
chk_sutils () {
    if [[ "`rpm -qa | grep spacewalk-utils`" == "" ]]; then
        cat <<EOT
${LTYLLW}    This seems to be the first time executing ${PROGNAME},
    Dependancies = >
        1-${LTCYN} Installation of spacewalk-utils${LTYLLW}
        2-${LTCYN} Creation of a sourced local credentials file to pass to commands- ~/bin/.creds.sh${LTYLLW}
        3-${LTCYN} Creation of local .mgr-sync file to pass to commands- ~/.mgr-sync${LTYLLW}
        If you choose to continue you will be required to input that
    information when prompted to do so but ONLY on the first run, it can be
    completely automated after that.${BOLD}

    Do you agree with this installation and credental files generation and wish to continue?${RESET}
[Y|n]

EOT
    read SUMADOIT
    if [[ "`echo $SUMADOIT`" == "n" ]]; then
        usage
        exit $?
    else
        zypper in -y spacewalk-utils
        printf "Installed spacewalk-utils" >> $EMAILMSGZ
    fi
fi
if [[ ! -f ~/.mgr-sync ]]; then
    printf "\n\t${LTYLLW}Enter the SUSE Manager Admin User credentials when prompted...${RESET}\n"
    mgr-sync -s refresh
fi
if [[ -f $MYCREDFIL ]]; then
    source $MYCREDFIL
else
    my_user=`cat ~/.mgr-sync | grep mgrsync.user | sed -e 's/mgrsync.user\ \=\ //'`
    my_pass=`cat ~/.mgr-sync | grep mgrsync.password | sed -e 's/mgrsync.password\ \=\ //'`
    printf "\n\t${LTYLLW}Type the email address for notifications${RESET}\n"
    read MYMAIL
    my_mail="EMAILG='$MYMAIL'"
    touch $MYCREDFIL
    my_ucred="MY_ADMIN='$my_user'"
    my_pcred="MY_CREDS='$my_pass'"
    echo $my_ucred >> $MYCREDFIL
    echo $my_pcred >> $MYCREDFIL
    echo $my_mail >> $MYCREDFIL
    chmod 700 $MYCREDFIL
    source $MYCREDFIL
    printf "\n\t${LTCYN}Your new credentials file has been successfully created...\n\tIf you mis-typed or need to change the password, \n\tit can be found at ${MYCREDFIL}${RESET}\n"
    echo "Credentials file created" >> ${EMAILMSGZ}
fi
}
#
#####################################################################
#####   Setting Options Usage Help Output
#####################################################################
#
usage () {
    clear
    cat <<EOT
${BOLD}${MAGENTA}${PROGNAME} Rev ${SCRIPT_RELEASE} Released ${SCRIPT_RELEASE_DATE}${BOLD}${YELLOW}
Usage-${RESET}${LTYLLW}
    This process requires 1 (one) parameter -- ${LTCYN}[b|d|p|h|g|r|R|c|x]${LTYLLW}
    Initially, these MUST be run in the following order-${LTCYN}
  ${PROGNAME} -b
  ${PROGNAME} -d
  ${PROGNAME} -p${BOLD}${YELLOW}
Options-${RESET}${LTCYN}
  [-b]${BOLD}${CYAN}    Base-Pool${RESET}${LTYLLW}      Clones the SUSE base pool trees to 'dev' channels${LTCYN}
  [-d]${BOLD}${CYAN}    promote-Dev${RESET}${LTYLLW}    Promotes the 'dev' channel to the 'test' channel${LTCYN}
  [-p]${BOLD}${BOLD}${CYAN}    Production${RESET}${LTYLLW}     Promotes 'test' to 'Prod'${LTCYN}
  [-h]${BOLD}${CYAN}    Help${RESET}${LTYLLW}           Prints this list and exits${LTCYN}
  [-g]${BOLD}${CYAN}    GPL${RESET}${LTYLLW}            Prints the GPL info and exits${LTCYN}
  [-r]${BOLD}${CYAN}    Release${RESET}${LTYLLW}        Prints the Current Release Version and exits${LTCYN}
  [-R]${BOLD}${CYAN}    Requirements${RESET}${LTYLLW}   Prints the Requirements and Dependencies for this process${LTCYN}
  [-c]${BOLD}${CYAN}    Change${RESET}${LTYLLW}         Prints the last 30 lines of the Change-Log and exits${LTCYN}
  [-x]${BOLD}${CYAN}    Clean${RESET}${LTYLLW}          Removes ALL clones, keys, bootstraps, and creds files and exits
                         To be used to start from scratch${BOLD}${YELLOW}
    ${ULINE}${BGBLU}If you have never run this script before${NULINE}${RESET}${BOLD}${YELLOW}, and have not yet configured your
    SUMA-Server for its use, please use the initial [${LTCYN}config${YELLOW}] Option=${RESET}${LTCYN}
  ${PROGNAME} config${RESET}${BOLD}${YELLOW}
Description-
    ${LTBLU}Please see-${LTCYN}
https://github.com/SeaPhor/suma-channel-mgr_5/blob/master/README.md${RESET}
EOT
}
#
#####################################################################
###	Begin logging
#####################################################################
#
printf "\n#########################################################\n#\n# ${LDATE}${MDATE} -- Executing ${PROGNAME} Script\n#\n#########################################################\n" >> ${EMAILMSGZ}
#
####  COMPLETETOHERE
#####################################################################
#####   Setting Functions
#####################################################################
#
no_opts () {
spacecmd -u $MY_ADMIN -p $MY_CREDS softwarechannel_listbasechannels | grep ^sle > /tmp/mybaselist.sumatmp
#	Optional- Comment/Un-Comment to disable/enable RHEL
#spacecmd -u $MY_ADMIN -p $MY_CREDS softwarechannel_listbasechannels | grep ^rhe >> /tmp/mybaselist.sumatmp
#	END - Optional- Un-Comment to enable RHEL
    MY_BASELIST=/tmp/mybaselist.sumatmp
spacecmd -u $MY_ADMIN -p $MY_CREDS softwarechannel_listbasechannels | grep -v ^sle | grep -v ^suse | grep -v rhel > /tmp/mychanlist.sumatmp
    MY_CHANLIST=/tmp/mychanlist.sumatmp
#####################################################################
#####	Check for bootstrap repo/s - this will only create the 
#####	initial repos, manual creation for new OSs/releases [at this rv]
#####################################################################
if [[ ! -d /srv/www/htdocs/pub/repositories ]]; then
    for b in `mgr-create-bootstrap-repo --list | awk '{print $2}'`; do mgr-create-bootstrap-repo --create=$b ; done
else
    for m in `mgr-create-bootstrap-repo --list | awk '{print $2}' | grep -i ^s | awk -F- '{print $2"/"$3}' | sed -e 's/[A-Z]//g'`
    do if [[ ! -d /srv/www/htdocs/pub/repositories/$m ]]; then
        for b in `mgr-create-bootstrap-repo --list | awk '{print $2}'`
        do mgr-create-bootstrap-repo --create=$b 
        done
       fi
    done
fi
}
snd_mail () {
        SUBJECT="$HOSTA -- $PROGNAME script $RDATE"
        FROMA=$MY_ADMIN@$HOST
        /usr/bin/mailx -s "$SUBJECT" "$EMAILG" -f $FROMA < $EMAILMSGZ
}
#
susetrees_clone () {
spacecmd -u $MY_ADMIN -p $MY_CREDS softwarechannel_listchildchannels | grep ^sle > /tmp/mychildlist.sumatmp
MY_CHILDLIST=/tmp/mychildlist.sumatmp
if [[ ! -f ~/.mgr-sync ]]; then
    mgr-sync -s refresh 2>&1 >> $EMAILMSGZ
else
    mgr-sync refresh 2>&1 >> $EMAILMSGZ
fi
for i in `cat $MY_CHILDLIST`; do
#for i in `cat $MY_BASELIST`; do ###Leaving here in case further issues arise xxyyzz
    /usr/bin/python -u /usr/bin/spacewalk-repo-sync --channel $i --type yum --non-interactive
done
for i in `cat $MY_BASELIST`; do
    if [[ "`grep dev-$i $MY_CHANLIST`" == "" ]]; then
        INITRUN=true
        NEWNAME=`echo $i | sed -e "s/$i/dev-$i/g"`
        spacewalk-manage-channel-lifecycle -C -c $i --init -u $MY_ADMIN -p $MY_CREDS 2>&1 >> $EMAILMSGZ
        spacecmd -u $MY_ADMIN -p $MY_CREDS activationkey_create -- -n $NEWNAME -d $NEWNAME -b $NEWNAME 2>&1 >> $EMAILMSGZ
        if [[ -f $TMPLATFIL ]]; then
            cat $TMPLATFIL | sed -e s/slartybartfast/$NEWNAME/g > $TMPLATDIR/$NEWNAME-bootstrap.sh
            chmod +x $TMPLATDIR/$NEWNAME-bootstrap.sh
        else
            mgr-bootstrap
            cat $TMPLATDIR/bootstrap.sh | sed -e 's/^ACTIVATION_KEYS\=/ACTIVATION_KEYS\=1-slartybartfast/g' > $TMPLATFIL
            cat $TMPLATFIL | sed -e s/slartybartfast/$NEWNAME/g > $TMPLATDIR/$NEWNAME-bootstrap.sh
            chmod +x $TMPLATDIR/$NEWNAME-bootstrap.sh
        fi
        spacecmd -u $MY_ADMIN -p $MY_CREDS activationkey_list 2>&1 >> $EMAILMSGZ #2>&1 >> $EMAILMSGZ
        echo $NEWNAME >> $EMAILMSGZ
    else
        spacewalk-manage-channel-lifecycle -C -c $i --promote -u $MY_ADMIN -p $MY_CREDS 2>&1 >> $EMAILMSGZ
    fi
done
printf "\n\t `date` \n" >> $EMAILMSGZ
}
#
promote_dev () {
if [[ "`grep 'dev' $MY_CHANLIST`" == "" ]]; then
    clear
    usage
    printf "\n\n\t${LTRED}The '-b' Option MUST be run before any other\n\tthen the '-d'\n\tand then the -p${RESET}\n"
    exit $?
fi
for i in `cat $MY_BASELIST`; do
    if [[ "`grep test-$i $MY_CHANLIST`" == "" ]]; then
                INITRUN=true
        spacewalk-manage-channel-lifecycle -C -c dev-$i --promote -u $MY_ADMIN -p $MY_CREDS 2>&1 >> $EMAILMSGZ
        #NEWNAME=`echo $i | sed -e "s/$i/test-$i/g"`
        NEWNAME="test-$i"
        spacecmd -u $MY_ADMIN -p $MY_CREDS activationkey_create -- -n $NEWNAME -d $NEWNAME -b $NEWNAME 2>&1 >> $EMAILMSGZ
        cat $TMPLATFIL | sed -e s/slartybartfast/$NEWNAME/g > $TMPLATDIR/$NEWNAME-bootstrap.sh
        chmod +x $TMPLATDIR/$NEWNAME-bootstrap.sh
    else
        spacewalk-manage-channel-lifecycle -C -c dev-$i --promote -u $MY_ADMIN -p $MY_CREDS 2>&1 >> $EMAILMSGZ
    fi
done
}
#
promote_test () {
if [[ "`grep 'dev' $MY_CHANLIST`" == "" ]]; then
    clear
    usage
    printf "\n\n\t${LTRED}The '-b' Option MUST be run before any other\n\tthen the '-d'\n\tand then the -p${RESET}\n"
    exit $?
else
    if [[ "`grep 'test' $MY_CHANLIST`" == "" ]]; then
        clear
	usage
        printf "\n\n\t${LTRED}The '-d' Option MUST be run before using the '-p'${RESET}"
        exit $?
    fi

fi
for i in `cat $MY_BASELIST`; do
    if [[ "`grep prod-$i $MY_CHANLIST`" == "" ]]; then
        INITRUN=true
        spacewalk-manage-channel-lifecycle -C -c test-$i --promote -u $MY_ADMIN -p $MY_CREDS 2>&1 >> $EMAILMSGZ
        NEWNAME="prod-$i"
        spacecmd -u $MY_ADMIN -p $MY_CREDS activationkey_create -- -n $NEWNAME -d $NEWNAME -b $NEWNAME 2>&1 >> $EMAILMSGZ
        cat $TMPLATFIL | sed -e s/slartybartfast/$NEWNAME/g > $TMPLATDIR/$NEWNAME-bootstrap.sh
        chmod +x $TMPLATDIR/$NEWNAME-bootstrap.sh
    else
        spacewalk-manage-channel-lifecycle -C -c test-$i --promote -u $MY_ADMIN -p $MY_CREDS 2>&1 >> $EMAILMSGZ
    fi
done
}
#
change_log () {
    if [[ "`find ~/* -name $PROGNAME`" != "" ]]; then
        CPPATH="`find ~/* -name $PROGNAME`"
        clear
        cat $CPPATH | tail -n 30
    else
        printf "\n\tThe $PROGNAME was not found in your PATH [~/*] => It is recommended to have the sym-link to $PROGNAME in [~/bin/]\n"
    fi
}
#
clean_all () {
    printf "\n$LTRED $BOLD !!!! WARNING !!!! \n This will remove ALL cloned channels!\n This will remove ALL activation keys!\n This will remove ALL bootstrap scripts!\n This will remove ALL generated credentials files!\n\t Do you really want to do this?\n [y|N]\n $RESET"
    read CLEANALL
    if [[ $CLEANALL == "y" ]]; then
        if [[ -f $MYCREDFIL ]]; then
            source $MYCREDFIL
        fi
        spacewalk-remove-channel -a "dev*" --unsubscribe
        spacewalk-remove-channel -a "test*" --unsubscribe
        spacewalk-remove-channel -a "prod*" --unsubscribe
        spacecmd activationkey_delete 1-dev*
        spacecmd activationkey_delete 1-test*
        spacecmd activationkey_delete 1-prod*
        rm /srv/www/htdocs/pub/bootstrap/dev*-bootstrap.sh
        rm /srv/www/htdocs/pub/bootstrap/test*-bootstrap.sh
        rm /srv/www/htdocs/pub/bootstrap/prod*-bootstrap.sh
        rm ~/.mgr-sync
        rm ~/bin/.creds.sh
        exit $?
    else
        printf "\n $LTCYN Action canceled by user... Exiting $RESET \n"
        exit $?
    fi
}
#
#####################################################################
#####   Execute Functions
#####################################################################
#
case "$1" in
"-a")
  chk_sutils
  no_opts
  susetrees_clone 2>&1 >> $EMAILMSGZ
  promote_dev 2>&1 >> $EMAILMSGZ
  promote_test 2>&1 >> $EMAILMSGZ
  ;;
"-n")
  chk_sutils
  no_opts
  susetrees_clone 2>&1 >> $EMAILMSGZ
  promote_dev 2>&1 >> $EMAILMSGZ
  ;;
"-p")
  chk_sutils
  no_opts
  promote_test 2>&1 >> $EMAILMSGZ
  ;;
"-d")
  chk_sutils
  no_opts
  promote_dev 2>&1 >> $EMAILMSGZ
  ;;
"-b")
  chk_sutils
  no_opts
  susetrees_clone 2>&1 >> $EMAILMSGZ
  ;;
#
"-h")
  clear
  usage
  exit $?
  ;;
#
"-g")
  gpl_info
  exit $?
  ;;
#
"-r")
  printf "${LTYLLW}The $PROGNAME version is $SCRIPT_RELEASE -\n\treleased on $SCRIPT_RELEASE_DATE ${RESET}\n"
  exit $?
  ;;
#
"-R")
  req_depends
  exit $?
  ;;
#
"-c")
  change_log
  exit $?
  ;;
#
"-x")
  clean_all
  exit $?
  ;;
#
"config")
  chk_sutils
  usage
  exit $?
  ;;
#
*)
  clear
  usage
  exit $?
  ;;
esac
#####################################################################
###     Email & Finalize Log
#####################################################################
if $INITRUN; then
    printf "\n\t${LTCYN}Thank you for using the $PROGNAME script, Release $SCRIPT_RELEASE\n\tThis will require maually adding Child Channels to your Activation Keys in the WebUI${RESET}\n"
    sleep 3
    printf "${LTYLLW}Your activation keys are\n `spacecmd activationkey_list`${RESET}\n"
    tail -n 12 $SYNCLOG
    if $BADPATH; then
#	Adding check for ignoring the script path message
        if [[ "`echo $2`" != "ignore" ]]; then
            chk_path
        fi
    fi
    printf "\n\t${YELLOW}The log for this process can be found at\n ${SYNCLOG}${RESET}\n"
else
    if $BADPATH; then
#	Adding check for ignoring the script path message
        if [[ "`echo $2`" != "ignore" ]]; then
            chk_path
        fi
    fi
    printf "\n\t${LTCYN}Thank you for using the $PROGNAME script, Release $SCRIPT_RELEASE${RESET}\n"
fi
snd_mail
echo "" >> $SYNCLOG
cat $EMAILMSGZ >> $SYNCLOG
printf "\n\tThe following Failure/s occured:\n" >> $SYNCLOG
grep -i 'error' $EMAILMSGZ >> $SYNCLOG
#####################################################################
###	Cleanup & Exit
#####################################################################
rm /tmp/*.sumatmp
exit $?
#
#####################################################################
#####           channellock-promote.sh
#####           08 July, 2014- Shawn Miller
#####   Objective- 1. Clone the Pool for each OS/SP/Arch to
#####			a 'dev' channel ((NEEDS- clones for RedHat))
#####   Objective- 2. Promote each 'dev' to a 'test' channel for non-prod clients
#####   Objective- 3. Promote each 'test' channel to a 'prod' channel for production clients
#####   Objective- 4. The 'dev' channel is where you add/remove	selected and/or custom packages
#####   Objective- 5. Log all results
#####   Objective- 6. Convert all lines to comprehensive variables
#####			to make it portable for any SUMA Server
#####   		Added 'source' for suma-admin credentials
#####   All Objectives Completed-- (except... 42...)
#####    - I only have 22 days remaining on my 60-day free trial, and my 'server' is actually my old desktop gaming machine
#####    - I hope to be finishe with this script before it expires, and I will try to get another one but on a VirtualBox VM instead. 08 July, 2014
#####           Shawn Miller
#####   
#####################################################################
#
##
#################################################################################################################
# KNOWN BUGS													#
#         20 January 2018-
# - Found weird issue where clone/promote does NOT populate the "Patches" in the WebUI. I don't know yet	#
#   if this is 
#     A- Bug with SUSE Manager
#     B- Bug with the 'spacewalk-manage-channel-lifecycle from the spacewalk-utils package.
#     C- Most likely cause- Timing or order of the code in this script
#   The weird part is that running the command a 2nd time DOES populate it.				
#
# - Steps to reproduce
#   1- WebUI=> Notice # of Patches in the SUSE Channel	
#   2- CLI=> Run script with [-b] option, notice the of Patches in matching 'dev' channel is same	#
#   3- CLI=> Run script with [-d] option, notice the of Patches in matching 'test' channel is EMPTY	#
#   4- CLI=> Run script with [-p] option, notice the of Patches in matching 'prod' channel is EMPTY, BUT
#      the Patches in the 'test' channel are now populated???
#   5- CLI=> Run script with [-p] option again, notice the of Patches in matching 'prod' channel is now populated
#         						#
#########################################################
# END OF KNOWN BUGS
#         						#
#########################################################
# CHANGELOG
#########################################################
#                                                       #
###             channellock-promote_4.1		        #
###     This script is for SUSE-Manager to clone        #
###        channels per schedule, and keep them static 	#
###        throughout the Non-Prod Environment, then    #
###        promote that static channel to Production    #
#                       #####                           #
##      Shawn Miller- Sr. Linux Systems Engineer	#
##      11 December 2015 - shawn                        #
##      Modified -- Finalized                           #
##      02 February 2016 - shawn                        #
##      Modified -- Finalized                           #
##      15 December 2016 - shawn                        #
##      Modified -- Finalized                           #
##      29 December 2016 - shawn                        #
##      Apr-May-Jun 2017 - shawn                        #
##      Modified -- Finalized                           #
##      Promoted script to release 4.1.2-02             #
#         Added logic for OS/Release for custom repos   #
#         Moved custom repos function to the sourced    #
#         non-generic '.creds' file                     #
##      Promoted script to release 4.1.3-01             #
#         Added logic for generating required    	#
#         credentials file, now making the script 100%	#
#         portable and transferable- 			#
##      Promoted script to release 4.1.3-02             #
#         generate the credentials password		#
#         variable without printing the input to the	#
#         display- 					#
##      Promoted script to release 4.1.3-03             #
#         Completed the credentials file working	#
#         Now working on autocreation of the bootstrap	#
#         script and the activation keys		#
##      Promoted script to release 4.1.3-04             #
#         Completed the bootstrap script creation 	#
##      Promoted script to release 4.1.4-01             #
#         22 July 2017 					#
#         Completed the automation and portability	#
#         Completed all needed for complete portability	#
##      Promoted script to release 4.1.4-02             #
#         22 July 2017 					#
#         Found a bug with the dev base channel		#
#         fixed it 					#
##      Promoted script to release 4.1.4-04             #
#         02 August 2017 				#
#         Added disclaimer to the gpl [-g] option	#
##      Promoted script to release 4.1.4-05             #
#         13 August 2017 				#
#         Added mgr-sync & spacewalk-repo-sync 		#
#         to no_opts					#
##      Promoted script to release 4.1.4-06             #
#         20 August 2017 				#
#         Added Separate clone for PCI/Scope 		#
##      Promoted script to release 4.1.4-07             #
#         20 August 2017 				#
#         Tested -06- next changes here 		#
#         09 September 2017 				#
#         Found bug, need orig bootstrap script created #
#         Fixed bug above. Found a few more and fixed 	#
#         them, but, I still see onethat I can't	#
#         Identify. I will keep looking and fix in 08	#
##      Promoted script to release 4.1.4-08             #
#         10 September 2017 				#
#         found the issue from 09- creds not being 	#
#         passed in mgr-sync -s the first time, added	#
#         logic to replace the empty fields with the 	#
#         credentials from the .creds file variables.	#
#         Not tested yet- 				#
#         Fixed and tested the mgr-sync adding values	#
#         to the first run of the script.		#
##      Promoted script to release 4.1.4-09             #
#         30 September 2017				#
#         Added -r Relase Version to help		#
#         Cleaned up the Options descriptions		#
#         Added a check/create for bootstrap repos	#
#         - Only works for initial, manual for new	#
#         07 October 2017				#
#         Editing to remove all refference to Custom	#
#         funcrions or calls.				#
#         08 October 2017				#
#         Found missing variable in create-bootstrap	#
#         and fixed it, needs testing.			#
#         Removing PCI clone, not needed.		#
##      Promoted script to release 4.1.4-10             #
#         08 October 2017				#
#         Cleaned up the -s Custom option and the Usage	#
##      Promoted script to release 4.1.4-11             #
#         08 October 2017				#
#         Added Check for root & set error exit		#
#         Fixed the log output of the script name	#
#         Edited un-needed statements in initrun state	#
#         Seeing an issue in 10 that tries to duplicate	#
#         the test activation key, can't find issue yet	#
#         Found the issue, dup'd the dev code and fixed	#
#         Promoting to 12 to push 11 to Latest for this	#
#         Issue is a big issue and wastes run time	#
##      Promoted script to release 4.1.4-12             #
#         08 October 2017				#
#         10 October 2017 - General cleanup unused code	#
#         Moved changelog to bottom of script		#
#         16 October 2017 - Move Sript Details to top	#
##      Promoted script to release 4.1.4-13             #
#         22 October 2017				#
#         Need to NOT use a static file moved to ~/bin/	#
#         It needs to be a symlink to githup Latest	#
#         Have not begun yet, just recognized the need	#
#         - Adding echo to suggest how this should be	#
#         - structured in the PATH to be sym in ~/bin/	#
#         - to ~/SUSEManager/Latest_Stable/$PROGNAME	#
#         - to always have the 'Latest_Stable'		#
#         Completed and tested recommended PATH		#
##      Promoted script to release 4.1.4-14             #
#         22 October 2017				#
#         Added Cleanup logs to archive and remove +90	#
#         23 October 2017 found another call to local	#
#         admin user and replaces with variable		#
#         Added colors to variables and echos to user	#
#         No functionality changes so making 14 Latest	#
##      Promoted script to release 4.1.4-15             #
#         23 October 2017				#
#         Sent error output for 'find' to /dev/null	#
#         24 October 2017, fixed syntax error for the 	#
#         sym-link creation command recommendation	#
#         Promoting to Latest for syntax error		#
##      Promoted script to release 4.1.4-16             #
#         25 October 2017				#
#         Copied the 4_1_4-16 to 4_1_4-16_test to test	#
#	  changing ALL code 'printf' statements to 	#
#	  'printf' statements as per recommendations 	#
#	  from 'real' coders 8|				#
#         27 October 2017 = Tested and works, 		#
#	  Promoting to Latest				#
##      Promoted script to release 4.1.4-17             #
#         27 October 2017				#
#         04 November 2017- changed spacewalk-repo-sync	#
#         command to cleaner output to display - 	#
#	  /usr/bin/python -u /usr/bin/spacewalk-repo- \	#
#	  sync --channel $i --type yum --non-interactive#
#         Changed the date format for the log, and 	#
#         the time [mainly for my testing purposes]	#
#         Added Release Date to the -r Option		#
#         Fix typo in changelog- activtion > activation	#
##      Promoted script to release 4.1.4-18		#
#         04 November 2017-				#
#         Added 'Optional- Un-Comment to enable RHEL'	#
#         15 Nov 2017-					#
#         Began changing the color variables to 	#
#         standard tput/setaf instead of custom 	#
#         declared variables and escaped characters	#
#         -Completed need to test full functionality	#
#         16 Nov 2017-					#
#         Uncommented 'Optional- Comment/Un-Comment	#
#         to disable/enable RHEL, Promote to apply	#
##      Promoted script to release 4.1.4-19		#
#         16 November 2017-				#
#         Adding check for ignoring the script path 	#
#         message					#
#         Added a space between 'for' & admin-name	#
#         Added printout of Activation keys if created	#
#         12 December 2017-				#
#         Added Color Variables and changed the 'USAGE' #
#         Options colors, no real code impact           #
##      Promoted script to release 4.1.4-20		#
#         16 December 2017-				#
#         Removed the '-n' option from the Usage to	#
#         simplify the options, I never used it anyway	#
#         Also found a typo in parms- s/s/r		#
##      Promoted script to release 4.1.4-21		#
#         16 December 2017-				#
#         For fixing issues found in 20			#
#         Cleaned up the Options/Usage verbage		#
#         Next, I want to fork this script to a new 	#
#         name, 'sumachan' is one suggestion, the other	#
#         may require approval, incorporate it as	    #
#         'spacewalk-lifecycle'				            #
#         	!!!!!!!!!!!!!!!!!			                #
#         !!! 19 December 2017- This thread will no 	#
#         longer be maintained or supported as		    #
#         'channellock-promote_4.n.n-nn'- I am making 	#
#         this release the final Latest_Stable and then	#
#         forking to a new name and revision as in	    #
#         'suma-channel-mgr_5.0.0-01'			        #
#         	Peace, C4				                    #
#                                                       #
##      Forked to suma-channel-mgr 19 Dec, 2017		#
##      Promoted script to release 5.0.0-01		#
#         19 December 2017-				#
#         General cleanup from the fork and took the 	#
#         [-a] option out of the 'Usage' output	but 	#
#         left the function in place for later		#
#         Changed the script-path recommends output     #
#         23 December 2017- Forked and changed names	#
##      Promoted script to release 5.0.0-02		#
#         23 December 2017-				#
#         Structuring new repos with new names for	#
#         future dev. Forked on github to new name	#
#         suma-channel-mgr_5, the SUSEManager repo 	#
#         will be Archived				#
##      Promoted script to release 5.0.0-03		#
#         23 December 2017-				#
#         Structuring new repos with names and path	#
#         testing new auto promote script		#
##      Promoted script to release 5.0.0-04		#
#         23 December 2017-				#
#         Final fork testing and promotions complete	#
#         Added link to full GPL to the GNU/GPL		#
#         Changed variable for REPOPATH	for namechange	#
#         - Next major change => Move the mgr-sync and  #
#         - repo-sync to the susetrees function, it     #
#         - does not need to run for test/prod.         #
#         Moved the checks to the susetrees, now need	#
#         to change how the creds file is generated	#
#         since it prompts for mgr-sync any way.	#
#         - Moved mgr-sync and reposync to susetrees	#
#         only, And changed how the creds file is gen-	#
#         erated, from the .mgr-sync file creation	#
#         Testing and will promote if successful	#
#         Added 'clear' to USAGE variable		#
#         going to test as-is and then promote 05 but	#
#         going to optimize the cred file create for	#
#         a simpler code in 06				#
#         tested, corrected, and retested- success	#
##      Promoted script to release 5.0.1-01		#
#         04 January 2018-				#
#         17 Jan 2018- changed emailaddress to 2 words	#
#         added sleep 3 after WebUI notification	#
#         Corrected typo 'istalled' to installed	#
#         Added error_exit to action items		#
#         20 January 2018-				#
# 	  - Added 'KNOWN BUGS' to before changelog	#
# 	  - Added [-c] CHANGE Prints the last 30 lines	#
#	   of the Change-Log and exits to Usage/Options	#
#         20 January 2018- Promoted 5.0.1-01 to Latest	#
##      Promoted script to release 5.0.1-02		#
#         20 January 2018- (My 52nd Birthday)		#
#         Commented check for RHEL, not priority atm	#
#         Found issue- mistakenly added error_exit to	#
#         all action case statements- this breakes it!	#
#         Fixed and promote 5.0.1-02 to Latest		#
##      Promoted script to release 5.0.1-03		#
#         22 January 2018-				#
#         KEY creation- changed grep dev to grep dev-$i	#
#         -Tested and working- will now create new KEYS	#
#         -as new SUSE products are added		#
#         Changed how the errors are logged- will test	#
#         FINALLY!!! I finally isolated that irritating	#
#         bug where it allways runs as INITRUN is true	#
#         but only in test and prod?? will run full 	#
#         tests on first and continues runs tomorrow	#
#         -After testing the above bug-fix, discovered 	#
#         a bigger issue, and a cleaner way to generate	#
#         test and prod activation keys, will test full	#
#         Fully tested, and with the major changes to	#
#         generation methods I must rev to next major	#
#         revision- 5.0.2-01 is Latest_Stable		#
##      Promoted script to release 5.0.2-02		#
#         22 January 2018-				#
#         Added Description link to github and moved	#
#         former to Requirements.			#
#         Added a [-x] option to remove all cloned 	#
#         channels, activation keys, and all creds to 	#
#         start all over from scratch.			#
#         Still having issue with [-b] not populating	#
#         the "Patches" ... Very odd that it used to...	#
#         It populates dev only after running the [-d]	#
#         -OK, discovered that starting from scratch 	#
#         does populate the patches, the next run does 	#
#         not, but running same again does- weird...	#
#         - - adding 2nd run to temp resolve this...	#
#         Added a new file to the repo to track details	#
#         of Bugs- ~/Tools/Bugs.txt- Added confirmation	#
#         to the [-x] option before wiping all- I may 	#
#         change that to each individual in future	#
#         -I am considering that this 'Bug' is a SUSE 	#
#	  Manager or a spacewalk-manage-channel-	#
#	  lifecycle issue and NOT my script or code 	#
#	  within it- I may submit a bugzilla to SUSE 	#
#	  for this.					#
#         Promoting 5.0.2-02 to Latest			#
##      Promoted script to release 5.0.2-03		#
#         11 Febuary 2018-				#
#         01 March 2018- replaced /root	with ~/ in the 	#
#         logging section for the path			#
#         27 May 2018- 					#
#         27 May 2018- Added Alpha/Beta/Prod dates	#
#         to the GPL 					#
#         27 May 2018-					#
#         Added logic to check for new bootstrap	#
#         Repos and create if missing- needs testing	#
#         Also- Found NEW error in the promote test to	#
#         prod- mistyped variable????			#
##      Promoted script to release 5.0.2-04		#
#         27 May 2018-					#
##      Promoted script to release 5.1.0-01		#
#         02 Sep 2018- Begin total re-write		#
#         Changing format of functions, Variable, etc.	#
#         Re-Writing for clean script witing and	#
#         efficiency, Re-Do-ing EVERYTHING.		#
#         Added a 'config' option for initial setup	#
#         clean all functions, variables...		#
#                                                       #
#########################################################
# END OF CHANGELOG
