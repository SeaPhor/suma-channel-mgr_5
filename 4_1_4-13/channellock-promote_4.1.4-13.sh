#!/bin/bash
#
#####################################################################
#####	Full changelog and revision history at bottom of script
#####################################################################
#
#####################################################################
#####   Setting Script Details
#####################################################################
#
        SCRIPT_RELEASE="4.1.4-13"
        SCRIPT_RELEASE_DATE="?? October 2017"
        PROGNAME=$(basename $0)
#
#####################################################################
#####                   GNU/GPL Info                                
#####################################################################
#
function gpl_info
{
echo -e "\n
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
####w#################################b######################################c#####\n"
}
#
#####################################################################
#####	Checking for root, setting error exit
#####################################################################
#
function error_exit
{
	echo "${PROGNAME}: ${1:-"you are not root, please run as root"}" >&2
	exit 1
}
###
[[ "$UID" == "0" ]] && : || error_exit
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
		echo -e "\n\tThis process requires the 'spacewalk-utils' package and is not installed...\n\tWould you like to install it now?\n\t[y/n]\n"
		read INSTCHOICE
		if [[ "`echo $INSTCHOICE`" == "n" ]]; then
			echo -e "\nexiting...\n"
			exit $?
		else
			zypper in -y spacewalk-utils
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
	PROGPATH=~/bin
	MYCREDFIL=$PROGPATH/.creds.sh
	if [[ -f $MYCREDFIL ]]; then
		source $MYCREDFIL
  		SYNCLOG=~/reposync.log
	else
		echo -e "\n\tYou need a LOCAL CREDENTIALS FILE!!!\n\tThe default is ~/bin/.creds.sh --\n\tCreate that file, or edit this script to remove the chk_creds funtion call\n\tfrom the case statement sections and pass your credentials\n\tdirectly in the clone/promote functions [NOT RECOMMENDED!!!]\n\tThe creds.sh file should look like the following--\nMY_ADMIN='suma-admin-username'\nMY_CREDS='suma-admin-password'\nEMAILG='email-or-group,additional-email-or-group' [Separated by commas and NO spaces]\n"
		echo -e "\n\n... You don't seem to have a credentials file, do you want to do that now?\n\t[y/n]\n"
		read SETNOW
		if [[ "`echo $SETNOW`" == "n" ]]; then
        		echo -e "$USAGE" | less
		        exit $?
		fi
		if [[ "`echo $SETNOW`" == "y" ]]; then
			echo -e "\nType the username of the SUMA Administrator\n"
			read MYADMIN
			my_user="MY_ADMIN='$MYADMIN'"
			echo -e "\nType the password for $MYADMIN\n"
		        read -s MYPASS
			my_pass="MY_CREDS='$MYPASS'"
			echo -e "\nType the emailaddress for notifications\n"
			read MYMAIL
			my_mail="EMAILG='$MYMAIL'"
			touch $MYCREDFIL
			echo $my_user >> $MYCREDFIL
			echo $my_pass >> $MYCREDFIL
			echo $my_mail >> $MYCREDFIL
			chmod 700 $MYCREDFIL
			source $MYCREDFIL
			SYNCLOG=~/reposync.log
			echo -e "\n\tYour new credentials file has been successfully created...\n\tIf you mis-typed or need to change the password, \n\tit can be found at $MYCREDFIL\n"
		fi
###	BEGIN 4.1.4-13 need for making symlink NOT static
#		if [[ ! -f $PROGPATH/$PROGNAME ]]; then
#			cp $PWD/$PROGNAME $PROGPATH/.
#		fi
###	END 4.1.4-13 need for making symlink NOT static
	fi
}
#
#	Log Variable
	SYNCLOG=~/reposync.log
#
#####################################################################
#####   Setting Options & Script Variables
#####################################################################
#
	USAGE="\n\tThis process requires 1 (one) parameter -- [a|b|d|n|p|h|g|s]\nInitially, these MUST be run in the following order-\n\t$PROGNAME -b\n\t$PROGNAME -d\n\t$PROGNAME -p\nOptions\n###\t[-b]\tBase-Pool\tClones the SUSE base pool trees to 'dev' channels\n###\t[-d]\tPromote-dev\tPromotes the 'dev' channel to the 'test' channel\n###\t[-n]\tNon-Prod\tDoes both -b and -d\n###\t[-p]\tProduction\t Promotes 'test' to 'Prod'\n###\t[-a]\tALL\t\tDoes all the Options\n###\t[-h]\tHelp\t\tPrints this list and exits\n###\t[-g]\tGPL\t\tPrints the GPL info and exits\n###\t[-r]\tRelease\t\tPrints the Current Release Version and exits\n\n\tThis Clone/Promote process requires the SUMA Admin account username\n\tand password to be issued, for security and portability purposes this\n\trequires a local credentials file [Default = /root/bin/.creds.sh], this file is \n\t'sourced' for the user/pass required VARIABLES and has the following\n\tstructure with NO empty lines or white-space--\nMY_ADMIN='suma-admin-username'\nMY_CREDS='suma-admin-password'\nEMAILG=email-or-group,additional-email-or-group [Separated by commas and NO spaces]\n\n\tThis file can also be used to add Custom function calls to\n\tadd custom repositories and packages.\n\nType 'q' to exit\n"

  TDATE=`date +%Y-%m-%d`
  RDATE=`date +%Y%m%d`
  HOSTA=`hostname`
  INITRUN=false
  TMPLATDIR=/srv/www/htdocs/pub/bootstrap
  TMPLATFIL=/srv/www/htdocs/pub/bootstrap/template.sh
  touch /tmp/tmp.sumatmp
  EMAILMSGZ=/tmp/tmp.sumatmp
  echo "Running $PROGNAME $1 Initial Process for $RDATE $2" > $EMAILMSGZ
