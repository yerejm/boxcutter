#!/bin/bash

if [[ ! "$DESKTOP" =~ ^(true|yes|on|1|TRUE|YES|ON])$ ]]; then
  exit
fi

apt-get install -y task-lxde-desktop i3

# just in case the previous command failed to download all packages do it again
apt-get install -y task-lxde-desktop i3

LIGHTDM_CONFIG=/etc/lightdm/lightdm.conf

# Configure lightdm autologin.

if [ -f $LIGHTDM_CONFIG ]; then
    sed -i s/^#autologin-user=$/autologin-user=vagrant/ $LIGHTDM_CONFIG
    sed -i s/^#autologin-user-timeout=0$/autologin-user-timeout=0/ $LIGHTDM_CONFIG
    sed -i s/^#user-session=default$/user-session=i3/ $LIGHTDM_CONFIG
fi

# Need to disable NetworkManager because it overwrites vagrant's
# settings in /etc/resolv.conf with empty content in the first boot.
# So, DNS doesn't work on the first boot.
#
# Maybe there is a better solution then disabling the service.
systemctl disable NetworkManager.service

echo "==> Removing desktop components"
apt-get -y purge gnome-getting-started-docs clipit xscreensaver
apt-get -y purge $(dpkg --get-selections | grep -v deinstall | grep libreoffice | cut -f 1)
apt -y autoremove
