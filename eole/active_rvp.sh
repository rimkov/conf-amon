#!/bin/bash
##############################################################
# active_rvp.sh
# Script VPN pour module Amon
# 12/2002
# $Id: active_rvp.sh,v 1.1.1.1.4.5 2005/03/29 12:59:24 sam Exp $
##############################################################

# Mode Dialog Graphique
ModeDialog=${ModeDialog=oui}
if [ "$ModeDialog" == "oui" ]
then
export DIALOGRC=$RepEole/.dialogrc
export ECHO=InfoBox2
fi
#service gpm status  >/dev/null
#if [ $? -ne 0 ]
#then
#	NOMOUSE="--nomouse"
#fi
TitreGen="EOLE  -  Configuration du Client RVP"
# Appel Bibliothèque

Ok () {
if [ "$1" -ne 0 ]
then
	Zecho "Problème copie Fichier "
	rm -fr $TempRep
	exit 1
fi
}

[ -x /usr/share/eole/FonctionsEole ] || {
        echo "Pas de bibliotheque Eole !"
        exit 1
}
. /usr/share/eole/FonctionsEole

RepEole="/usr/share/eole/"
IpSecRep="/etc/freeswan"
TempRep="/tmp/TempIpsec"
TempRep1="/tmp/TempIpsec-ori"
Param=$1
ModeZephir=0

####### FONCTIONS ##############

# question dans le menu
Question()
{
	InputBox "$1" Rep "$3"
	if [ "$Rep" == "oui" -o "$Rep" == "o" -o "$Rep" == "O" ] 
	then
		exit 1
	fi
	eval $2=$Rep
}

