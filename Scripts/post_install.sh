#!/bin/bash
WEBSERVER=192.168.124.1

# Pull down credentials and register host
export rhnuser=$(curl -s ${WEBSERVER}/OS/.rhninfo | grep rhnuser | cut -f2 -d\=)
export rhnpass=$(curl -s ${WEBSERVER}/OS/.rhninfo | grep rhnpass | cut -f2 -d\=)
[ ! -e $rhnuser ] && subscription-manager status || subscription-manager register --auto-attach --force --username="${rhnuser}" --password="${rhnpass}"

# Enable SUDO nopasswd for mansible user
echo "mansible ALL=(ALL)	NOPASSWD: ALL" | sudo tee /etc/sudoers.d/mansible

# If I am going to add a reboot at this point, I need to figure out how to make it NOT reboot if 
#   this host is currently being kickstarted
#sudo yum -y update 

