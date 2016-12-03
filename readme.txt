Run the script 'dspamdb.sh' to create the dspam database, install dspam, and start the dspam service.
If dspam is implemented for a domain, every email received by that domain will have a dspam signature in the header and a
matching signature will automatically be entered in the dspam maria/mysql database. At this point there has been no training.
To train I have users create a spam and notspam folder in their IMAP account. All spam will be placed into the spam folder and
all ham into the notspam folder. I run a bash script enumerating all mail in these folders and dumping each to dspam:

Training:

$SOURCE=corpus/error 
$CLASS=spam/innocent
$MODE=toe/teft/unlearn
cat $email | dspam --user $USER@$DOMAIN --mode=$MODE --class=$CLASS --source=$SOURCE

Flags:

1) Corpus (no dspam signature present in header)
   $SOURCE=corpus
   $CLASS=spam/innocent
   $MODE=teft
2) Error (dspam signature present in header) dspam catagorizes spam as ham
   $SOURCE=error
   $CLASS=spam
   $MODE=toe
3) Error (dspam signature present in header) dspam catagorized ham as spam. A & B below must be called.
   A) 
      $SOURCE=error
      $CLASS=spam
      $MODE=unlearn
   B)
      $SOURCE=error
      $CLASS=innocent
      $MODE=toe
