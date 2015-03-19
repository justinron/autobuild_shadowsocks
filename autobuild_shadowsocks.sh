#!/bin/bash
#===============================================================================================
#   System Required:  Debian or Ubuntu (32bit/64bit)
#   Description:  Install Shadowsocks(libev) for Debian or Ubuntu
#   Author: JR <admin@zygotee.com>
#   Intro:  http://www.zygotee.com
#===============================================================================================

clear
echo "#############################################################"
echo "# Install Shadowsocks(libev) for Debian or Ubuntu (32bit/64bit)"
echo "# Intro: http://www.zygotee.com"
echo "#"
echo "# Author: JR <admin@zygotee.com>"
echo "#"
echo "#############################################################"
echo ""

function check_sanity() {
	# Do some sanity checking.
	if [ $(/usr/bin/id -u) != "0" ]; then
		die 'Must be run by root user'
	fi

	if [ ! -f /etc/debian_version ]; then
		die "Distribution is not supported"
	fi
}

function die() {
	echo "ERROR: $1" > /dev/null 1>&2
	exit 1
}

############################### install function##################################
function install_shadowsocks() {
# Make sure only root can run our script
check_sanity

cd $HOME

# install
apt-get update
apt-get install -y --force-yes build-essential autoconf libtool libssl-dev git curl

#download source code
git clone https://github.com/madeye/shadowsocks-libev.git

#compile install
cd shadowsocks-libev
./configure --prefix=/usr
make && make install
mkdir -p /etc/shadowsocks-libev
cp ./debian/shadowsocks-libev.init /etc/init.d/shadowsocks-libev
cp ./debian/shadowsocks-libev.default /etc/default/shadowsocks-libev
chmod +x /etc/init.d/shadowsocks-libev

# Get IP address(Default No.1)
IP=`curl -s checkip.dyndns.com | cut -d' ' -f 6  | cut -d'<' -f 1`
if [ -z $IP ]; then
   IP=`curl -s ifconfig.me/ip`
fi

#config setting
echo "#############################################################"
echo "#"
echo "# Please input your shadowsocks server_port and password"
echo "#"
echo "#############################################################"
echo ""
echo "Please input server_port for shadowsocks-libev (443 is suggested):"
read -p "Default port: 443" serverport
if [ -z $serverport ]; then
	serverport=443
fi
echo "serverport: $serverport"
echo "#######################"

echo "Please input password for shadowsocks-libev:"
read -p "Default passwd: lalala" shadowsockspwd
if [ -z $shadowsockspwd ]; then
	shadowsockspwd=XXXXXX
fi
echo "password: $shadowsockspwd"
echo "#######################"

# Config shadowsocks
cat > /etc/shadowsocks-libev/config.json<<EOF
{
    "server":"${IP}",
    "server_port":${serverport},
    "local_port":1080,
    "password":"${shadowsockspwd}",
    "timeout":60,
    "method":"rc4-md5"
}
EOF

#restart
/etc/init.d/shadowsocks-libev restart

#start with boot
update-rc.d shadowsocks-libev defaults

#install successfully
    echo ""
    echo "Congratulations, shadowsocks-libev install completed!"
    echo -e "Your Server IP: ${IP}"
    echo -e "Your Server Port: ${serverport}"
    echo -e "Your Password: ${shadowsockspwd}"
    echo -e "Your Local Port: 1080"
    echo -e "Your Encryption Method:rc4-md5"
}

############################### uninstall function##################################
function uninstall_shadowsocks() {
#change the dir to shadowsocks-libev
cd $HOME
cd shadowsocks-libev

#stop shadowsocks-libev process
/etc/init.d/shadowsocks-libev stop

#uninstall shadowsocks-libev
make uninstall
make clean
cd ..
rm -rf shadowsocks-libev

# delete config file
rm -rf /etc/shadowsocks-libev

# delete shadowsocks-libev init file
rm -f /etc/init.d/shadowsocks-libev
rm -f /etc/default/shadowsocks-libev

#delete start with boot
update-rc.d -f shadowsocks-libev remove

echo "Shadowsocks-libev uninstall success!"

}

############################### update function##################################
function update_shadowsocks() {
     uninstall_shadowsocks
     install_shadowsocks
	 echo "Shadowsocks-libev update success!"
}

# Initialization
action=$1
[ -z $1 ] && action=install
case "$action" in
install)
    install_shadowsocks
    ;;
uninstall)
    uninstall_shadowsocks
    ;;
update)
    update_shadowsocks
    ;;	
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|uninstall|update}"
    ;;
esac
