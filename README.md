
# VirtualBox Kickstart

These scripts setup a kickstart server for VirtualBox and automate the spin-up of VirtualBox instances.

Requirements:

- VirtualBox
- Running HTTP server

## kick_vbox_setup.sh

- Adjust `VBOXROOT` for your VirtualBox installation
- Be certain to use the same version with `PXESTUFF` variable as `CENTOSISO` in `kick_vbox_centos7.sh`
- Modify the reference to the kickstart server in the PXE Menu `ks=http://192.168.1.5`

## kick_vbox_centos7.sh

- Be certain `CENTOSISO` corresponds to `PXESTUFF` in `kick_vbox_setup.sh`



