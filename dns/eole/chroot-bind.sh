#!/bin/bash
#################################################
# chroot-bind.sh
# script de configuration de la chroot de bind
# execute par instance-amon
# $Id: chroot-bind.sh,v 0.0.0.1 2006/11/29 10:41 freg Exp $
#################################################

# creation de l'arbo de la cage
[ -e/var/lib/chroot-named/etc ] || mkdir -p /var/lib/chroot-named/etc
cd  /var/lib/chroot-named
mkdir -p dev etc/namedb/slave var/run
cp -p /etc/bind/named.conf /var/lib/chroot-named/etc/
cp -a /etc/bind/* /var/lib/chroot-named/etc/namedb/
chown bind:bind /var/lib/chroot-named/var/run
mknod /var/lib/chroot-named/dev/null c 1 3
mknod /var/lib/chroot-named/dev/random c 1 8
chmod 666 /var/lib/chroot-named/dev/{null,random}
cp /etc/localtime /var/lib/chroot-named/etc/

chmod 700 /var/lib/chroot-named
cp -rf /etc/bind /var/lib/chroot-named/etc/bind
ln -s /var/lib/chroot-named/bind /etc/bind
chown -R bind:bind /var/lib/chroot-named
chown -h bind:bind /etc/bind

# specifique a ext2
#cd /var/lib/chroot-named/named
#chattr +i etc etc/localtime var

