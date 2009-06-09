#!/bin/bash
##########################################################
# Manage AMON
# Mode Dialog
# PreVersion 2
# LB 01/2003 Eole Dijon
###########################################################

# Initialisation des variables
# Avec verification dans l'Environnement 
RepEole=${RepEole="/usr/share/eole"}
export PATH=$PATH:/sbin

# un seul manage ?
pmanage=`pgrep manage-amon.sh`
nbmanage=`echo $pmanage | wc -w`

# Mode Dialog Graphique
ModeDialog=${ModeDialog=oui}
if [ "$ModeDialog" == "oui" ]
then
export DIALOGRC=$RepEole/.dialogrc
export ECHO=InfoBox2
fi
service gpm status &>/dev/null
if [ $? -ne 0 ]
then
	NOMOUSE="--nomouse"
fi

TitreGen="Eole  -  Gestion Serveur AMON "
# Appel Bibliothèque
[ -x $RepEole/FonctionsEole ] || {
        echo "Pas de bibliotheque Eole !"
        exit 1
	}
. $RepEole/FonctionsEole

Question()
{
InputBox "$1" Rep
if [ "$Rep" == "CANCEL" ] 
then
echo "Abandon"	
exit 1
fi
}

Entree(){
echo
echo  "Tapez <Entree>"
read Bidon
}
if [ $nbmanage -gt 1 ]
then
	MenuBox "D'autres instances de manage-amon ont été détectées" Rep "1 Quitter_sans_tuer 2 Quitter_et_tuer"
	if [ "$Rep" == "2" ]
	then
		for pid in $pmanage
		do
			kill -9 $pid
		done
	fi
	exit 1
fi

OkBox "Administration AMON \n\nPour Vous Deplacer sur l'Ecran\nUtiliser votre Souris\nOu la touche tabulation.\n\n"
	
FileCpt="$Tmp/Amon$TmpSuff"
touch $FileCpt

Rep=""
while [ 1 ]
do
MenuBox "Votre Choix"  Rep "1 Diagnostique_Amon 2 Reconfiguration 3 Paquets_en_Maj 4 Mise_A_Jour 5 Maj_blacklists 8 Redemarrer_Serveur 9 Arret_Serveur ! Shell_Linux  Q Quitter"

if [ "$Rep" == "CANCEL" ] 
then
	echo "Abandon"	
	exit 1
fi

case $Rep in
	1) 
	echo "En cours ..."
	sudo /usr/bin/diagnose 
	Entree
	;;
	2) 
	sudo /usr/bin/reconfigure 
	Entree
	;;
	3)
	sudo /usr/bin/Query-Auto
	Entree
	;;
	4) 
	sudo /usr/bin/Maj-Auto
	Entree
	;;
	5)
	sudo /usr/share/eole/Maj-blacklist.sh
	Entree
	;;
	8)
	QuestionBox "Vous avez demandé le redémarrage du serveur\nEtes vous sur ?" Rep
	if [ "$Rep" == "OUI" ] 
	then
	sudo /sbin/reboot
	exit 0
	fi
	;;
	9)
	QuestionBox "Vous avez demandé un arret total du serveur\nEtes vous sur ?" Rep
	if [ "$Rep" == "OUI" ] 
	then
	sudo /sbin/halt
	exit 0
	fi
	;;
	!)
	echo "exit pour revenir au Menu"
        /bin/bash	
        ;;
	Q)
	exit 0
	;;

esac
done
