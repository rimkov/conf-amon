#!/bin/bash
######################################################
# amon-reconf.sh
# taches a executer lors d'une reconfiguration
######################################################

. ParseDico

## Test si une adresse reseau est bien spécifié
#identique a amon.sh
if [ "$adresse_ip_eth0" = "" ]; then
        echo "Impossible de déterminer l'adresse réseau \"adresse_ip_eth0\"."
        echo "Essayer de le relancer :"
        echo "/etc/init.d/networking restart"
        echo "Et relancer le reconfigure"
        exit 1
fi
#

for i in $*
do
        if [ "-ead" == "$i" ]
        then
                EAD='-ead'
        fi
done

## On regénère les db du dns
/usr/share/eole/gen_dns

## On rechroot bind
# mise en place de la cage pour bind
[ -e /var/lib/chroot-named/etc/named.conf ] || {
/usr/sbin/bind-chroot.sh -c /var/lib/chroot-named >/dev/null 2>&1
sleep 2
}

# FIXME : plus utilisé sur 2.2
# on relance le create-rrd (sans casser les bases !)
#/usr/share/eole/create-rrd.sh

echo "Mise en place de la configuration dansguardian"
# suppression des données dans /etc/dansguardian/
/etc/init.d/dansguardian stop > /dev/null
etcdanspath='/etc/dansguardian'
rm -rf $etcdanspath/*

danspath="/usr/share/eole/dansguardian"
# remplacement du script d'init (2 instances)
cp -f $danspath/init/dansguardian /etc/init.d/dansguardian
# mise à niveau de la configuration
$danspath/init_dans.py

# droit pour ces certificats nufw/nuauth
#identique a amon.sh
if [ "$active_nufw" == "oui" ]
then
        [ ! "$nuauth_tls_cacert" == "none" ] && chown root:nuauth $nuauth_tls_cacert && chmod 440 $nuauth_tls_cacert
        [ ! "$nuauth_tls_cert" == "none" ] && chown root:nuauth $nuauth_tls_cert && chmod 440 $nuauth_tls_cert
        [ ! "$nuauth_tls_key" == "none" ] && chown root:nuauth $nuauth_tls_key && chmod 440 $nuauth_tls_key
fi

# On supprime le service rvp au niveau des rc*.d s'il existe...
if [ -L /etc/rc3.d/S20rvp ]
then
	update-rc.d -f rvp remove >/dev/null 2>&1
fi

# On supprime le lancement de freeradius s'il n'est pas utilisé
if [ "freeradius" == "non" ]
then
	update-rc.d -f freeradius remove >/dev/null 2>&1
	/etc/init.d/freeradius stop >/dev/null 2>&1
fi

echo
