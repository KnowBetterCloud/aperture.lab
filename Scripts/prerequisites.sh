#!/bin/bash

DOMAIN=aperture.lab

YUM=$(which dnf || which yum)

case OS in `lsb_release -ds`
  "Fedora release 37 (Thirty Seven)")
    sudo $YUM -y install libvirt virt-manager virt-install
  ;;
  *(
    sudo $YUM -y groupinstall Virtualizaiton 'Additional Virtualization Tools'
  ;;
esac

sudo systemctl enable libvirtd --now

cat << EOF | sudo tee -a /etc/hosts

# Kubernetes Lab
192.168.124.100 control-plane-0 control-plane-0.aperture.lab
192.168.124.110 worker-node-0 worker-node-0.aperture.lab
192.168.124.111 worker-node-1 worker-node-1.aperture.lab
EOF

sudo mkdir /home/ISOS; sudo chown qemu:qemu /home/ISOS


# NOTE:  Ansible is probably simple to install on Fedora and all this can be replaced with
#  dnf -y install ansible
#        So, check it out and fix this
install_ansible() {
python3 -m pip -v || { echo "ERROR: install pip"; exit 9; }
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py --user
python3 -m pip install --user ansible
}
# Test if ansible is already installed, and respond

for NODE in control-plane-0 worker-node-0 worker-node-1
do 
  ssh-copy-id mansible@$NODE.$DOMAIN
done

sudo dnf -y install httpd php
cd /var/www/
sudo mv html html.orig
sudo git clone https://github.com/KnowBetterCloud/blackmesa.git
sudo ln -s blackmesa html
sudo chown -R jradtke:jradtke blackmesa
sudo systemctl enable httpd --now
firewall-cmd --permanent --zone=libvirt --add-port=80/tcp
firewall-cmd --permanent --zone=libvirt --add-service=http
#firewall-cmd --permanent --zone=libvirt --add-interface=virbr0

firewall-cmd --reload

# HTTP OS Directory
cat << EOF | sudo tee /etc/httpd/conf.d/OS.conf
Alias "/OS" "/var/www/OS"
<Directory "/var/www/OS">
  Options FollowSymLinks Indexes
</Directory>
EOF

sudo mkdir /var/www/OS; sudo restorecon -RF /var/www/OS

# HTTP ISOS Directory
sudo cp /etc/fstab /etc/fstab.`date +%F`
cat << EOF | sudo tee -a /etc/fstab 
# BIND MOUNT FOR ISOS
/home/ISOS /var/www/ISOS
EOF
sudo mkdir /var/www/ISOS; 
sudo systemctl daemon-reload; sudo mount -a

cat << EOF | sudo tee /etc/httpd/conf.d/ISOS.conf
Alias "/ISOS" "/var/www/ISOS"
<Directory "/var/www/ISOS">
  Options FollowSymLinks Indexes
  DirectoryIndex index.php index.html
</Directory>
EOF
curl https://raw.githubusercontent.com/KnowBetterCloud/blackmesa/main/Files/index.php | sudo tee /var/www/ISOS/index.php 

sudo systemctl restart httpd

# Mount ISOS for Installation ISOS/rhel-8.7-x86_64 -> {webserver}/OS/rhel-8.7-x86_64
cat << EOF | sudo tee -a /etc/fstab
# ISO Mounts
/home/ISOS/rhel-8.7-x86_64-dvd.iso /var/www/OS/rhel-8.7-x86_64  iso9660 defaults,nofail 0 0
EOF
sudo mkdir /var/www/OS/rhel-8.7-x86_64
sudo systemctl daemon-reload; sudo mount -a

sudo semanage fcontext -a -t httpd_sys_content_t '/home/ISOS(/.*)?'
sudo semanage fcontext -a -t httpd_sys_content_t '/var/www/OS(/.*)?'
sudo restorecon -RFvv /home/ISOS /var/www/OS

