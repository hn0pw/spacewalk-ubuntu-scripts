### Spacewalk setup scripts
This repo contains scripts to install the spacewalk server and the ubuntu 14.04 client

#### Spacewalk server setup
Please use a fresh CentOS 7 installation and run as root:
```
git clone https://github.com/ramon-ga/spacewalk-ubuntu-scripts.git
cd spacewalk-ubuntu-scripts/server-centos-7
./spacewalk_install.sh
```


#### Spacewalk client setup Ubuntu 14.04
You have just run the following command as root:
```
wget --quiet -N https://raw.githubusercontent.com/ramon-ga/spacewalk-ubuntu-scripts/master/client-ubuntu-14.04/install.sh&&bash install.sh 'spacewalk-host.yourdomain.swiss' '1-spacewalk-key'
```
