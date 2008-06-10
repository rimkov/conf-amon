#!/bin/sh
##################################################################
# script permettant d'utiliser une connexion adsl avec un modem
# realise le 13/02/2003 par samuel morin <samuel.morin@ac-dijon.fr>
# Version Beta. 
# N'ayant pas les moyens de tester, je ne garantis pas le bon fonctionnement
# de ce script ....
#$Id: pptp.sh,v 1.1.1.1 2004/01/05 10:16:50 eole Exp $
##################################################################
# Appel Bibliothèque
#[ -x /usr/share/eole/FonctionsEole ] || {
#        echo "Pas de bibliotheque Eole !"
#        exit 1
#	}
#. /usr/share/eole/FonctionsEole

. ParseDico

## Renseignez ici les parametres de votre connexion adsl

mode_authentification="PAP" # mode d'authentification (PAP ou CHAP)
login_connexion="toto@titi.com" # nom d'utilisateur pour la connexion
passwd_connexion="tutu" #mot de passe pour la connexion

## creation des fichiers de conf
[ ! -e /etc/ppp/options.ori ] && mv /etc/ppp/options /etc/ppp/options.ori
[ ! -e /etc/ppp/chap-secrets.ori ] && mv /etc/ppp/options /etc/ppp/chap-secrets.ori
[ ! -e /etc/ppp/pap-secrets.ori ] && mv /etc/ppp/options /etc/ppp/pap-secrets.ori

if [ $mode_authentification == PAP ]
then
	cat > /etc/ppp/pap-secrets <<EOF
	$login_connexion           *        $passwd_connexion     *
EOF

	rm /etc/ppp/chap-secrets

else
	cat > /etc/ppp/chap-secrets <<EOF
	$login_connexion           *        $passwd_connexion     *
EOF

	rm /etc/ppp/pap-secrets	
	
fi

	cat > /etc/ppp/options <<EOF
	#debug
	name "$login_connexion"
	noauth
	noipdefault
	defaultroute
	mtu 1492
	mru 2400
EOF

# on active le module ppp
modprobe ppp

# lancement du service
if [ -e /var/run/pptp/* ] 
	then
		killall pppd
		killall pptp
		rm -f /var/run/pptp/* 
	fi
pptp $adresse_ip_eth0
