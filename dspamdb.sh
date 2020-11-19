#!/bin/sh
#
# Written by Eric C. Broch of White Horse Technical Consulting: 9/5/20
#
# Use this script at your own risk. If you do use it and the bottom drops out of
# your world, I will accept no responsibilty.
#
# Assumes a running MySQL/MariaDB & QMT server
#

sites=(
https://d2lzkl7pfhq30w.cloudfront.net/pub/archive/fedora/linux/releases/28/Everything/x86_64/os/ \
http://mirror.math.princeton.edu/pub/fedora-archive/fedora/linux/releases/28/Everything/x86_64/os/ \
http://pubmirror1.math.uh.edu/fedora-buffet/archive/fedora/linux/releases/28/Everything/x86_64/os/ \
https://pubmirror2.math.uh.edu/fedora-buffet/archive/fedora/linux/releases/28/Everything/x86_64/os/ \
http://mirrors.kernel.org/fedora-buffet/archive/fedora/linux/releases/28/Everything/x86_64/os/ \
https://dl.fedoraproject.org/pub/archive/fedora/linux/releases/28/Everything/x86_64/os/
)
FREPO=
rel=`grep "release 8" /etc/centos-release`
if [[ ! -z $rel ]]
then
   printf '%s\n%s\n%s\n%s\n%s\n%s\n' '[fedora]' 'name=Fedora 28' 'mirrorlist=file:///etc/yum.repos.d/fedoramirrors' 'enabled=0' 'gpgcheck=0' 'priority=100' > /etc/yum.repos.d/fedora28.repo
   printf '%s\n%s\n%s\n%s\n%s\n%s\n' "${sites[0]}" "${sites[1]}" "${sites[2]}" "{$sites[3]}" "${sites[4]}" "${sites[5]}" > /etc/yum.repos.d/fedoramirrors
   FREPO=--enablerepo=fedora
fi

yum $FREPO install dspam dspam-client dspam-mysql dspam-libs

# Get db structure
wget https://raw.githubusercontent.com/qmtoaster/dspam/master/dspamdb.sql
if [ "$?" != "0" ]; then
   echo "Error downloading dspam db: ($?), exiting..."
   exit 1
fi

MYSQLPW=

# Get DB password for administrator and check validity.
if [ -z "$MYSQLPW" ]; then
   read -s -p "Enter MySQL/MariaDB admin password to create dspam database: " MYSQLPW
fi

credfile=~/sql.cnf
echo -e "[client]\nuser=root\npassword=$MYSQLPW\nhost=localhost" > $credfile

mysqladmin --defaults-extra-file=$credfile status > /dev/null 2>&1
if [ "$?" != "0" ]; then
   echo "Bad MySQL/MariaDB administrator password or MySQL/MariaDB is not running. Exiting..."
   exit 1
fi

echo ""
echo "Dropping Dspam database if it exists already..."
mysql --defaults-extra-file=$credfile -e "use dspam" &> /dev/null
[ "$?" = "0" ] && mysqldump --defaults-extra-file=$credfile dspam > dspam.sql \
               && mysql --defaults-extra-file=$credfile -e "drop database dspam" \
               && echo "dspam db saved to dspam.sql and dropped..."

# Create dspam with correct permissions
echo "Creating Dspam database..."
mysqladmin --defaults-extra-file=$credfile reload
mysqladmin --defaults-extra-file=$credfile refresh
mysqladmin --defaults-extra-file=$credfile create dspam
mysqladmin --defaults-extra-file=$credfile reload
mysqladmin --defaults-extra-file=$credfile refresh
echo "Adding dspam users and privileges..."
mysql --defaults-extra-file=$credfile -e "CREATE USER dspam@localhost IDENTIFIED BY 'p4ssw3rd'"
mysql --defaults-extra-file=$credfile -e "GRANT ALL PRIVILEGES ON dspam.* TO dspam@localhost"
mysqladmin --defaults-extra-file=$credfile reload
mysqladmin --defaults-extra-file=$credfile refresh
echo "Done with dspam database..."
mysql --defaults-extra-file=$credfile dspam < dspamdb.sql
mysqladmin --defaults-extra-file=$credfile reload
mysqladmin --defaults-extra-file=$credfile refresh

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

read -p "Do you want to implement Dspam Web [Y/N]: " input
if [ "$input" = "Y" ] || [ "$input" = "y" ]; then
   firewall-cmd --zone=public --add-port=8009/tcp --permanent
   firewall-cmd --reload
   yum $FREPO install dspam-web
   wget -O /etc/httpd/conf.d/dspam-web.conf https://raw.githubusercontent.com/qmtoaster/dspam/master/dspam-web.conf
   groupmod -g 1984 dspam
   usermod -u 1988 -g 1984 dspam
   chown -R dspam:dspam /var/www/dspam
   chown dspam:dspam /run/dspam
   chown -R dspam:dspam /var/log/dspam
   chown dspam:dspam /usr/bin/dspam
   chown dspam:dspam /usr/bin/dspamc
   systemctl restart httpd
   TAB="$(printf '\t')" && GREEN=$(tput setaf 2) && RED=$(tput setaf 1) && NORMAL=$(tput sgr0)
   echo $RED
   printf "You will need to add credentials for all virtual email users at the command line.\n"
   echo $GREEN
   printf "Create credential file and add first user: \n"
   echo $NORMAL
   printf "# htpasswd -c /var/www/dspam-passwd myemail@mydomain.tld\n"
   printf "\n"
   echo $GREEN
   printf "Add subsequent users to credential file: \n"
   echo $NORMAL
   printf "# htpasswd /var/www/dspam-passwd myemail2@mydomain.tld\n"
   printf "\n"
   echo $RED
   printf "You will also need to change the 'ServerName' option in Dspam's httpd config file, dspam-web.conf\n"
   printf "You can login to the web interface with http://my.fqdn.tld:8009 or http://my.ip.addr:8009/\n"
   echo $NORMAL
fi

chown dspam:mail /usr/bin/dspam
chown dspam:mail /usr/bin/dspamc
chmod 2511  /usr/bin/dspam
chmod 2511  /usr/bin/dspamc

exit 0
