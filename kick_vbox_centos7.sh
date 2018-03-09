#!/bin/bash

##
## Based on: https://sites.google.com/site/chrismacdermaid/odds-and-ends/kickstart-virtualbox
## Foundation: https://gist.github.com/jtyr/816e46c2c5d9345bd6c9
## 
## Very helpful for the CLI tricks: https://www.virtualbox.org/manual/ch08.html
##
## For cleaning up:
##
##  VBoxManage list vms
##  VBoxManage controlvm <vm> poweroff
##  VBoxManage unregistervm <vm> --delete
##

VBOX=`which VirtualBox`
VBOXMANAGE=`which VBoxManage`
VBOXBASE='/vbox'
VBOXTFTP="/root/.config/VirtualBox/TFTP"

RELEASE="7"
RANDSTR=`cat /dev/urandom|tr -cd "[:alnum:]" |head -c 5`
PXELINUX="./pxelinux.0"

KICKSTARTPATH="/var/www/html/kickstart" 
KICKSTARTMAIN="${KICKSTARTPATH}/centos7.cfg"
KICKSTARTTMPL="${KICKSTARTPATH}/centos7-template.cfg"
KICKSTARTCONFIGS="/var/www/html/kickstart/config" 
# CENTOSISO="/ddb2233/ISO/CentOS-7-x86_64-Minimal-1611.iso"
CENTOSISO="/ddb2233/ISO/CentOS-7-x86_64-Minimal-1708.iso"

CPU=1
RAM=512
DISK=5120

##
## The name of the vm's host network interface. 
##
# NIC=enp0s10
NIC=eno1

##
## Be careful, it seems special characters (eg, at least "_") don't work well here with PXELINUX
##
HOSTNAME=$2
IPADDR=$3
FQDN=${HOSTNAME}.local 

createks() {

rm -f ${KICKSTARTMAIN}
cat $KICKSTARTTMPL | sed -e s/_IPADDR_/${IPADDR}/ -e s/_HOSTNAME_/${HOSTNAME}/ > ${KICKSTARTPATH}/centos7-${HOSTNAME}.cfg
ln -s ${KICKSTARTPATH}/centos7-${HOSTNAME}.cfg ${KICKSTARTMAIN} 

cat ${KICKSTARTCONFIGS}/ifcfg-enp3s0.template | sed -e s/_IPADDR_/${IPADDR}/ -e s/_HOSTNAME_/${HOSTNAME}/ -e s/_FQDN_/${FQDN}/ \
	> ${KICKSTARTCONFIGS}/ifcfg-enp3s0.dist
cat ${KICKSTARTCONFIGS}/puppet.conf.template | sed -e s/_IPADDR_/${IPADDR}/ -e s/_HOSTNAME_/${HOSTNAME}/ -e s/_FQDN_/${FQDN}/ \
	> ${KICKSTARTCONFIGS}/puppet.conf.dist
cat ${KICKSTARTCONFIGS}/sshd_config.template | sed -e s/_IPADDR_/${IPADDR}/ -e s/_HOSTNAME_/${HOSTNAME}/ -e s/_FQDN_/${FQDN}/ \
	> ${KICKSTARTCONFIGS}/sshd_config.dist
cat ${KICKSTARTCONFIGS}/privoxy.config.template | sed -e s/_IPADDR_/${IPADDR}/ -e s/_HOSTNAME_/${HOSTNAME}/ -e s/_FQDN_/${FQDN}/ \
	> ${KICKSTARTCONFIGS}/privoxy.config.dist

}

createvm() {

# this must be available or we can't do anything...
if [ ! -e "$CENTOSISO" ]; then
 echo "Please correct the location of CENTOSISO: ${CENTOSISO}";
 exit 1;
fi

## This makes a random VM name if none is specified
[ "$HOSTNAME" == "" ] && VM="CentOS${RELEASE}${RANDSTR}" || VM=${HOSTNAME}

echo $VM >/tmp/.vmname

echo "Creating ${VM}"
VBOXINFO="${VBOXMANAGE} showvminfo ${VM}"

## Build the vbox image... 
${VBOXMANAGE} createvm --name "${VM}" --ostype "Linux_64" --register && \
${VBOXMANAGE} createhd --filename "${VBOXBASE}/${VM}/${VM}.vdi" --size ${DISK} && \
${VBOXMANAGE} modifyvm "${VM}" --cpus ${CPU} --memory ${RAM} && \

${VBOXMANAGE} storagectl "${VM}" --name "IDE" --add ide \
--controller PIIX4 && \

${VBOXMANAGE} storageattach "${VM}" --storagectl "IDE" --port 0 \
--device 0 --type hdd --medium "${VBOXBASE}/${VM}/${VM}.vdi" && \

## Put the cdrom in the tray...
${VBOXMANAGE} storageattach "${VM}" --storagectl "IDE" --port 1 \
--device 0 --type dvddrive --medium "${CENTOSISO}" && \

## boot from net / pxe 
${VBOXMANAGE} modifyvm "${VM}" --boot1 net --boot2 none --boot3 none --boot4 none

## The pxe file must have the same name as the VM. Symlinking works here. 
ln -s ${VBOXTFTP}/pxelinux.0 ${VBOXTFTP}/${VM}.pxe

## Start it up headless
${VBOXMANAGE} startvm "${VM}" --type=headless

echo "Please give some time for the machine to cook..."

}

postvm() {

VM=`cat /tmp/.vmname`

####################################################################
##
## First let's be sure the vm isn't running:
##
${VBOXMANAGE} showvminfo ${VM} | grep State | grep running

if [ "$?" -eq "0" ]; then
 echo "The VM is still cooking. Please try again in a few minutes."
 exit 1
fi
####################################################################

# make sure this vm comes up after host reboot
${VBOXMANAGE} modifyvm ${VM} --autostart-enabled on

# boot from disk
${VBOXMANAGE} modifyvm "${VM}" --boot1 disk --boot2 none --boot3 none --boot4 none && \

# eject iso
${VBOXMANAGE} storageattach "${VM}" --storagectl "IDE" --port 1 \
--device 0 --type dvddrive --medium "emptydrive" && \

# change NIC to bridged
${VBOXMANAGE} modifyvm "${VM}" --bridgeadapter1 ${NIC} && \
${VBOXMANAGE} modifyvm "${VM}" --nic1 bridged

# set it to use paravirtualization
# https://www.virtualbox.org/manual/ch10.html#gimproviders
${VBOXMANAGE} modifyvm "${VM}" --paravirtprovider kvm

# and then start it...
${VBOXMANAGE} startvm "${VM}" --type=headless

# Clean up... 
rm -f ${VBOXTFTP}/${VM}.pxe
# rm -f /tmp/.vmname

}


case "$1" in
  createks)
        createks
        ;;
  createvm)
        createvm
        ;;
  postvm)
        postvm
        ;;
  *)
        echo $"Usage: $0 { createks <hostname> <ipaddr> | createvm <hostname> | postvm }"
        exit 1
esac
