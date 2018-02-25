#!/bin/bash -e

on_chroot << EOF
usermod -l cgminer -m -d /home/cgminer pi
groupmod -n cgminer pi
echo "cgminer:cgminer" | chpasswd
EOF

install -m 644 files/etc/default/cgminer                    ${ROOTFS_DIR}/etc/default/
install -m 644 files/etc/default/keyboard                   ${ROOTFS_DIR}/etc/default/

install -m 644 files/etc/hostname                           ${ROOTFS_DIR}/etc/hostname

install -d                                                  ${ROOTFS_DIR}/etc/avahi
install -d                                                  ${ROOTFS_DIR}/etc/avahi/services
install -m 644 files/etc/avahi/avahi-daemon.conf            ${ROOTFS_DIR}/etc/avahi/
install -m 644 files/etc/avahi/services/http.service        ${ROOTFS_DIR}/etc/avahi/services/

#install -d                                                  ${ROOTFS_DIR}/etc/openvpn
#install -m 644 files/etc/openvpn/ca.crt                     ${ROOTFS_DIR}/etc/openvpn/
#install -m 644 files/etc/openvpn/cgminer.conf               ${ROOTFS_DIR}/etc/openvpn/
#install -m 644 files/etc/openvpn/cgminer.crt                ${ROOTFS_DIR}/etc/openvpn/
#install -m 600 files/etc/openvpn/cgminer.key                ${ROOTFS_DIR}/etc/openvpn/

install -d                                                  ${ROOTFS_DIR}/etc/sudoers.d
install -m 600 files/etc/sudoers.d/privacy                  ${ROOTFS_DIR}/etc/sudoers.d/
install -m 600 files/etc/sudoers.d/timeout                  ${ROOTFS_DIR}/etc/sudoers.d/
rm -f                                                       ${ROOTFS_DIR}/etc/sudoers.d/[0-9]*

install -m 755 files/usr/bin/cgminer-monitor                ${ROOTFS_DIR}/usr/bin/

install -m 644 files/lib/systemd/system/cgminer.service     ${ROOTFS_DIR}/lib/systemd/system/

install -m 644 files/vimrc                                  ${ROOTFS_DIR}/root/.vimrc
install -m 644 files/vimrc                                  ${ROOTFS_DIR}/home/cgminer/.vimrc

on_chroot << EOF
sed -i -e 's/raspberrypi/cgminer/g' /etc/hosts
EOF

on_chroot << EOF
touch /etc/modprobe.d/raspi-blacklist.conf

sed -i -e "s/#dtparam=i2c_arm=on/dtparam=i2c_arm=on/" /boot/config.txt
sed -i -e "s/^\(blacklist[[:space:]]*i2c[-_]bcm2708\)/#\1/" /etc/modprobe.d/raspi-blacklist.conf
sed /etc/modules -i -e "s/^#[[:space:]]*\(i2c[-_]dev\)/\1/"
if ! grep -q "^i2c[-_]dev" /etc/modules; then
  printf "i2c-dev\n" >> /etc/modules
fi

echo "" >>/boot/config.txt
echo "# Disable BT uart, make pl011 available" >>/boot/config.txt
echo "dtoverlay=pi3-disable-bt" >>/boot/config.txt
echo "" >>/boot/config.txt
sed -i -e "/blacklist btbcm/d; /blacklist hci_uart/d" /etc/modprobe.d/raspi-blacklist.conf
echo "blacklist btbcm" >>/etc/modprobe.d/raspi-blacklist.conf
echo "blacklist hci_uart" >>/etc/modprobe.d/raspi-blacklist.conf
systemctl disable hciuart
EOF

on_chroot << EOF
echo "Building cgminer..."
git clone https://github.com/ckolivas/cgminer 
cd cgminer
./autogen.sh
./configure --enable-avalon7
make
gcc api-example.c -Icompat/jansson-2.9/src -o cgiminer-api
chown root:root cgminer cgiminer-api
cp cgminer cgiminer-api /usr/bin
rm -rf cgminer
EOF

on_chroot << EOF
systemctl enable openvpn
systemctl enable ssh
systemctl enable cgminer
EOF

on_chroot << EOF
apt-get -y autoremove
EOF
