#!/bin/bash
#
#####################################################################
#####	Full changelog and revision history at bottom of script
#####################################################################
#
#####################################################################
#####   Setting Script Variables
#####################################################################
#
	SCRIPT_RELEASE="4.1.4-16"
	SCRIPT_RELEASE_DATE="27 October 2017"
	PROGNAME=$(basename $0)
	REPOPATH=~/SUSEManager
	LTSTSTAB=$REPOPATH/Latest_Stable
	PROGPATH=~/bin
	BADPATH=false
	MYCREDFIL=$PROGPATH/.creds.sh
	SYNCLOG=~/reposync.log
	TDATE=`date +%Y-%m-%d`
	RDATE=`date +%Y%m%d`
	LDATE=`date +%d-%b-%Y`
	HOSTA=`hostname`
	INITRUN=false
	TMPLATDIR=/srv/www/htdocs/pub/bootstrap
	TMPLATFIL=/srv/www/htdocs/pub/bootstrap/template.sh
	touch /tmp/tmp.sumatmp
	EMAILMSGZ=/tmp/tmp.sumatmp
	echo "Running $PROGNAME $1 Initial Process for $RDATE $2" > $EMAILMSGZ
###	Cleanup logs
	if [[ "`find /root/reposync.log -size +1M`" != "" ]]; then
		mv $SYNCLOG /root/reposync_$LDATE-log.log
	fi
	find /root/reposync_*-log.log -mtime +90 -exec rm {} \; 2>/dev/null
### Colors ###################
	RED='\e[0;31m'
	LTRED='\e[1;31m'
	BLUE='\e[0;34m'
	LTBLUE='\e[1;34m'
	GREEN='\e[0;32m'
	LTGREEN='\e[1;32m'
	ORANGE='\e[0;33m'
	YELLOW='\e[1;33m'
	CYAN='\e[0;36m'
	LTCYAN='\e[1;36m'
	PURPLE='\e[0;35m'
	LTPURPLE='\e[1;35m'
	GRAY='\e[1;30m'
	LTGRAY='\e[0;37m'
	WHITE='\e[1;37m'
	NC='\e[0m'
##############################
#
#####################################################################
#####                   GNU/GPL Info                                
#####################################################################
#
function gpl_info
{
printf "\n${LTCYAN}
####c4#############################################################################
###                                                                             ###
##                      GNU/GPL Info                                             ##
##              channellock-promote.sh ver-4.1                                   ##
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
###                                                                             ###
####w#################################b######################################c#####${NC}\n"
}
#
#####################################################################
#####	Checking for root, setting error exit
#####################################################################
#
function error_exit
{
	printf "${LTRED} ${PROGNAME}: ${1:-"you are not root, please run as root"}${NC}" >&2
	exit 1
}
###
[[ "$UID" == "0" ]] && : || error_exit
#
###	BEGIN 4.1.4-13 need for making symlink NOT static
if [[ ! -L $PROGPATH/$PROGNAME ]]; then
	BADPATH=true
	printf "${ORANGE}Script PATH Not Recommended${NC}" >> $EMAILMSGZ
