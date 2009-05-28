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
e=/usr/share/eole/gen_dns
if [ ! -e /var/run/bind/run ]
then
    mkdir -p /var/run/bind/run
    #chown -R bind:bind /var/run/bind
fi
# FIXME
#TestExe "$e"
$e
cp -f /etc/bind/db.root /etc/bind/db.cache

# modification du lien renvoyant vers les messages d'erreurs de squid
rm -f /etc/squid/errors
ln -s /usr/share/squid/errors/French /etc/squid/errors
chown proxy.proxy /var/spool/squid

## activation du rvp
if [ "$install_rvp" == "oui" -a ! -e /etc/eole/Tunnel.conf ]
then
	echo
	echo "** Configuration du RVP **"
	echo
	echo "ATTENTION : vous aurez besoin de la disquette"
	echo "contenant les fichiers de configuration"
	echo
	echo "Voulez vous configurer le Reseau Virtuel Privé maintenant ? (oui/non)"
	read Rep

	if [ "$Rep" = "oui" -o "$Rep" = "o" -o "$Rep" = "O" ]
	then
		/usr/share/eole/active_rvp.sh
	fi
	echo
fi

# droit pour ces certificats nufw/nuauth
#identique a amon.sh
if [ "$active_nufw" == "oui" ]
then
	[ ! "$nuauth_tls_cacert" == "none" ] && chown root:nuauth $nuauth_tls_cacert && chmod 440 $nuauth_tls_cacert
	[ ! "$nuauth_tls_cert" == "none" ] && chown root:nuauth $nuauth_tls_cert && chmod 440 $nuauth_tls_cert
	[ ! "$nuauth_tls_key" == "none" ] && chown root:nuauth $nuauth_tls_key && chmod 440 $nuauth_tls_key
fi

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


# Utilisation manage-amon comme shell pour amon/amonecole et amon2 s'il existe
user=`cat /etc/eole/version | awk -F "-" '{ print $NR }'`
id $user &>/dev/null
if [ $? -eq 0 ]
then
	usermod -s /usr/share/eole/manage-amon.sh $user
fi
id amon2 &>/dev/null
if [ $? -eq 0 ]
then
	usermod -s /usr/share/eole/manage-amon.sh amon2
fi
echo
if [ "$activer_log_distant" == "oui" -o "$activate_tls" == "oui" ]; then
                if [ -e /etc/ssl/ca/ca-eole-rsyslog.pem ]; then
                        echo "Génération de la clé..."

                        /usr/bin/certtool --template /etc/ssl/eole-client-template.cnf --generate-privkey --outfile /etc/ssl/private/$nom_machine-key.pem --bits 2048

                        echo "Génération de la requête de signature..."

                        if [ ! -d /etc/ssl/request ]; then
                                mkdir -p /etc/ssl/request
                        fi

                        /usr/bin/certtool --template /etc/ssl/eole-client-template.cnf --generate-request --load-privkey /etc/ssl/private/$nom_machine-key.pem --outfile /etc/ssl/request/$nom_machine-rsyslog-request.pem

                        echo "Génération du couple clé/certificat signé..."

                        if [ ! -d /etc/ssl/certs ]; then
                                mkdir -p /etc/ssl/certs
                        fi

                        /usr/bin/certtool --template /etc/ssl/eole-client-template.cnf --generate-certificate --load-request /etc/ssl/request/$nom_machine-rsyslog-request.pem --outfile /etc/ssl/certs/$nom_machine-rsyslog-cert.pem --load-ca-certificate /etc/ssl/ca/ca-eole-rsyslog.pem --load-ca-privkey /etc/ssl/private/ca-eole-rsyslog-key.pem

                else
                        echo "Fichier CA de rsyslog non trouvé, merci de le transférer dans le répertoire /etc/ssl/ca"
                fi
fi

