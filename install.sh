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

version=`cat /etc/redhat-release | cut -d" " -f3 | cut -d "." -f1`

echo "Updating system..."
yum update -y

if [ $version -gt 5 ]; then
	echo "Installing needed system packages for CentOS 6..."
	yum groupinstall -y core
	yum groupinstall -y server-policy
	yum groupinstall -y development
	yum install -y elinks httpd mod_ssl ntp poppler-utils screen vim-enhanced bzip2-devel bzip2-devel.i686 cyrus-sasl-devel cyrus-sasl-devel.i686 db4-devel db4-devel.i686 freetype-devel freetype-devel.i686 gdbm-devel gdbm-devel.i686 glibc-devel glibc-devel.i686 lcms-devel lcms-devel.i686 libgcc.i686 libjpeg-devel libjpeg-devel.i686 libstdc++-devel libstdc++-devel.i686 libtiff-devel libtiff-devel.i686 libxml2-devel libxml2-devel.i686 libxslt-devel libxslt-devel.i686 mysql-devel mysql-devel.i686 ncurses-devel ncurses-devel.i686 openldap-devel openldap-devel.i686 openssl-devel openssl-devel.i686 readline-devel readline-devel.i686 sqlite-devel sqlite-devel.i686 zlib-devel zlib-devel.i686 mariadb mariadb-devel mariadb-server 
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


