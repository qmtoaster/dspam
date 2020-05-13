#!/bin/sh

LEARN_CORPUS=teft
LEARN_ERROR=toe

domain=
username=
VPOPDIR=/home/vpopmail

for domain in `ls $VPOPDIR/domains`
do
   echo ""
   printf "Begin: %s\n" "$domain"
   printf "%s\n" "-----------------------------------------------------------------------------------------------------------------------------------------------"
   echo "Processing $domain..."
   for username in `ls $VPOPDIR/domains/$domain`
   do
      if [ -d $VPOPDIR/domains/$domain/$username/subscribers ]
      then
         echo "Skipping $username list..."
         continue
      fi
      echo "Processing $username..."
      if [ ! -d $VPOPDIR/domains/$domain/$username/Maildir/.1-notspam ]; then
         doveadm mailbox create -u $username@$domain -s 1-notspam
      fi
      echo "Processing notspam for $username@$domain"
      cd $VPOPDIR/domains/$domain/$username/Maildir/.1-notspam/cur
      for NAME in `ls`; do
         directory=`pwd`
         if [ "$directory" != "$VPOPDIR/domains/$domain/$username/Maildir/.1-notspam/cur" ]; then
            echo "Directory changed unexpectedly: `pwd`"
            break
         fi
         ds=
         sa=
         sa=`cat $NAME | grep "X-Spam-Status: Yes"`
         ds=`cat $NAME | grep "X-DSPAM-Result: Spam"`
         ds1=`cat $NAME | grep "X-DSPAM-Result:"`
         FROM=`cat $NAME | grep "From:"`
         SUBJECT=`cat $NAME | grep "Subject:"`
         # Marked as spam by both dpsam and sa
         if [ "$sa" != "" ] && [ "$ds" != "" ]; then
            echo "*** Marked by dspam and sa as spam: $NAME"
            echo "From: $FROM"
            echo "Subject: $SUBJECT"
            # Remove dspam header signature and subject and learn with sa (don't relearn dspam)
            echo "Learning sa..."
            cat $NAME | grep -v X-DSPAM | sed 's/\*\*\*SPAM\*\*\*\[ds\]//g' | sa-learn --forget
            cat $NAME | grep -v X-DSPAM | sed 's/\*\*\*SPAM\*\*\*\[ds\]//g' | sa-learn --ham
            mv -v $NAME  $VPOPDIR/domains/$domain/$username/Maildir/cur
            echo ""
         # Not marked by either dspam or sa as spam
         elif [ "$sa" = "" ] && [ "$ds" = "" ]; then
            echo "*** Not marked by either dspam or sa as spam: $NAME"
            echo "From: $FROM"
            echo "Subject: $SUBJECT"
            # Remove dspam signature from message and learn with sa
            echo "Learning sa..."
            cat $NAME | grep -v X-DSPAM | sa-learn --forget
            cat $NAME | grep -v X-DSPAM | sa-learn --ham
            # Learn with dspam
            echo "Learning dspam..."
            if [ "$ds1" = "" ]; then
               echo "---No Dspam Header, corpus $LEARN_CORPUS (ham)"
               cat $NAME | sed 's/\*\*\*SPAM\*\*\*\[sa\]//g' | sed 's/\*\*\*SPAM\*\*\*//g' | dspam --user $USER@$DOMAIN --mode=$LEARN_CORPUS --class=innocent --source=corpus
            else
               echo "---Dspam Header, error $LEARN_ERROR (ham)"
               cat $NAME | sed 's/\*\*\*SPAM\*\*\*\[sa\]//g' | sed 's/\*\*\*SPAM\*\*\*//g' | dspam --user $USER@$DOMAIN --mode=unlearn --class=spam --source=error
               cat $NAME | sed 's/\*\*\*SPAM\*\*\*\[sa\]//g' | sed 's/\*\*\*SPAM\*\*\*//g' | dspam --user $USER@$DOMAIN --mode=$LEARN_ERROR --class=innocent --source=error
            fi
            mv -v $NAME  $VPOPDIR/domains/$domain/$username/Maildir/cur
            echo ""
         # Marked by dspam and not sa as spam
         elif [ "$sa" = "" ] && [ "$ds" != "" ]; then
            echo "*** Marked by dspam and not sa as spam: $NAME"
            echo "From: $FROM"
            echo "Subject: $SUBJECT"
            echo "Learning sa..."
            cat $NAME | grep -v X-DSPAM | sed 's/\*\*\*SPAM\*\*\*\[ds\]//g' | sa-learn --forget
            cat $NAME | grep -v X-DSPAM | sed 's/\*\*\*SPAM\*\*\*\[ds\]//g' | sa-learn --ham
            mv -v $NAME  $VPOPDIR/domains/$domain/$username/Maildir/cur
            echo ""
         # Marked by sa and not dspam as spam
         else #[ "$sa" != "" ] && [ "$ds" = "" ]
            echo "*** Marked by sa and not dspam: $NAME"
            echo "From: $FROM"
            echo "Subject: $SUBJECT"
            # Remove dspam signature from message and learn with sa
            echo "Learning sa..."
            cat $NAME | grep -v X-DSPAM | sa-learn --forget
            cat $NAME | grep -v X-DSPAM | sa-learn --ham
            # Learn with dspam
            echo "Learning dspam..."
            if [ "$ds1" = "" ]; then
               echo "---No Dspam Header, corpus $LEARN_CORPUS (ham)"
               cat $NAME | sed 's/\*\*\*SPAM\*\*\*\[sa\]//g' | sed 's/\*\*\*SPAM\*\*\*//g' | dspam --user $USER@$DOMAIN --mode=$LEARN_CORPUS --class=innocent --source=corpus
            else
               echo "---Dspam Header, error $LEARN_ERROR (ham)"
               cat $NAME | sed 's/\*\*\*SPAM\*\*\*\[sa\]//g' | sed 's/\*\*\*SPAM\*\*\*//g' | dspam --user $USER@$DOMAIN --mode=unlearn --class=spam --source=error
               cat $NAME | sed 's/\*\*\*SPAM\*\*\*\[sa\]//g' | sed 's/\*\*\*SPAM\*\*\*//g' | dspam --user $USER@$DOMAIN --mode=$LEARN_ERROR --class=innocent --source=error
            fi
            mv -v $NAME  $VPOPDIR/domains/$domain/$username/Maildir/cur
            echo ""
         fi
      done
      echo ""
   done
done
