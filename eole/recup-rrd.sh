#!/bin/bash

#######################################################
# script de récupération des données (traffic et squid)
# et de création des graphiques pour l'ead
# par bruno boiget (CETIAD)
# $Id: recup-rrd.sh,v 1.1.1.1 2004/01/05 10:16:50 eole Exp $
#######################################################

# Appel Bibliothèque eole
#[ -x /usr/share/eole/FonctionsEole ] || {
#   echo "Pas de bibliotheque Eole !"
#        exit 1
#}
#. /usr/share/eole/FonctionsEole

# définition de la fonction cat_proc
cat_proc(){

	if [ "$2" == "in" ]
	then
		# On récupère le champ octets reçus de l'interface $2
	        echo `cat /proc/net/dev | grep $1 | sed -e ";s/:/ /g;" | sed -e ":;s/  / /g;t" | cut -d " " -f 3`
	elif [ "$2" == "out" ]
	then
		# On récupère le champ octets transmis de l'interface $2
	        echo `cat /proc/net/dev | grep $1 | sed -e ";s/:/ /g;" | sed -e ":;s/  / /g;t" | cut -d " " -f 11`
	else
		# Erreur, le deuxième argument n'est ni "in" ni "out"
		echo "usage : cat_proc <interface> <in/out>"
	        exit -1
	fi
}



# On Récupère les variables spécifiques Eole
. ParseDico

# ***************************************************
# Mise en place des variables nécessaires au script
# ***************************************************

# On vérifie le nombre de carte réseaux (3 ou 4) de la machine
nb_interface=`cat /proc/net/dev | grep eth | wc -l | tr -d  " "`

# répertoire des bases de données
REP_BAS_RRD=/usr/share/ead/rrd

# répertoire des images
REP_IMG_RRD=/var/www/ead/stats/rrd/image

# répertoire des scripts
REP_SCRIPTS=/usr/share/eole

					
# récupération de la mémoire physique existante
phys_mem_size=`cat /proc/meminfo | grep Mem: | cut -f3 -d " "`

# Définition de la valeur seuil pour les alertes
# Pour les cartes réseaux (10 Mo)
seuil_if=10000000
# Pour Squid
#http : 2 Mo/s (Attention : cette valeur doit être exprimée en Ko/s et non octets/s)
#cpu : 95 %
seuil_http=2000
seuil_cpu=95

# définition des échelles pour les graphes (val max en y par défaut)

# valeur limite des débits (octets/s)
lim_octets=400000
# valeur limite des pourcentages (%)
lim_pourcent=105
# valeur limite des requetes (req/s)
lim_req=20

# étendue des graphiques journaliers (en secondes)
duree_jour=86400

# *******************************
# Mise à jour des statistiques
# *******************************


# Lecture des statistiques des différentes interfaces réseau et mise à jour de la base rrd correspondante
#
# On lit ces données directement dans /proc/net/dev
# le script utilisé cat_proc.sh a pour but d'isoler les valeurs utiles
# (paramètres : nom de l'interface réseau et type de flux : entrée ou sortie)

# remplacer le répertoire par une variable ?
cd "$REP_BAS_RRD"

# debug : vérification de la fonction cat_proc
# echo `cat_proc eth0 out`

rrdtool update eth0.rrd `perl -e 'print time'`:`cat_proc eth0 in`:`cat_proc eth0 out`

rrdtool update eth1.rrd `perl -e 'print time'`:`cat_proc eth1 in`:`cat_proc eth1 out`

rrdtool update eth2.rrd `perl -e 'print time'`:`cat_proc eth2 in`:`cat_proc eth2 out`

if [ "$nb_interface" != "3" ]
then
	rrdtool update eth3.rrd `perl -e 'print time'`:`cat_proc eth3 in`:`cat_proc eth3 out`
fi


#monitoring de squid
# base des oid pour squid : "1.3.6.1.4.1.3495.1"
# données à surveiller:
#	- Ko/s en entrée (http)
#	- Ko/s en sortie (http)
# à la sortie de snmpget, on obtient un résultat de la forme 'Counter32: 27278049'
# On supprime donc tout ce qui n'est pas numérique


rrdtool update squid_http.rrd \
`perl -e 'print time'`\
:`snmpget -v2c -Ov -Pe -m /usr/share/squid/mib.txt 127.0.0.1:3401 -c public enterprises.3495.1.3.2.1.4 | cut -d" " -f 2`\
:`snmpget -v2c -Ov -Pe -m /usr/share/squid/mib.txt 127.0.0.1:3401 -c public enterprises.3495.1.3.2.1.5 | cut -d" " -f 2`