fi
function chk_path
{
	if [[ ! -L $PROGPATH/$PROGNAME ]]; then
		BADPATH=true
		printf "${LTCYAN}\n\n\t#################################################################\n\t# This process is designed to always have the latest release\t#\n\t# It is recommended that your cloned repo be at ~/SUSEManager\t#\n\t# And that you create a sym-link to the Latest, as in so:\t#\n\t# 'cd ~/bin' and create a sym-link to:\t\t\t\t#\n\t# $LTSTSTAB \t\t\t\t#\n\t# ln -s $LTSTSTAB/channellock-promote.sh \\\#\n\t# channellock-promote.sh\t\t\t\t\t#\n\t#################################################################\n\n${NC}"
		sleep 15
		echo ""
	fi
}
#	chk_path
###	END 4.1.4-13 need for making symlink NOT static
#
#####################################################################
#####   Adjusted for portability, check for required spacewalk-utils
#####################################################################
#
function chk_sutils
{
#
	if [[ "`rpm -qa | grep spacewalk-utils`" == "" ]]; then
		zypper se spacewalk-utils
		printf "${LTCYAN}\n\tThis process requires the 'spacewalk-utils' package and is not installed...${NC}\n\t${LTCYAN}Would you like to install it now?\n\t[y/n]\n${NC}"
		read INSTCHOICE
		if [[ "`echo $INSTCHOICE`" == "n" ]]; then
			printf "${LTRED}\nexiting...\n${NC}"
			exit $?
		else
			zypper in -y spacewalk-utils
			echo "Installed spacewalk-utils" >> $EMAILMSGZ
		fi
	fi
}
#
#####################################################################
#####   Adjusted for portability, source the local credentials
#####################################################################
#
function chk_creds
{
	if [[ -f $MYCREDFIL ]]; then
		source $MYCREDFIL
	else
		echo ""
		printf "${ORANGE}\n\tYou need a LOCAL CREDENTIALS FILE!!!\n\tThe default is ~/bin/.creds.sh --\n\tCreate that file, or edit this script to remove the chk_creds funtion call\n\tfrom the Case Statement sections and pass your credentials\n\tdirectly in the clone/promote functions${NC} ${LTRED}[NOT RECOMMENDED!!!]${NC}\n\t${ORANGE}The creds.sh file should look like the following--${NC}\n${CYAN}MY_ADMIN='suma-admin-username'\nMY_CREDS='suma-admin-password'\nEMAILG='email-or-group,additional-email-or-group' [Separated by commas and NO spaces]\n${NC}"
		echo ""
		printf "${ORANGE}\n\n... You don't seem to have a credentials file,${NC} ${CYAN}do you want to do that now?${NC}\n\t${CYAN}[${NC}${GREEN}y${NC}${CYAN}/${NC}${LTRED}n${NC}${CYAN}]${NC}\n"
		read SETNOW
		if [[ "`echo $SETNOW`" != "y" ]]; then
        		printf "$USAGE" | less
		        exit $?
		fi
		if [[ "`echo $SETNOW`" == "y" ]]; then
			printf "\n${PURPLE}Type the username of the SUMA Administrator${NC}\n"
			read MYADMIN
			my_user="MY_ADMIN='$MYADMIN'"
			printf "\n${PURPLE}Type the password for${NC}${CYAN} $MYADMIN${NC}\n"
		        read -s MYPASS
			my_pass="MY_CREDS='$MYPASS'"
			printf "\n${PURPLE}Type the emailaddress for notifications${NC}\n"
			read MYMAIL
			my_mail="EMAILG='$MYMAIL'"
			touch $MYCREDFIL
			echo $my_user >> $MYCREDFIL
			echo $my_pass >> $MYCREDFIL
			echo $my_mail >> $MYCREDFIL
			chmod 700 $MYCREDFIL
			source $MYCREDFIL
			printf "\n\t${CYAN}Your new credentials file has been successfully created...\n\tIf you mis-typed or need to change the password, \n\tit can be found at $MYCREDFIL${NC}\n"
			echo "Credentials file created" >> $EMAILMSGZ
		fi
	fi
}
#
#####################################################################
#####   Setting Options
#####################################################################
#
	USAGE="\n\t${CYAN}This process requires 1 (one) parameter -- [a|b|d|n|p|h|g|s]\nInitially, these MUST be run in the following order-\n\t$PROGNAME -b\n\t$PROGNAME -d\n\t$PROGNAME -p\nOptions\n###\t[-b]\tBase-Pool\tClones the SUSE base pool trees to 'dev' channels\n###\t[-d]\tPromote-dev\tPromotes the 'dev' channel to the 'test' channel\n###\t[-n]\tNon-Prod\tDoes both -b and -d\n###\t[-p]\tProduction\t Promotes 'test' to 'Prod'\n###\t[-a]\tALL\t\tDoes all the Options\n###\t[-h]\tHelp\t\tPrints this list and exits\n###\t[-g]\tGPL\t\tPrints the GPL info and exits\n###\t[-r]\tRelease\t\tPrints the Current Release Version and exits\n\n\tThis Clone/Promote process requires the SUMA Admin account username\n\tand password to be issued, for security and portability purposes this\n\trequires a local credentials file [Default = /root/bin/.creds.sh], this file is \n\t'sourced' for the user/pass required VARIABLES and has the following\n\tstructure with NO empty lines or white-space--\nMY_ADMIN='suma-admin-username'\nMY_CREDS='suma-admin-password'\nEMAILG=email-or-group,additional-email-or-group [Separated by commas and NO spaces]\n\n\tThis file can also be used to add Custom function calls to\n\tadd custom repositories and packages.\n\nType 'q' to exit${NC}\n"

