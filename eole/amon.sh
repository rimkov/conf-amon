#!/bin/bash
#################################################
# amon.sh
# script de configuration d'amon
# execute par instance
#################################################

. ParseDico

## Test si une adresse reseau est bien spécifié
#identique a reconf-amon.sh
if [ "$adresse_ip_eth0" = "" ]; then
        echo "Impossible de déterminer l'adresse réseau \"adresse_ip_eth0\"."
        echo "Essayer de le relancer :"
        echo "/etc/init.d/networking restart"
        echo "Et relancer le reconfigure"
        exit 1
fi
#

echo "Initialisation DNS "
if [ ! -e /var/run/bind/run ]
then
    mkdir -p /var/run/bind/run
    #chown -R bind:bind /var/run/bind
fi
/usr/share/eole/gen_dns
cp -f /etc/bind/db.root /etc/bind/db.cache

# modification du lien renvoyant vers les messages d'erreurs de squid
rm -f /etc/squid/errors
ln -s /usr/share/squid/errors/French /etc/squid/errors
chown proxy.proxy /var/spool/squid

## activation du rvp
if [ "$install_rvp" == "oui" -a ! -e /etc/eole/Tunnel.conf ]
then
	echo
	echo "Voulez-vous configurer le Réseau Virtuel Privé maintenant ? [oui/non]"
	read Rep

	if [ "$Rep" = "oui" -o "$Rep" = "o" -o "$Rep" = "O" ]
	then
		/usr/share/eole/active_rvp.sh
	fi
	echo
fi

#Enregistrement des sondes (desactivé si pas de Zephir)
#/usr/share/eole/enregistrement_sonde.sh enreg

# FIXME : plus utilisé sur 2.2
# creation base rrdtools
#/usr/share/eole/create-rrd.sh
echo "Mise en place de la configuration dansguardian"

# suppression des données dans /etc/dansguardian/
etcdanspath='/etc/dansguardian'
mkdir -p $etcdanspath
rm -rf $etcdanspath/*

danspath="/usr/share/eole/dansguardian"
# remplacement du script d'init (2 instances)
cp -f $danspath/init/dansguardian /etc/init.d/dansguardian
# mise à niveau de la configuration
$danspath/init_dans.py
