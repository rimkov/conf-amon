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

# On supprime le service rvp au niveau des rc*.d s'il existe...
if [ -L /etc/rc3.d/S20rvp ]
then
	update-rc.d -f rvp remove >/dev/null 2>&1
fi

echo