#
#####################################################################
###	Begin logging
#####################################################################
#
printf "\n#########################################################\n#\n#    $TDATE -- Executing $PROGNAME Script\n#\n#########################################################\n" >> $EMAILMSGZ
#
#####################################################################
#####   Setting Functions
#####################################################################
#
function no_opts
{
spacecmd -u $MY_ADMIN -p $MY_CREDS softwarechannel_listbasechannels | grep ^sle > /tmp/mybaselist.sumatmp
	MY_BASELIST=/tmp/mybaselist.sumatmp
spacecmd -u $MY_ADMIN -p $MY_CREDS softwarechannel_listbasechannels | grep -v ^sle | grep -v ^suse | grep -v ^rhe > /tmp/mychanlist.sumatmp
	MY_CHANLIST=/tmp/mychanlist.sumatmp
if [[ ! -f ~/.mgr-sync ]]; then
	mgr-sync -s refresh
	sed -i "s/mgrsync.user \= \"\"/mgrsync.user \= $MY_ADMIN/" ~/.mgr-sync
	sed -i "s/mgrsync.password \= \"\"/mgrsync.password \= $MY_CREDS/" ~/.mgr-sync
else
	if [[ "`cat ~/.mgr-sync | grep $MY_ADMIN`" == "" ]]; then
		sed -i "s/mgrsync.user \= \"\"/mgrsync.user \= $MY_ADMIN/" ~/.mgr-sync
		sed -i "s/mgrsync.password \= \"\"/mgrsync.password \= $MY_CREDS/" ~/.mgr-sync
	fi
fi
mgr-sync -s refresh 2>&1 >> $EMAILMSGZ
for i in `cat $MY_BASELIST`; do
	spacewalk-repo-sync --channel $i
done
#####################################################################
#####	Check for bootstrap repo/s - this will only create the 
#####	initial repos, manual creation for new OSs/releases [at this rv]
#####################################################################
if [[ ! -d /srv/www/htdocs/pub/repositories ]]; then
	for b in `mgr-create-bootstrap-repo --list | awk '{print $2}'`; do mgr-create-bootstrap-repo --create=$b ; done
fi

}
function snd_mail
{
        SUBJECT="$HOSTA -- sync-channels script $RDATE"
        FROMA=$MY_ADMIN@$HOST
        /usr/bin/mailx -s "$SUBJECT" "$EMAILG" -f $FROMA < $EMAILMSGZ
}
#
function susetrees_clone
{
for i in `cat $MY_BASELIST`; do
	if [[ "`grep 'dev' $MY_CHANLIST`" == "" ]]; then
		INITRUN=true
		NEWNAME=`echo $i | sed -e "s/$i/dev-$i/g"`
		spacewalk-manage-channel-lifecycle -C -c $i --init -u $MY_ADMIN -p $MY_CREDS 2>&1 >> $EMAILMSGZ
		spacecmd -u $MY_ADMIN -p $MY_CREDS activationkey_create -- -n $NEWNAME -d $NEWNAME -b $NEWNAME
		if [[ -f $TMPLATFIL ]]; then
			cat $TMPLATFIL | sed -e s/slartybartfast/$NEWNAME/g > $TMPLATDIR/$NEWNAME-bootstrap.sh
			chmod +x $TMPLATDIR/$NEWNAME-bootstrap.sh
		else
			mgr-bootstrap
			cat $TMPLATDIR/bootstrap.sh | sed -e 's/^ACTIVATION_KEYS\=/ACTIVATION_KEYS\=1-slartybartfast/g' > $TMPLATFIL
			cat $TMPLATFIL | sed -e s/slartybartfast/$NEWNAME/g > $TMPLATDIR/$NEWNAME-bootstrap.sh
			chmod +x $TMPLATDIR/$NEWNAME-bootstrap.sh
		fi
		spacecmd -u $MY_ADMIN -p $MY_CREDS activationkey_list 2>&1 >> $EMAILMSGZ
		echo $NEWNAME >> $EMAILMSGZ
	else
		spacewalk-manage-channel-lifecycle -C -c $i --promote -u $MY_ADMIN -p $MY_CREDS 2>&1 >> $EMAILMSGZ
	fi
done
}
#
function promote_dev
{
if [[ "`grep 'dev' $MY_CHANLIST`" == "" ]]; then
	printf "$USAGE\n\n\t${RED}The '-b' Option MUST be run before any other\n\tthen the '-d'\n\tand then the -p${NC}\n"
	exit $?
fi
for d in `grep 'dev' $MY_CHANLIST`; do
	if [[ "`grep 'test' $MY_CHANLIST`" == "" ]]; then
                INITRUN=true
		spacewalk-manage-channel-lifecycle -C -c $d --promote -u $MY_ADMIN -p $MY_CREDS 2>&1 >> $EMAILMSGZ
		NEWNAME="`echo $d | sed -e s/dev/test/g`"
		spacecmd -u $MY_ADMIN -p $MY_CREDS activationkey_create -- -n $NEWNAME -d $NEWNAME -b $NEWNAME 
		cat $TMPLATFIL | sed -e s/slartybartfast/$NEWNAME/g > $TMPLATDIR/$NEWNAME-bootstrap.sh
		chmod +x $TMPLATDIR/$NEWNAME-bootstrap.sh
	else
		spacewalk-manage-channel-lifecycle -C -c $d --promote -u $MY_ADMIN -p $MY_CREDS 2>&1 >> $EMAILMSGZ
	fi
done
}
#
function promote_test
{
if [[ "`grep 'dev' $MY_CHANLIST`" == "" ]]; then
	printf "$USAGE\n\n\t${RED}The '-b' Option MUST be run before any other\n\tthen the '-d'\n\tand then the -p${NC}\n"
	exit $?
else
	if [[ "`grep 'test' $MY_CHANLIST`" == "" ]]; then
        	printf "$USAGE\n\n\t${RED}The '-d' Option MUST be run before using the '-p'${NC}"
	        exit $?
	fi

fi
for t in `grep 'test' $MY_CHANLIST`; do
	if [[ "`grep 'prod' $MY_CHANLIST`" == "" ]]; then
                INITRUN=true
        	spacewalk-manage-channel-lifecycle -C -c $t --promote -u $MY_ADMIN -p $MY_CREDS 2>&1 >> $EMAILMSGZ
		NEWNAME="`echo $t | sed -e s/test/prod/g`"
		spacecmd -u $MY_ADMIN -p $MY_CREDS activationkey_create -- -n $NEWNAME -d $NEWNAME -b $NEWNAME 
		cat $TMPLATFIL | sed -e s/slartybartfast/$NEWNAME/g > $TMPLATDIR/$NEWNAME-bootstrap.sh
		chmod +x $TMPLATDIR/$NEWNAME-bootstrap.sh
	else
        	spacewalk-manage-channel-lifecycle -C -c $t --promote -u $MY_ADMIN -p $MY_CREDS 2>&1 >> $EMAILMSGZ
	fi
done
}
#
#####################################################################
#####	Disclaimer Statement
#####################################################################
#
function dis_claimer
{
clear
printf "${RED}
\n\t\t\t\t\t\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
\t\t\t\t\t\t\t=\tLet Me Be Perfectly Clear       =
\t\t\t\t\t\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n
${NC}"
sleep 1
clear
printf "${RED}
\n\t\t\t\t\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
\t\t\t\t\t\t=\tLet Me Be Perfectly Clear       =
\t\t\t\t\t\t=\tI do NOT claim to be a coder    =
\t\t\t\t\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n
${NC}"
sleep 2
clear
printf "${RED}
\n\t\t\t\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
\t\t\t\t\t=\tLet Me Be Perfectly Clear       =
\t\t\t\t\t=\tI do NOT claim to be a coder    =
\t\t\t\t\t=\tI know my code is UGLY and      =
\t\t\t\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n
${NC}"
sleep 2
clear
printf "${RED}
\n\t\t\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
\t\t\t\t=\tLet Me Be Perfectly Clear       =
\t\t\t\t=\tI do NOT claim to be a coder    =
\t\t\t\t=\tI know my code is UGLY and      =
\t\t\t\t=\tSloppy, BUT, it WORKS as        =
\t\t\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n
${NC}"
sleep 2
clear
printf "${RED}
\n\t\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
\t\t\t=\tLet Me Be Perfectly Clear       =
\t\t\t=\tI do NOT claim to be a coder    =
\t\t\t=\tI know my code is UGLY and      =
\t\t\t=\tSloppy, BUT, it WORKS as        =
\t\t\t=\tIntended! I know most of you    =
\t\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n
${NC}"
sleep 2
clear
printf "${RED}
\n\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
\t\t=\tLet Me Be Perfectly Clear       =
\t\t=\tI do NOT claim to be a coder    =
\t\t=\tI know my code is UGLY and      =
\t\t=\tSloppy, BUT, it WORKS as        =
\t\t=\tIntended! I know most of you    =
\t\t=\tThat examine it could write     =
\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n
${NC}"
sleep 2
clear
printf "${RED}
\n\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
\t=\tLet Me Be Perfectly Clear       =
\t=\tI do NOT claim to be a coder    =
\t=\tI know my code is UGLY and      =
\t=\tSloppy, BUT, it WORKS as        =
\t=\tIntended! I know most of you    =
\t=\tThat examine it could write     =
\t=\tIt better and more efficient.   =
\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n
${NC}"
sleep 2
clear
printf "
\n\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
\t=\tLet Me Be Perfectly Clear       =
\t=\tI do NOT claim to be a coder    =
\t=\tI know my code is UGLY and      =
\t=\tSloppy, BUT, it WORKS as        =
\t=\tIntended! I know most of you    =
\t=\tThat examine it could write     =
\t=\tIt better and more efficient.   =
\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n
"
sleep .5
clear
sleep .5
printf "
\n\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
\t=\tLet Me Be Perfectly Clear       =
\t=\tI do NOT claim to be a coder    =
\t=\tI know my code is UGLY and      =
\t=\tSloppy, BUT, it WORKS as        =
\t=\tIntended! I know most of you    =
\t=\tThat examine it could write     =
\t=\tIt better and more efficient.   =
\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n
"
sleep .5
clear
sleep .5
printf "
\n\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
\t=\tLet Me Be Perfectly Clear       =
\t=\tI do NOT claim to be a coder    =
\t=\tI know my code is UGLY and      =
\t=\tSloppy, BUT, it WORKS as        =
\t=\tIntended! I know most of you    =
\t=\tThat examine it could write     =
\t=\tIt better and more efficient.   =
\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n
"
sleep .5
clear
sleep .5
printf "
\n\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
\t=\tLet Me Be Perfectly Clear       =
\t=\tI do NOT claim to be a coder    =
\t=\tI know my code is UGLY and      =
\t=\tSloppy, BUT, it WORKS as        =
\t=\tIntended! I know most of you    =
\t=\tThat examine it could write     =
\t=\tIt better and more efficient.   =
\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n
"
sleep .5
clear
sleep .5
printf "${CYAN}
\n\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
\t=\tLet Me Be Perfectly Clear       =
\t=\tI do NOT claim to be a coder    =
\t=\tI know my code is UGLY and      =
\t=\tSloppy, BUT, it WORKS as        =
\t=\tIntended! I know most of you    =
\t=\tThat examine it could write     =
\t=\tIt better and more efficient.   =
\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n
${NC}"
sleep 5
}
#
#####################################################################
#####   Execute Functions
#####################################################################
#
case "$1" in
"-a")
  chk_sutils
  chk_creds
  no_opts
  susetrees_clone 2>&1 >> $EMAILMSGZ
  promote_dev 2>&1 >> $EMAILMSGZ
  promote_test 2>&1 >> $EMAILMSGZ
  ;;
