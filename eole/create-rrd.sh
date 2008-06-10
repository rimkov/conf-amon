#!/bin/bash
###########################################################################
# Eole NG - 2007
# Copyright Pole de Competence Eole  (Ministere Education - Academie Dijon)
# Licence CeCill  cf /root/LicenceEole.txt
# eole@ac-dijon.fr
#
# create-rrd.sh
#
# Initialisation des bases RRD pour l'EAD
#
###########################################################################


echo "Initialisation des bases RRD"

ParseDico

# On vérifie le nombre de carte réseaux (3 ou 4) de la machine
nb_interface=`cat /proc/net/dev | grep eth | wc -l | tr -d  " "`

REP_BAS_RRD=/usr/share/ead/rrd
REP_WWW_RRD=/var/www/ead/stats/rrd

# **********************************************************
# Mise en place des pages de consultation des statistiques
# des interfaces réseau
# **********************************************************

# en fonction du type d'amon (3 ou 4 zones), on recopie les pages correspondantes

if  [ "$nb_interface" == "3" ]
then 
	cp $REP_WWW_RRD/3interf.php $REP_WWW_RRD/interf.php
	cp $REP_WWW_RRD/3interf_sem.php $REP_WWW_RRD/interf_sem.php
else
	cp $REP_WWW_RRD/4interf.php $REP_WWW_RRD/interf.php
	cp $REP_WWW_RRD/4interf_sem.php $REP_WWW_RRD/interf_sem.php
fi

# création du répertoire des images de statistiques

# ************************************************
# création des bases de données des statistiques
# par bruno boiget (CETIAD)
# ************************************************

# création des bases communes à tous les types d'amon :
#  eth0, eth1, eth2 et squid 


if [ ! -d $REP_BAS_RRD ] 
then
	mkdir $REP_BAS_RRD
fi

cd "$REP_BAS_RRD"


if [ ! -f $REP_BAS_RRD/eth0.rrd ] 
then

rrdtool create eth0.rrd         \
	DS:input:COUNTER:600:0:U   \
	DS:output:COUNTER:600:0:U  \
	RRA:AVERAGE:0.5:1:600      \
	RRA:AVERAGE:0.5:6:700      \
	RRA:AVERAGE:0.5:24:775     \
	RRA:AVERAGE:0.5:288:380    \
	RRA:MAX:0.5:1:600          \
	RRA:MAX:0.5:6:700          \
	RRA:MAX:0.5:24:775         \
	RRA:MAX:0.5:288:380

fi
if [ ! -f $REP_BAS_RRD/eth1.rrd ] 
then

rrdtool create eth1.rrd         \
	DS:input:COUNTER:600:0:U   \
	DS:output:COUNTER:600:0:U  \
	RRA:AVERAGE:0.5:1:600      \
	RRA:AVERAGE:0.5:6:700      \
	RRA:AVERAGE:0.5:24:775     \
	RRA:AVERAGE:0.5:288:380    \
	RRA:MAX:0.5:1:600          \
	RRA:MAX:0.5:6:700          \
	RRA:MAX:0.5:24:775         \
	RRA:MAX:0.5:288:380
fi
if [ ! -f $REP_BAS_RRD/eth2.rrd ] 
then

rrdtool create eth2.rrd         \
	DS:input:COUNTER:600:0:U   \
	DS:output:COUNTER:600:0:U  \
	RRA:AVERAGE:0.5:1:600      \
	RRA:AVERAGE:0.5:6:700      \
	RRA:AVERAGE:0.5:24:775     \
	RRA:AVERAGE:0.5:288:380    \
	RRA:MAX:0.5:1:600          \
	RRA:MAX:0.5:6:700          \
	RRA:MAX:0.5:24:775         \
	RRA:MAX:0.5:288:380
fi

# création de bases supplémentaires si nécessaire

if [ "$nb_interface" != "3" ]
then

	if [ ! -f $REP_BAS_RRD/eth3.rrd ] 
	then
	rrdtool create eth3.rrd	\
		DS:input:COUNTER:600:0:U   \
		DS:output:COUNTER:600:0:U  \
		RRA:AVERAGE:0.5:1:600      \
		RRA:AVERAGE:0.5:6:700      \
		RRA:AVERAGE:0.5:24:775     \
		RRA:AVERAGE:0.5:288:380    \
		RRA:MAX:0.5:1:600          \
		RRA:MAX:0.5:6:700          \
		RRA:MAX:0.5:24:775         \
		RRA:MAX:0.5:288:380
											
	fi
fi

# création de la base de surveillance du cache de squid

if [ ! -f $REP_BAS_RRD/squid_request.rrd ] 
then

# base des requêtes serveurs / clients

        rrdtool create squid_request.rrd \
	DS:serveur:COUNTER:600:0:U \
	DS:client:COUNTER:600:0:U \
	RRA:AVERAGE:0.5:1:600 \
	RRA:AVERAGE:0.5:6:700 \
	RRA:AVERAGE:0.5:24:775 \
	RRA:AVERAGE:0.5:288:380 \
	RRA:MAX:0.5:1:600 \
	RRA:MAX:0.5:6:700 \
	RRA:MAX:0.5:24:775 \
	RRA:MAX:0.5:288:380

# base des entrees/sorties HTTP

	rrdtool create squid_http.rrd \
	DS:input:COUNTER:600:0:U \
	DS:output:COUNTER:600:0:U \
        RRA:AVERAGE:0.5:1:600 \
	RRA:AVERAGE:0.5:6:700 \
	RRA:AVERAGE:0.5:24:775 \
	RRA:AVERAGE:0.5:288:380 \
	RRA:MAX:0.5:1:600 \
	RRA:MAX:0.5:6:700 \
	RRA:MAX:0.5:24:775 \
	RRA:MAX:0.5:288:380

# base de hit-ratio/byte-ratio
	
	rrdtool create squid_ratio.rrd \
	DS:hits-ratio:GAUGE:600:0:99 \
	DS:bytes-ratio:GAUGE:600:0:99 \
	RRA:AVERAGE:0.5:1:600 \
	RRA:AVERAGE:0.5:6:700 \
	RRA:AVERAGE:0.5:24:775 \
	RRA:AVERAGE:0.5:288:380 \
	RRA:MAX:0.5:1:600 \
	RRA:MAX:0.5:6:700 \
	RRA:MAX:0.5:24:775 \
	RRA:MAX:0.5:288:380

fi
