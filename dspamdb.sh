#!/bin/sh
#
# Written by Eric C. Broch of White Horse Technical Consulting: 9/5/20
#
# Use this script at your own risk. If you do use it and the bottom drops out of
# your world, I will accept no responsibilty.
#
# Assumes running MySQL/MariaDB & QMT server
#

yum install dspam dspam-client dspam-mysql dspam-web dspam-libs

MYSQLPW=

# Get DB password for administrator and check validity.
if [ -z "$MYSQLPW" ]; then
   read -s -p "Enter MySQL/MariaDB admin password to create dspam database: " MYSQLPW
fi
mysqladmin status -uroot -p$MYSQLPW > /dev/null 2>&1
if [ "$?" != "0" ]; then
   echo "Bad MySQL/MariaDB administrator password or MySQL/MariaDB is not running. Exiting..."
   exit 1
fi

echo ""
echo "Dropping Dspam database if it exists already..."
echo "use dspam" | mysql -uroot -p$MYSQLPW &> /dev/null
[ "$?" = "0" ] && mysqldump -uroot -p$MYSQLPW dspam > dspam.sql \
               && echo "drop database dspam" | mysql -u root -p$MYSQLPW \
               && echo "dspam db saved to dspam.sql and dropped..."

# Create dspam with correct permissions
echo "Creating Dspam database..."
mysqladmin create dspam -uroot -p$MYSQLPW
mysqladmin -uroot -p$MYSQLPW reload
mysqladmin -uroot -p$MYSQLPW refresh
echo "GRANT ALL ON dspam.* TO dspam@localhost IDENTIFIED BY 'p4ssw3rd'" | mysql -uroot -p$MYSQLPW
mysqladmin -uroot -p$MYSQLPW reload
mysqladmin -uroot -p$MYSQLPW refresh
wget https://raw.githubusercontent.com/qmtoaster/dspam/master/dspamdb.sql
if [ "$?" != "0" ]; then
   echo "Error downloading dspam db: ($?), exiting..."
   exit 1
fi
mysql -uroot -p$MYSQLPW dspam < dspamdb.sql
mysqladmin -uroot -p$MYSQLPW reload
mysqladmin -uroot -p$MYSQLPW refresh

# Change permissions on and place proper files necessary to run dspam daemon
chmod 777 /var/run/dspam
cp -p /etc/dspam.conf /etc/dspam.conf.bak
wget -O /etc/dspam.conf https://raw.githubusercontent.com/qmtoaster/dspam/master/dspam.conf
if [ "$?" != "0" ]; then
   echo "Error downloading dspam conf: ($?), exiting..."
   exit 1
fi

# Implement dspam for all domains
domains=/home/vpopmail/domains
read -p "Do you want to implement Dspam filtering at domain level? (For user level filtering skip this step) [Y/N]: " input
if [ "$input" = "Y" ] || [ "$input" = "y" ]; then
   for domain in `ls $domains`; do
      if [ -d $domains/$domain ]; then
         read -p "Add dspam functionality to $domain [Y]: " input1
         if [ "$input1" = "Y" ] || [ "$input1" = "y" ]; then
            mv $domains/$domain/.qmail-default $domains/$domain/.qmail-default.bak
            wget -O $domains/$domain/.qmail-default https://raw.githubusercontent.com/qmtoaster/dspam/master/.qmail-default
            echo "Domain: $domain ready..."
         else
            echo "Skipping $domain..."
         fi
      fi
   done
fi

exit 0
