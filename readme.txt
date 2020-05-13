Install Dspam:
wget https://raw.githubusercontent.com/qmtoaster/dspam/master/dspamdb.sh
chmod 755 dspamdb.sh
./dpsamdb.sh

Running the script 'dspamdb.sh' creates the dspam database, installs dspam, and starts the dspam service.
If dspam is implemented for a domain, every email received by that domain will have a dspam signature in the header and a
matching signature will automatically be entered in the dspam maria/mysql database. At this point there has been no training.
To train I have users create a spam and notspam folder in their IMAP account. All spam will be placed into the spam folder and
all ham into the notspam folder. I run a bash script enumerating all mail in these folders and dumping each to dspam. 

If there are spam filters in front of dspam that insert header signatures dspam's configuration file must enumerate them
so that they can be ignored for training purposes. Below are the Spamassassin signatures with the proper configuration syntax:

IgnoreHeader X-Spam-Checker-Version
IgnoreHeader X-Spam-Level
IgnoreHeader X-Spam-Status
IgnoreHeader X-Spam-Flag
IgnoreHeader X-Spam-Report
IgnoreHeader X-Spam-Prev-Subject

Here's a list of headers to ignore for your config file: https://raw.githubusercontent.com/qmtoaster/dspam/master/IgnoreHeader

Training:

   Flag options:
      SOURCE=corpus/error 
      CLASS=spam/innocent
      MODE=toe/teft/unlearn

   Dspam call:
      cat $email | dspam --user $USER@$DOMAIN --mode=$MODE --class=$CLASS --source=$SOURCE

   Source: Depending on email source, corpus or error, dspam must be called with the flags set below.
      1) Corpus (no dspam signature present in header) Depending on type of corpus, ham or spam, class appropriately.
         SOURCE=corpus
         CLASS=spam or innocent
         MODE=teft
      2) Error (dspam signature present in header) dspam catagorizes spam as ham
         SOURCE=error
         CLASS=spam
         MODE=toe
      3) Error (dspam signature present in header) dspam catagorized ham as spam, dspam must be called twice, to unlearn and
                                                   train.
         A) 
            SOURCE=error
            CLASS=spam
            MODE=unlearn
         B)
            SOURCE=error
            CLASS=innocent
            MODE=toe

Server side filtering:

For server side filter you must install maildrop and download and install two file .qmail and .mailfilter.dspam in each user directory for which Dspam will be enabled.

# cd /home/vpopmail/'dspam-enabled-domain'/'user'
# wget https://raw.githubusercontent.com/qmtoaster/dspam/master/.qmail
# wget https://raw.githubusercontent.com/qmtoaster/dspam/master/.mailfilter.dspam
# chown vpopmail:vchkpw .qmail
# chown vpopmail:vchkpw .mailfilter.dspam
# chmod 600 .qmail
# chmod 600 .mailfilter.dspam

Mail should flow and be logged
# cat /var/log/maildrop/maildrop-'user'@'dspam-enabled-domain'.log

At this point in your email client you must create the 'spam' and 'notspam' folders and start placing spam in the spam folder to be learned by the script.