## Suppression des fichiers de conf, réinitialisation de l'ipsec
SuppConf()
{
	echo "suppression des fichiers de configuration et des certificats"
	echo "Voulez-vous continuer O/N"
	read Rep
	if [ $Rep == O ]
	then
		/etc/init.d/rvp stop
		rm -f /etc/eole/Tunnel.conf
		rm -f /etc/freeswan/ipsec_updown*
		rm -f /etc/freeswan/ipsec.conf
		rm -f /etc/freeswan/ipsec.secrets
		rm -f /etc/freeswan/test-rvp
		rm -f /etc/freeswan/ipsec.d/*.pem
		rm -f /etc/freeswan/ipsec.d/private/*.pem
		rm -f /etc/freeswan/ipsec.d/cacerts/*.pem
		rm -f /usr/share/eole/test-rvp 
		/usr/sbin/update-rc.d -f rvp remove >/dev/null 2>&1
		exit 1
	else
		exit 1
	fi
}

DefSupport() 
{
	MenuBox "Support comportant les fichiers de configuration ipsec" Rep "/media/floppy Disquette /root Choix_Manuel zephir zephir" #/media/removable USB 
	if [ "$Rep" == "CANCEL" ]
	then
		echo  "La procédure est stoppée!"
		exit 1
	fi
	if [ "$Rep" == "zephir" ]
	then
		ModeZephir=1
		if [ ! $ZephirActif -eq 0 ]
		then
			Zecho "Ce serveur n'est pas enregistré sur zephir !"
			exit 1
		fi
		if [ ! -d /root/tmp/ConfIpsec ]
		then
			mkdir -p /root/tmp/ConfIpsec
		fi
		SupportConf="/root/tmp/ConfIpsec"
		rc=1
		while [ $rc -ne 0 ]
		do
			Question "login zephir (rien pour annuler)" "login"
			if [ "$login" == "" ]
			then
				exit 1
			fi
			Question "mot de passe" "passwd" "secret"
			Question "identifiant zephir du serveur sphynx" "id_sphynx"
			$RepEole/zephir_rvp.py "$login" "$passwd" "$id_sphynx" "$SupportConf" > /tmp/retour 2>&1
			rc=$?
                        if [ $rc -ne 0 ]
			then
				dialog $NOMOUSE --title "Récupération de configuration" --exit-label "Quitter" --textbox /tmp/retour 0 0
				exit 1
			fi
		done
		if [ ! -e $SupportConf/Id ]
		then
			Zecho "Fichiers configurations non trouvés dans $SupportConf"
			echo  "La procédure est stoppée!"
			exit 1
		fi
		RepConfIpsec=$SupportConf
	else	
		SupportConf=$Rep
		## On monte la disquette si support = floppy
		if [ "$SupportConf" == "/media/floppy" ]
		then
			umount /media/floppy > /dev/null 2>&1
			mount /media/floppy > /dev/null 2>&1
			if [ $? -ne 0 ]
			then
				Zecho "Problème disquette"
				echo  "La procédure est stoppée!"
				exit 1
			fi
		fi
		## On monte le repertoire removable si support = usb
		if [ "$SupportConf" == "/media/removable" ]
		then
			umount /media/removable > /dev/null 2>&1
			mount /media/removable > /dev/null 2>&1
			if [ $? -ne 0 ]
			then
				Zecho "Problème usb"
				echo  "La procédure est stoppée!"
				exit 1
			fi
		fi
		## Si support autre que disquette on ouvre un menu permettant de selectionner le repertoire contenant les fichiers de conf
		if [ "$SupportConf" != "/media/floppy" ]
		then
			#Zecho "reponse : $Rep"
			#read Pause
			if [ $ModeZephir -eq 1 ]
			then
				RepConfIpsec=$SupportConf
			else
				Fichier=`dialog $NOMOUSE --stdout --fselect $SupportConf 0 0 `
				if [ $? -eq 0 ]
				then
					RepConfIpsec=$Fichier
				else
					echo  "La procédure est stoppée!"
					exit 1
				fi
			fi
		else 
			## On initialise RepConfIpsec avec la valeur /media/floppy si on utilise floppy
			RepConfIpsec=$SupportConf
		fi
		if [ ! -e $RepConfIpsec/Id ]
		then
			Zecho "Fichiers configurations non trouvés dans $SupportConf"
			echo  "La procédure est stoppée!"
			exit 1
		fi
	fi
}
#################################
## Passage de paramètres en options
if [ "$Param" == "" ]
then
        Param="Normal"
fi
case $Param in
	--delete)
		SuppConf ;;      

	--zephir)
		if [ $ZephirActif != 0 ]
		then
			echo "Ce serveur n'est pas enregistré sur zephir !"
			exit 1
		fi
		SupportConf="/root/tmp/ConfIpsec"
		rc=1
		while [ ! $rc -eq 0 ]
		do
			echo -n "login zephir (rien pour annuler) :" 
			read login
			if [ "$login" == "" ]
			then
				exit 1
			fi
			stty -echo
			echo -n "mot de passe :"
			read passwd
			stty echo
			echo  -n "identifiant zephir du serveur sphynx :"
			read id_sphynx
			$RepEole/zephir_rvp.py "$login" "$passwd" "$id_sphynx" "$SupportConf" > /tmp/retour 2>&1
			rc=$?
                        if [ $rc -ne 0 ]
			then
				dialog $NOMOUSE --title "Récupération de configuration" --exit-label "Quitter" --textbox /tmp/retour 0 0
				exit 1
			fi
		done
		if [ ! -e $SupportConf/Id ]
		then
			Zecho "Fichiers configurations non trouvés dans $SupportConf"
			echo  "La procédure est stoppée!"
			exit 1
		fi
		RepConfIpsec=$SupportConf ;;

	Normal)
		DefSupport;;
esac

######## Procedure de mise en place des fichiers de conf et d'activation du VPN ##############
echo "Activation de la fonction Réseau Virtuel Privé"
echo "En cours ..."

if [ ! -d $IpSecRep ]
then
	echo "Repertoire IPSEC : $IpSecRep non trouvé"
	echo  "La procédure est stoppée!"
	exit 1
fi
# arret du service rvp
/etc/init.d/rvp stop >/dev/null 2>&1
# Copie de Travail
rm -fr $TempRep  >/dev/null 2>&1
mkdir $TempRep
chmod 700 $TempRep
cp $RepConfIpsec/* $TempRep >/dev/null 2>&1

## On demonte les périphériques montés précédement
## S'il s'agit d'un repertoire sur le DD, on le supprime
if [ "$SupportConf" == "/media/floppy" ]
then
	umount /media/floppy >/dev/null 2>&1
fi
if [ "$SupportConf" == "/media/removable" ]
then
	umount /media/removable >/dev/null 2>&1
fi
if [ "$SupportConf" != "/media/floppy" ] && {
	[ "$SupportConf" != "/media/removable" ]
}
then
	echo "Suppression fichiers de $RepConfIpsec"
	rm -f $RepConfIpsec/ipsec*
	rm -f $RepConfIpsec/*.pem
	rm -f $RepConfIpsec/*.pkcs7
	rm -f $RepConfIpsec/*.p10
fi

## On vérifie l'existance du fichier Id
TestFichier $TempRep/Id
Cn=`cat $TempRep/Id`
# On Range mais on stoppe si une erreur
# Fichier de conf Freeswan

if [ -e  /etc/eole/Tunnel.conf ]
then
	echo "Mise à Niveau de la configuration RVP existante "
	[ -d /tmp/freeswan ] || mkdir /tmp/freeswan
	cp -f -R $IpSecRep/* /tmp/freeswan >/dev/null 2>&1
	/usr/share/eole/MergeFic.py  -i $TempRep/ipsec.conf_$Cn -o /tmp/freeswan/ipsec.conf -r $IpSecRep/ipsec.conf -d DEB:$Cn -f FIN:$Cn
	Ok $?
	/usr/share/eole/MergeFic.py  -i $TempRep/ipsec.secrets_$Cn -o /tmp/freeswan/ipsec.secrets -r $IpSecRep/ipsec.secrets -d DEB:$Cn -f FIN:$Cn
	Ok $?
	/usr/share/eole/MergeFic.py  -i $TempRep/test-rvp -o /usr/share/eole/test-rvp -r $IpSecRep/test-rvp -d DEB:$Cn -f FIN:$Cn
	Ok $?
	cp -f $IpSecRep/test-rvp /usr/share/eole/test-rvp
	mv -f $TempRep/ipsec_updown*$Cn* $IpSecRep
	Ok $?
	chmod 700  $IpSecRep/ipsec_updown*$Cn*

	[ `grep "=$Cn=" /etc/eole/Tunnel.conf` ] || echo "=$Cn=" >> /etc/eole/Tunnel.conf 

else
	# Pas de fichier de conf on recopie tout
	echo "Mise en place configuration RVP"
	mv -f $TempRep/ipsec.conf_$Cn $IpSecRep/ipsec.conf
	Ok $?
	chmod 400 $IpSecRep/ipsec.conf
	mv -f $TempRep/ipsec.secrets_$Cn $IpSecRep/ipsec.secrets
	Ok $?
	chmod 400 $IpSecRep/ipsec.secrets
	mv -f $TempRep/ipsec_updown*$Cn* $IpSecRep
	Ok $?
	chmod 700  $IpSecRep/ipsec_updown*$Cn*
	echo "=$Cn=" > /etc/eole/Tunnel.conf 
	mv -f $TempRep/test-rvp /usr/share/eole/test-rvp
	chmod a+rx /usr/share/eole/test-rvp
fi

# Fichier Certificat (Si présent)
if [ -r $TempRep/CertifCa.pem ]
then
	mv -f $TempRep/CertifCa.pem $IpSecRep/ipsec.d/cacerts
	Ok $?
	chmod 400 $IpSecRep/ipsec.d/cacerts/CertifCa.pem
	echo "entrez le mot de passe de la clef privee"
	openssl rsa -in $TempRep/privkey.pem -out $IpSecRep/ipsec.d/private/priv$Cn.pem >/dev/null 2>&1
	while [ "$?" -ne 0 ]
	do
		echo "Problème Clé (mauvais mot de passe !)"
		echo "voulez vous reessayer (oui/non) ?"
		read Rep
		if [ "$Rep" == "oui" -o "$Rep" == "o" -o "$Rep" == "O" ]
		then
			echo "entrez le mot de passe de la clef privee"
			openssl rsa -in $TempRep/privkey.pem -out $IpSecRep/ipsec.d/private/priv$Cn.pem >/dev/null 2>&1
		else		
			echo "procedure de configuration du Reseau Prive Virtuel abandonnee"
			exit 1
		fi
	done
	rm -f $TempRep/privkey.pem
	Ok $?
	chmod 400 $IpSecRep/ipsec.d/private/priv$Cn.pem
	mv -f $TempRep/*.pem $IpSecRep/ipsec.d
	Ok $?
	chmod 400 $IpSecRep/ipsec.d/*.pem
fi
echo "Activation du service Reseau Virtuel Privé"
/usr/sbin/update-rc.d rvp defaults >/dev/null 2>&1
/etc/init.d/rvp start
if [ $? -ne 0 ]
then
	Zecho "Impossible d'activer Freeswan Ipsec"
	exit 1
fi
/etc/init.d/z_stats restart
Zecho "Le Vpn est configuré"