rrdtool update squid_ratio.rrd \
`perl -e 'print time'`\
:`snmpget -v2c -Ov -Pe -m /usr/share/squid/mib.txt 127.0.0.1:3401 -c public enterprises.3495.1.3.2.2.1.9.5 | cut -d" " -f 2`\
:`snmpget -v2c -Ov -Pe -m /usr/share/squid/mib.txt 127.0.0.1:3401 -c public enterprises.3495.1.3.2.2.1.10.5 | cut -d" " -f 2`

rrdtool update squid_request.rrd \
`perl -e 'print time'`\
:`snmpget -v2c -Ov -Pe -m /usr/share/squid/mib.txt 127.0.0.1:3401 -c public enterprises.3495.1.3.2.1.10 | cut -d" " -f 2`\
:`snmpget -v2c -Ov -Pe -m /usr/share/squid/mib.txt 127.0.0.1:3401 -c public enterprises.3495.1.3.2.1.1 | cut -d" " -f 2`

# **************************************************************************
# création des graphiques de charge et gestion des alarmes (ead ou mail)
# on appelle le script alerte.pl pour chaque interface surveillée
# **************************************************************************

# --upper-limit : taille minimum de l'axe vertical. Si une valeur dépasse cette taille, l'axe est mis
# à l'échelle pour afficher toutes les valeurs
# --start -300 : affiche les 300 dernières secondes (5 minutes)

# ***************************
# graphiques sur la journée
# ***************************

rrdtool graph pic-eth0.gif --start -$duree_jour \
--title "Entrées/Sorties vers l'extérieur" \
--vertical-label "octets/s" \
--width 350 --height 150 --upper-limit $lim_octets \
DEF:inoctets=eth0.rrd:input:AVERAGE \
DEF:outoctets=eth0.rrd:output:AVERAGE \
AREA:outoctets#0000FF:"Sortie" \
LINE2:inoctets#00FF00:"Entrée"

# paramètre : nom de l'interface (fichier interface.rrd) et seuil de surcharge en octets/s.

$REP_SCRIPTS/alerte.pl -i eth0 -s $seuil_if

rrdtool graph pic-eth1.gif --start -$duree_jour \
--title "Entrées/Sorties vers le sous réseau $nom_machine_eth1" \
--vertical-label "octets/s" \
--width 350 --height 150 --upper-limit $lim_octets \
DEF:inoctets=eth1.rrd:input:AVERAGE \
DEF:outoctets=eth1.rrd:output:AVERAGE \
AREA:outoctets#0000FF:"Sortie" \
LINE2:inoctets#00FF00:"Entrée"

$REP_SCRIPTS/alerte.pl -i eth1 -s $seuil_if

rrdtool graph pic-eth2.gif --start -$duree_jour \
--title "Entrées/Sorties vers le sous réseau $nom_machine_eth2" \
--vertical-label "octets/s" \
--width 350 --height 150 --upper-limit $lim_octets \
DEF:inoctets=eth2.rrd:input:AVERAGE \
DEF:outoctets=eth2.rrd:output:AVERAGE \
AREA:outoctets#0000FF:"Sortie" \
LINE2:inoctets#00FF00:"Entrée"

$REP_SCRIPTS/alerte.pl -i eth2 -s $seuil_if

if [ "$nb_interface" != "3" ]
then
	rrdtool graph pic-eth3.gif --start -$duree_jour \
	--title "Entrées/Sorties vers le sous réseau $nom_machine_eth3" \
	--vertical-label "octets/s" \
	--width 350 --height 150 --upper-limit $lim_octets \
	DEF:inoctets=eth3.rrd:input:AVERAGE \
	DEF:outoctets=eth3.rrd:output:AVERAGE \
	AREA:outoctets#0000FF:"Sortie" \
	LINE2:inoctets#00FF00:"Entrée"

	$REP_SCRIPTS/alerte.pl -i eth3 -s $seuil_if
fi

# surveillance de squid :


# requetes Serveur/Clients

rrdtool graph pic-squid-req.gif \
--start -$duree_jour --title "Requêtes sur le cache squid" \
--vertical-label "Requêtes/s" --width 350 --height 150 --upper-limit $lim_req \
DEF:serveur=squid_request.rrd:serveur:AVERAGE \
DEF:client=squid_request.rrd:client:AVERAGE \
AREA:client#0000FF:"clients (demandes)" \
LINE2:serveur#FF0000:"serveurs (réponses hors cache)"


# traffic HTTP moyen

rrdtool graph pic-squid-http.gif \
--start -$duree_jour --title "Traffic HTTP sur le cache squid" \
--vertical-label "octets/s" --width 350 --height 150 --upper-limit $lim_octets \
DEF:inoctets=squid_http.rrd:input:AVERAGE \
DEF:outoctets=squid_http.rrd:output:AVERAGE \
CDEF:ink=inoctets,1000,* \
CDEF:outk=outoctets,1000,* \
AREA:outk#0000FF:"Sortie" \
LINE2:ink#00FF00:"Entrée"

