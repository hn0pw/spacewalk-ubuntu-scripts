#!/bin/bash

echo "Install spacewalk on CentOS 7"
echo "   This will need ~80GB Space (For full Ubuntu 14.04 Packages)"
read -e -p "Please press enter to continue.." -i "" nix
echo "Updating system"
yum -y update

echo "Adding repos"
rpm -Uvh http://yum.spacewalkproject.org/2.3/RHEL/7/x86_64/spacewalk-repo-2.3-4.el7.noarch.rpm
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

cat > /etc/yum.repos.d/jpackage-generic.repo << EOF
[jpackage-generic]
name=JPackage generic
#baseurl=http://mirrors.dotsrc.org/pub/jpackage/5.0/generic/free/
mirrorlist=http://www.jpackage.org/mirrorlist.php?dist=generic&type=free&release=5.0
enabled=1
gpgcheck=1
gpgkey=http://www.jpackage.org/jpackage.asc
EOF
#yum repolist

echo "Installing packages"
#yum -y install spacewalk-postgresql
yum -y install spacewalk-setup-postgresql python-debian screen vnstat git net-snmp net-snmp-utils spacewalk-utils
#yum update python-debian

HOSTNAME=$(hostname -f)
echo "Patch files"
./patch_files.sh

# fix a problem that cobbler can't login
sed -i 's/redhat_management_permissive: 0/redhat_management_permissive: 1/g' /etc/cobbler/settings

# Fix package updates not showed up in spacewalk host
# https://www.redhat.com/archives/spacewalk-list/2015-May/msg00146.html
# Maybe reconf is needed spacewalk-hostname-rename <ip-address>
sed -i "s*serverURL=https://enter.your.server.url.here/XMLRPC*serverURL=https://"$HOSTNAME"/XMLRPC*g" /etc/sysconfig/rhn/up2date


echo "Open firewall ports"

firewall-cmd --add-service=http ; firewall-cmd --add-service=https; firewall-cmd --add-service=smtp; firewall-cmd --zone=public --add-port=161/udp; firewall-cmd --runtime-to-permanent; firewall-cmd --reload;
#firewall-cmd --permanent --list-all

echo "Spacewalk setup"
spacewalk-setup --disconnected

echo "Install needed perl cpan modules for spacewalk-debian-sync"
yum -y install cpan
cpan -i Frontier/Client.pm
cpan -i Module/Build.pm
cpan -i HTML::TreeBuilder
cpan -i WWW/Mechanize.pm

wget http://$HOSTNAME/pub/RHN-ORG-TRUSTED-SSL-CERT -O /usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT

DEBIANSYNCFILE="/root/spacewalk-debian-sync.pl"
#wget https://raw.githubusercontent.com/stevemeier/spacewalk-debian-sync/master/spacewalk-debian-sync.pl -O $DEBIANSYNCFILE
wget https://raw.githubusercontent.com/ramon-ga/spacewalk-ubuntu-scripts/master/server-centos-7/spacewalk-debian-sync.pl -O $DEBIANSYNCFILE
chmod +x $DEBIANSYNCFILE

echo "Please enter a user account to import packages with cron:"
read -e -p "username: " -i "" spacewalk_username
read -s -e -p "password: " -i "" spacewalk_password

CRONFILE="/etc/cron.d/spacewalk-debian-sync"
echo "Add ubuntu packages repos to cron "$CRONFILE
echo "0 0 * * * $DEBIANSYNCFILE --username $spacewalk_username --password '$spacewalk_password' --channel 'trusty' --url 'http://de.archive.ubuntu.com/ubuntu/dists/trusty/main/binary-amd64/'" >> $CRONFILE
echo "15 0 * * * $DEBIANSYNCFILE --username $spacewalk_username --password '$spacewalk_password' --channel 'trusty-updates' --url 'http://de.archive.ubuntu.com/ubuntu/dists/trusty-updates/main/binary-amd64/'" >> $CRONFILE
echo "30 0 * * * $DEBIANSYNCFILE --username $spacewalk_username --password '$spacewalk_password' --channel 'trusty-security' --url 'http://de.archive.ubuntu.com/ubuntu/dists/trusty-security/main/binary-amd64/'" >> $CRONFILE
echo "45 0 * * * $DEBIANSYNCFILE --username $spacewalk_username --password '$spacewalk_password' --channel 'trusty-universe' --url 'http://de.archive.ubuntu.com/ubuntu/dists/trusty/universe/binary-amd64/'" >> $CRONFILE
echo "0 1 * * * $DEBIANSYNCFILE --username $spacewalk_username --password '$spacewalk_password' --channel 'trusty-updates-universe' --url 'http://de.archive.ubuntu.com/ubuntu/dists/trusty-updates/universe/binary-amd64/'" >> $CRONFILE
echo "15 1 * * * $DEBIANSYNCFILE --username $spacewalk_username --password '$spacewalk_password' --channel 'trusty-security-universe' --url 'http://de.archive.ubuntu.com/ubuntu/dists/trusty-security/universe/binary-amd64/'" >> $CRONFILE

echo "Restart spacewalk"
spacewalk-service restart

echo "************************************************************************************"
echo "Finished, please open https://"$HOSTNAME" in your browser"
echo ""
echo "Please add the following channels in the web interface"
echo "   Name                     | Parent     | Checksum      | Architecture"
echo "----------------------------|------------|---------------|---------------"
echo "   trusty                     none         sha256          AMD64 Debian"
echo "   trusty-universe            trusty       sha256          AMD64 Debian"
echo "   trusty-updates             trusty       sha256          AMD64 Debian"
echo "   trusty-updates-universe    trusty       sha256          AMD64 Debian"
echo "   trusty-security            trusty       sha256          AMD64 Debian"
echo "   trusty-security-universe   trusty       sha256          AMD64 Debian"
echo ""
echo "If the email sender is wrong please add it to /etc/rhn/rhn.conf and restart 'spacewalk-service reload'"
echo "  echo \"web.default_mail_from = root@"$HOSTNAME"\" >> /etc/rhn/rhn.conf"
echo ""
echo "The packages import needs several hours, if you want to start right now do the following:"
echo "Run each command from "$CRONFILE" in screen session (will not die if the connection broke)"
echo ""
echo "To install the client on Ubuntu please run this lines as root on each server:"
echo "  wget --quiet -N https://raw.githubusercontent.com/ramon-ga/spacewalk-ubuntu-scripts/master/client-ubuntu-14.04/install.sh&&bash install.sh '"$HOSTNAME"' '1-paste-key-from-webinterface'"
echo ""
echo "To add custom repo's add it to the cron file "$CRONFILE
echo "Ex. for percona: 30 1 * * * root /root/spacewalk-debian-sync.pl --username user --password 'password' --channel 'trusty-percona-main' --url '/root/spacewalk-debian-sync.pl --username Administrator --password '9yupdz2YPinIRo8V' --channel 'trusty-percona-main' --url 'http://repo.percona.com/apt/dists/trusty/main/binary-amd64/'"
echo "************************************************************************************"
