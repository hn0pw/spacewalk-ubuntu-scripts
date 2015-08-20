#!/bin/bash
echo "Installing spacewalk client for Ubuntu 14.04LTS"

CONFIGFILE="config"
if [ ! -f $CONFIGFILE ]; then
    echo "Please add config file, and edit the lines in it!"
    echo "run: cp config_sample config"
    exit
fi

source config
echo "Your spacewalk host: "$SPACEWALK_HOST
echo "Your activation key: "$SPACEWALK_ACTIVATION_KEY

apt-get update
apt-get -y install apt-transport-spacewalk rhnsd python-libxml2

# Fix errors emails from spacewalk
# https://github.com/ahakala/deb-spacewalk
FILE="/etc/apt/apt.conf"
TEXT="Acquire::PDiffs \"false\";"
[[ -f $FILE ]] || touch $FILE
if grep -Fxq "$TEXT" $FILE
then
    echo "$TEXT already in $FILE"
else
    echo "Add $TEXT to $FILE"
    echo "$TEXT" >> $FILE
fi

mkdir /var/lock/subsys

bash patch_files.sh

echo "Register this client with your spacewalk host"
echo "rhnreg_ks --serverUrl=https://"$SPACEWALK_HOST"/XMLRPC --sslCACert=/usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT --activationkey="$SPACEWALK_ACTIVATION_KEY
wget http://$SPACEWALK_HOST/pub/RHN-ORG-TRUSTED-SSL-CERT -O /usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT
rhnreg_ks --serverUrl=https://$SPACEWALK_HOST/XMLRPC --sslCACert=/usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT --activationkey=$SPACEWALK_ACTIVATION_KEY

echo "Finished"
echo "Please go to your spacewalk web interface to see this client status"