#
#####################################################################
###	Begin logging
#####################################################################
#
echo -e "\n#########################################################\n#\n#    $TDATE -- Executing $PROGNAME Script\n#\n#########################################################\n" >> $EMAILMSGZ
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
        FROMA=smgadmin@$HOST
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
	echo -e "$USAGE\n\n\tThe '-b' Option MUST be run before any other\n\tthen the '-d'\n\tand then the -p\n"
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
	echo -e "$USAGE\n\n\tThe '-b' Option MUST be run before any other\n\tthen the '-d'\n\tand then the -p\n"
	exit $?
else
	if [[ "`grep 'test' $MY_CHANLIST`" == "" ]]; then
        	echo -e "$USAGE\n\n\tThe '-d' Option MUST be run before using the '-p'"
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
echo -e "
\n\t\t\t\t\t\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
\t\t\t\t\t\t\t=\tLet Me Be Perfectly Clear       =
\t\t\t\t\t\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n
"
sleep 1
clear
echo -e "
\n\t\t\t\t\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
\t\t\t\t\t\t=\tLet Me Be Perfectly Clear       =
\t\t\t\t\t\t=\tI do NOT claim to be a coder    =
\t\t\t\t\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n
"
sleep 2
clear
echo -e "
\n\t\t\t\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
\t\t\t\t\t=\tLet Me Be Perfectly Clear       =
\t\t\t\t\t=\tI do NOT claim to be a coder    =
\t\t\t\t\t=\tI know my code is UGLY and      =
\t\t\t\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n
"
sleep 2
clear
echo -e "
\n\t\t\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
\t\t\t\t=\tLet Me Be Perfectly Clear       =
\t\t\t\t=\tI do NOT claim to be a coder    =
\t\t\t\t=\tI know my code is UGLY and      =
\t\t\t\t=\tSloppy, BUT, it WORKS as        =
\t\t\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n
"
sleep 2
clear
echo -e "
\n\t\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
\t\t\t=\tLet Me Be Perfectly Clear       =
\t\t\t=\tI do NOT claim to be a coder    =
\t\t\t=\tI know my code is UGLY and      =
\t\t\t=\tSloppy, BUT, it WORKS as        =
\t\t\t=\tIntended! I know most of you    =
\t\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n
"
sleep 2
clear
echo -e "
\n\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
\t\t=\tLet Me Be Perfectly Clear       =
\t\t=\tI do NOT claim to be a coder    =
\t\t=\tI know my code is UGLY and      =
\t\t=\tSloppy, BUT, it WORKS as        =
\t\t=\tIntended! I know most of you    =
\t\t=\tThat examine it could write     =
\t\t=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n
"
sleep 2
clear
echo -e "
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
sleep 2
clear
echo -e "
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
echo -e "
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
echo -e "
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
echo -e "
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
echo -e "
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
sleep 5
}
#
#####################################################################
#####   Execute Functions
#####################################################################
#
case "$1" in
"-a")
  chk_sutils 2>&1 >> $EMAILMSGZ
  chk_creds 2>&1 >> $EMAILMSGZ
  no_opts 2>&1 >> $EMAILMSGZ
  susetrees_clone 2>&1 >> $EMAILMSGZ
  promote_dev 2>&1 >> $EMAILMSGZ
  promote_test 2>&1 >> $EMAILMSGZ
  ;;
"-n")
  chk_sutils 2>&1 >> $EMAILMSGZ
  chk_creds 2>&1 >> $EMAILMSGZ
  no_opts 2>&1 >> $EMAILMSGZ
  susetrees_clone 2>&1 >> $EMAILMSGZ
  promote_dev 2>&1 >> $EMAILMSGZ
  ;;
"-p")
  chk_sutils 2>&1 >> $EMAILMSGZ
  chk_creds 2>&1 >> $EMAILMSGZ
  no_opts 2>&1 >> $EMAILMSGZ
  promote_test 2>&1 >> $EMAILMSGZ
  ;;
"-d")
  chk_sutils 2>&1 >> $EMAILMSGZ
  chk_creds 2>&1 >> $EMAILMSGZ
  no_opts 2>&1 >> $EMAILMSGZ
  promote_dev 2>&1 >> $EMAILMSGZ
  ;;
"-b")
  chk_sutils 2>&1 >> $EMAILMSGZ
  chk_creds 2>&1 >> $EMAILMSGZ
  no_opts 2>&1 >> $EMAILMSGZ
  susetrees_clone 2>&1 >> $EMAILMSGZ
  ;;
#
"-h")
  echo -e "$USAGE" | less
  echo -e "$USAGE"
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
  echo -e "The $PROGNAME version release is $SCRIPT_RELEASE"
  exit $?
  ;;
#
*)
  echo -e "$USAGE" | less
  exit $?
  ;;
esac
#####################################################################
###     Email & Finalize Log
#####################################################################
echo -e "\n\tThe following Failure/s occured:\n" >> $EMAILMSGZ
grep -i 'error' $EMAILMSGZ >> $EMAILMSGZ
if $INITRUN; then
	echo -e "\n\tThank you for using the $PROGNAME script, Release $SCRIPT_RELEASE\n\tThis will require maually adding Child Channels to your Activation Keys in the WebUI\n" >> $EMAILMSGZ
	tail -n 12 $SYNCLOG
else
	echo -e "\n\tThank you for using the $PROGNAME script, Release $SCRIPT_RELEASE\n"
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
#####   All Objectives Completed--
#####   
#####           IT Linux 
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
#         ?? October 2017				#
#         Need to NOT use a static file moved to ~/bin/	#
#         It needs to be a symlink to githup Latest	#
#         Have not begun yet, just recognized the need	#
#                                                       #
#########################################################
#
