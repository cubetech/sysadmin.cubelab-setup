#!/bin/bash

# cubelab dev server install script

cd /root

command_exists() {
    type "$1" &> /dev/null ;
}

file_exists() {
	[ -f "$1" ]
}

dir_exists() {
	[ -d "$1" ]
}

doalarm() { perl -e 'alarm shift; exec @ARGV' "$@"; }

version=`cat /etc/redhat-release | cut -d" " -f4 | cut -d "." -f1`

echo "Updating system..."
yum update -y

if test $version -gt 5; then
	echo "Installing needed system packages for CentOS 6..."
	yum groupinstall -y core
	yum groupinstall -y server-policy
	yum groupinstall -y development
	yum install -y elinks httpd mod_ssl ntp poppler-utils screen vim-enhanced bzip2-devel bzip2-devel.i686 cyrus-sasl-devel cyrus-sasl-devel.i686 db4-devel db4-devel.i686 freetype-devel freetype-devel.i686 gdbm-devel gdbm-devel.i686 glibc-devel glibc-devel.i686 lcms-devel lcms-devel.i686 libgcc.i686 libjpeg-devel libjpeg-devel.i686 libstdc++-devel libstdc++-devel.i686 libtiff-devel libtiff-devel.i686 libxml2-devel libxml2-devel.i686 libxslt-devel libxslt-devel.i686 mysql-devel mysql-devel.i686 ncurses-devel ncurses-devel.i686 openldap-devel openldap-devel.i686 openssl-devel openssl-devel.i686 readline-devel readline-devel.i686 sqlite-devel sqlite-devel.i686 zlib-devel zlib-devel.i686 mariadb mariadb-devel mariadb-server wget 
else
	echo "WARNING: No CentOS/RedHat >= 6 found. Exit."
	exit 1;
fi

if ! command_exists git; then
	echo "Installing git..."
	echo
	yum install -y git
fi

echo "Installing apache...
"
chkconfig httpd on

if ! dir_exists /etc/httpd/vhosts.d; then
	mkdir /etc/httpd/vhosts.d
	echo "Patching apache config...
	"
	echo "
NameVirtualHost `ip -4 -o addr s dev eth0 | cut -d" " -f7 | cut -d/ -f1`:80
NameVirtualHost `ip -4 -o addr s dev eth0 | cut -d" " -f7 | cut -d/ -f1`:443

Include vhosts.d/*.conf" >> /etc/httpd/conf/httpd.conf

fi

service httpd start

while [ -z "$domain" ]
do
	read -p "Please input the top domain of the dev server (see README): " domain
done

echo "
Installing cubelab Apache vHost..."

wget --no-check-certificate -O /etc/httpd/vhosts.d/STAR.$domain.conf https://raw.githubusercontent.com/cubetech/sysadmin.cubelab-setup/master/vhost.conf

sed -i "s/DOMAINNAME/$domain/g" /etc/httpd/vhosts.d/STAR.$domain.conf
sed -i "s/IP/`ip -4 -o addr s dev eth0 | cut -d" " -f7 | cut -d/ -f1`/g" /etc/httpd/vhosts.d/STAR.$domain.conf
escdomain=`sed 's@\.@\\\.@g' <<<"$domain"`
sed -i "s/ESCNAME/$escname/g" /etc/httpd/vhosts.d/STAR.$domain.conf

echo "
Installing itk httpd module..."

yum install -y httpd-itk
if [ -z "`grep itk /etc/sysconfig/httpd`" ]; then
	echo "
HTTPD=/usr/sbin/httpd.itk" >> /etc/sysconfig/httpd
fi

if [ -z "`grep itk /etc/httpd/conf.d/php.conf`" ]; then
	echo "
<IfModule itk.c>
   LoadModule php5_module modules/libphp5.so
</IfModule>" >> /etc/httpd/conf.d/php.conf
fi

echo "
Installing skeleton..."

mkdir /etc/skel/log
mkdir /etc/skel/web

wget --no-check-certificate -O /etc/skel/web/.htaccess https://raw.githubusercontent.com/cubetech/sysadmin.cubelab-setup/master/web/.htaccess

echo "
Setup MariaDB server..."

while [ -z "$sqlrootpw" ]
do
	read -s -p "Please define a root pw for your SQL server: " sqlrootpw
done

echo "
Securing SQL installation..."

mysql -u root -e "UPDATE mysql.user SET Password=PASSWORD('$sqlrootpw') WHERE User='root';"
mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -u root -e "DELETE FROM mysql.user WHERE User='';"
mysql -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
mysql -u root -e "FLUSH PRIVILEGES;"

echo "
Installing setup script in /home/setup/web..."

useradd setup -m -k /etc/skel -d /home/setup -g apache;
cd /home/setup/web
rm -rf .htaccess
git init
git remote add origin https://github.com/cubetech/sysadmin.setup-script.git
git fetch
git checkout -t origin/master

chown -R setup:apache /home/setup/web

cp /home/setup/web/config.sample.php /home/setup/web/config.php
sed -i "s/DOMAINNAME/$domain/g" /home/setup/web/config.php

while [ -z "$mysqluser" ]
do
	read -p "Please enter your MySQL/MariaDB user with much rights (creating user and dbs, can be root): " mysqluser
done

while [ -z "$mysqlpw" ]
do
	read -s -p "Please enter your MySQL/MariaDB password: " mysqlpw
done

sed -i "s/USER/$mysqluser/g" /home/setup/web/config.php
sed -i "s/PASSWORD/$mysqlpw/g" /home/setup/web/config.php

echo "
You can now call the setup script via http://setup.$domain"

echo "Finished."
