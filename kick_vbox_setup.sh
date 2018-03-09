#!/bin/bash

##
##
## This is a quick and dirty scripted hack of Jiri Tyr's instructional:
##   https://gist.github.com/jtyr/816e46c2c5d9345bd6c9
##
## See also: http://www.syslinux.org
##

VBOXROOT="/vbox"
DATE=`date "+%Y%m%d"`

ROOTCONFIG=/root/.config
VBOX=${ROOTCONFIG}/VirtualBox
VBOXTFTP=${ROOTCONFIG}/VirtualBox/TFTP
PXESTUFF="http://mirror.centos.org/centos/7.4.1708/os/x86_64/images/pxeboot"

mv ${VBOX} ${VBOX}.${DATE}

# mkdir -p ~/.config/VirtualBox/TFTP/pxelinux.cfg
mkdir -p ${VBOXTFTP}/pxelinux.cfg
yum -y install syslinux 
cp -f /usr/share/syslinux/{pxelinux.0,{menu,vesamenu,chain}.c32} ${VBOXTFTP}

mkdir ${VBOXTFTP}/pxeboot
cd ${VBOXTFTP}/pxeboot
# wget http://mirror.centos.org/centos/7.3.1611/os/x86_64/images/pxeboot/{initrd.img,vmlinuz}
wget ${PXESTUFF}/{initrd.img,vmlinuz}

cat <<EoF > ${VBOXTFTP}/pxelinux.cfg/default

PROMPT 0
TIMEOUT 100
NOESCAPE 0
ALLOWOPTIONS 0
DEFAULT menu.c32

MENU TITLE myPXE Menu

LABEL myCentOS7Label
  MENU LABEL myCentOS7
  KERNEL ./pxeboot/vmlinuz
  APPEND initrd=./pxeboot/initrd.img ks=http://192.168.1.5/kickstart/centos7.cfg ip=dhcp ramdisk_size=10000 text

EoF
