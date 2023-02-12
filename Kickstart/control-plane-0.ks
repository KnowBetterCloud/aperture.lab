#version=RHEL8
# Do NOT Use graphical install
text
skipx

selinux --enforcing
firewall --enabled
eula --agreed
reboot

#############################
# System Setup
# Keyboard layouts
keyboard --xlayouts='us'
# System language
lang en_US.UTF-8
# System timezone
timezone America/New_York --isUtc
# User Management 
rootpw --iscrypted $6$s//2LyziMwEoMwlE$RzK4L/BKXP9L6mmoHKlhm9b17l8HFoUexAOY7PAwjn8xuNvvwvra2AxLEoqGokPe0tBkuvba0hOKzZHxtQnSm.
user --groups=wheel --name=mansible --password=$6$TxwtDnLcfs08tYju$ZSRJXWX0P4eA3uxSH.E6rn.pbUyDFrL6ospFPOC.lfoP98r98eDwe4UH5CSrLGtFoA1Qi/pstB/UZNljDmSfR0 --iscrypted --gecos="My Aansible"
syspurpose --role="Red Hat Enterprise Linux Server" --sla="Standard" --usage="Production"

#############################
# Software Management 
# Use the Network Installation
url --url="http://192.168.124.1/OS/rhel-8.7-x86_64/"
repo --name="AppStream" --baseurl=http://192.168.124.1/OS/rhel-8.7-x86_64/AppStream

%packages
@^minimal-environment
nmap
kexec-tools
%end

#############################
# Network information
network  --bootproto=static --device=enp1s0 --gateway=192.168.124.1 --ip=192.168.124.100 --nameserver=192.168.124.1,8.8.8.8 --netmask=255.255.255.0 --ipv6=auto --activate
network  --hostname=control-plane-0.aperture.lab

#############################
# Disk Management
ignoredisk --only-use=vda
autopart
# Partition clearing information
clearpart --none --initlabel


%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end

%post --erroronfail --log=/root/ks-post.lo
echo "Note: configure SSH for root user"
echo "" | ssh-keygen -trsa -b2048 -N ''
curl -o /root/.ssh/authorized_keys http://192.168.124.1/Files/authorized_keys
chmod 0600 /root/.ssh/authorized_keys

echo "Note: configure SSH for mansible user"
su - mansible -c "echo | ssh-keygen -trsa -b2048 -N '' "
curl -o /home/mansible/.ssh/authorized_keys http://192.168.124.1/Files/authorized_keys
chown mansible:mansible /home/mansible/.ssh/authorized_keys
restorecon -RF /home/mansible/.ssh/
chmod 0600 /home/mansible/.ssh/authorized_keys

curl -o /root/post_install.sh http://192.168.124.1/Scripts/post_install.sh
chmod 0754 /root/post_install.sh
/root/post_install.sh
%end

