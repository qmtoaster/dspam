Run the script 'dspamdb.sh' to create the dspam database, install dspam, and start the dspam service.
If dspam is implemented for a domain, every email received by that domain will have a dspam signature in the header and a
matching signature will automatically be entered in the dspam maria/mysql database. At this point there has been no training.
To train I have users create a spam and notspam folder in their IMAP account. All spam will be placed into the spam folder and
all ham into the notspam folder. I run a bash script enumerating all mail in these folders and dumping each to dspam:

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