"-n")
  chk_sutils
  chk_creds
  no_opts
  susetrees_clone 2>&1 >> $EMAILMSGZ
  promote_dev 2>&1 >> $EMAILMSGZ
  ;;
"-p")
  chk_sutils
  chk_creds
  no_opts
  promote_test 2>&1 >> $EMAILMSGZ
  ;;
"-d")
  chk_sutils
  chk_creds
  no_opts
  promote_dev 2>&1 >> $EMAILMSGZ
  ;;
"-b")
  chk_sutils
  chk_creds
  no_opts
  susetrees_clone 2>&1 >> $EMAILMSGZ
  ;;
#
"-h")
  printf "$USAGE" | less
  printf "$USAGE"
  exit $?
  ;;
#
"-g")
  dis_claimer
  gpl_info
  exit $?
  ;;
#
"-r")
  printf "${CYAN}The $PROGNAME version release is $SCRIPT_RELEASE${NC}\n"
  exit $?
  ;;
#
*)
  printf "$USAGE" | less
  exit $?
  ;;
esac
#####################################################################
###     Email & Finalize Log
#####################################################################
printf "\n\tThe following Failure/s occured:\n" >> $EMAILMSGZ
grep -i 'error' $EMAILMSGZ >> $EMAILMSGZ
if $INITRUN; then
	printf "\n\t${LTBLUE}Thank you for using the $PROGNAME script, Release $SCRIPT_RELEASE\n\tThis will require maually adding Child Channels to your Activation Keys in the WebUI${NC}\n"
	tail -n 12 $SYNCLOG
	if $BADPATH; then
		chk_path
	fi
	printf "\n\t${LTBLUE}The log for this process can be found at $SYNCLOG${NC}\n"
else
	if $BADPATH; then
		chk_path
	fi
	printf "\n\t${LTBLUE}Thank you for using the $PROGNAME script, Release $SCRIPT_RELEASE${NC}\n"
fi
snd_mail
echo "" >> $SYNCLOG
cat $EMAILMSGZ >> $SYNCLOG
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
#####   
#####           Shawn Miller
#####   
#####################################################################
#
##
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
#         the 'test' activtion key, can't find issue yet#
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
#                                                       #
#########################################################
#
