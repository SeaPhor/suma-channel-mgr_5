#!/bin/bash
WRKDIR=/home/smiller/MyNewRepos/GitHub/SUSEManager
cd $WRKDIR
git pull origin master
#
NEWREV=$(( `ls -1 $WRKDIR | grep ^4 | tail -n1 | awk -F- '{print $2}'` + 1 ));
BASENAME="`ls -1 $WRKDIR | grep ^4 | tail -n1 | awk -F- '{print $1}'`"
ARCHFIL="`ls -1 $WRKDIR | grep ^4 | head -n1`"
CPFIL="`ls -1 $WRKDIR | grep ^4 | tail -n2 | head -n1`"
LATEFIL="`ls -1 $WRKDIR | grep ^4 | tail -n1`"
REVDATE=`date +%d\ %B\ %Y`
#
cp -r $WRKDIR/$LATEFIL $WRKDIR/tempfil
sed -i "s/SCRIPT_RELEASE_DATE\=\"?? ??? 201?\"/SCRIPT_RELEASE_DATE\=\"$REVDATE\"/g" $WRKDIR/$LATEFIL/channellock-promote_4.1.4*
cp $WRKDIR/$LATEFIL/* $WRKDIR/Latest_Stable/channellock-promote.sh
mv $WRKDIR/$ARCHFIL $WRKDIR/Archive/.
mv $WRKDIR/tempfil $WRKDIR/$BASENAME-$NEWREV
mv $WRKDIR/$BASENAME-$NEWREV/channellock-promote_4.1.4* $WRKDIR/$BASENAME-$NEWREV/channellock-promote_4.1.4-$NEWREV
sed -i s/SCRIPT_RELEASE\=\"4.1.4-..\"/SCRIPT_RELEASE\=\"4.1.4-$NEWREV\"/g $WRKDIR/$BASENAME-$NEWREV/channellock-promote_4.1.4-$NEWREV
#
cd $WRKDIR
git add *
git commit -a -m "$CPFIL is now Latest_Stable - Promoted to 4.1.4-$NEWREV on $REVDATE"
git push origin master
exit 0
