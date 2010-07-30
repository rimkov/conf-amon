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