$REP_SCRIPTS/alerte.pl -i squid-http -s $seuil_http

# efficacité du cache (hits/requests)

rrdtool graph pic-squid-ratio.gif \
--start -$duree_jour --title "Hit ratio" \
--vertical-label "%" --width 350 --height 150 --upper-limit $lim_pourcent \
DEF:hits=squid_ratio.rrd:hits-ratio:AVERAGE \
DEF:bytes=squid_ratio.rrd:bytes-ratio:AVERAGE \
AREA:hits#FF0000:"hits-ratio" \
LINE2:bytes#0000FF:"bytes-ratio" \


# *************************
# graphes sur la semaine
# *************************



rrdtool graph pic-sem-eth0.gif --start -604800 \
--title "Entrées/Sorties vers l'extérieur" \
--vertical-label "octets/s" \
--width 350 --height 150 --upper-limit $lim_octets \
DEF:inoctets=eth0.rrd:input:AVERAGE \
DEF:outoctets=eth0.rrd:output:AVERAGE \
AREA:outoctets#0000FF:"Sortie" \
LINE2:inoctets#00FF00:"Entrée"


rrdtool graph pic-sem-eth1.gif --start -604800 \
--title "Entrées/Sorties vers le sous réseau $nom_machine_eth1" \
--width 350 --height 150 --upper-limit $lim_octets \
--vertical-label "octets/s" \
DEF:inoctets=eth1.rrd:input:AVERAGE \
DEF:outoctets=eth1.rrd:output:AVERAGE \
AREA:outoctets#0000FF:"Sortie" \
LINE2:inoctets#00FF00:"Entrée"

rrdtool graph pic-sem-eth2.gif --start -604800 \
--title "Entrées/Sorties vers le sous réseau $nom_machine_eth2" \
--width 350 --height 150 --upper-limit $lim_octets \
--vertical-label "octets/s" \
DEF:inoctets=eth2.rrd:input:AVERAGE \
DEF:outoctets=eth2.rrd:output:AVERAGE \
AREA:outoctets#0000FF:"Sortie" \
LINE2:inoctets#00FF00:"Entrée"

if [ "$nb_interface" != "3" ]
then
	rrdtool graph pic-sem-eth3.gif --start -604800 \
	--title "Entrées/Sorties vers le sous réseau $nom_machine_eth3" \
	--vertical-label "octets/s" \
	--width 350 --height 150 --upper-limit $lim_octets \
	DEF:inoctets=eth3.rrd:input:AVERAGE \
	DEF:outoctets=eth3.rrd:output:AVERAGE \
	AREA:outoctets#0000FF:"Sortie" \
	LINE2:inoctets#00FF00:"Entrée"
fi

# surveillance de squid :

# les deux sources définies good et overload permettent d'afficher le traffic de sortie http
# en deux couleurs (bleu ou rouge), selon qu'on est en surcharge ou non

# requetes clients/serveurs

rrdtool graph pic-sem-squid-req.gif \
--start -604800 --title "Requêtes sur le cache squid" \
--vertical-label "Requêtes/s" --width 350 --height 150 --upper-limit $lim_req \
DEF:serveur=squid_request.rrd:serveur:AVERAGE \
DEF:client=squid_request.rrd:client:AVERAGE \
AREA:client#0000FF:"clients (demandes)" \
LINE2:serveur#FF0000:"serveurs (réponses hors cache)"


# traffic HTTP moyen

rrdtool graph pic-sem-squid-http.gif \
--start -604800 --title "Traffic HTTP sur le cache squid" \
--vertical-label "octets/s" --width 350 --height 150 --upper-limit $lim_octets \
DEF:inoctets=squid_http.rrd:input:AVERAGE \
DEF:outoctets=squid_http.rrd:output:AVERAGE \
CDEF:ink=inoctets,1000,* \
CDEF:outk=outoctets,1000,* \
AREA:outk#0000FF:"Sortie" \
LINE2:ink#00FF00:"Entrée"


# efficacité du cache (hits/requests)

rrdtool graph pic-sem-squid-ratio.gif \
--start -604800 --title "Hit ratio" \
--vertical-label "%" --width 350 --height 150 --upper-limit $lim_pourcent \
DEF:hits=squid_ratio.rrd:hits-ratio:AVERAGE \
DEF:bytes=squid_ratio.rrd:bytes-ratio:AVERAGE \
AREA:hits#FF0000:"hits-ratio" \
LINE2:bytes#0000FF:"bytes-ratio" \

chown www-data.www-data pic*.gif
cp pic*.gif $REP_IMG_RRD
