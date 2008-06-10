#!/bin/bash
#
#---------------------------------------------------
# Status QOS  AMON 1.5
# Version 1.0
# EOLE  Dijon 09-2006
# $Id:  
#---------------------------------------------------
# option -s pour voir les statistiques
#---------------------------------------------------

#[ -x /usr/share/eole/FonctionsEole ] || {
#       echo "Pas de bibliotheque Eole"
#       exit 1
#}

#. /usr/share/eole/FonctionsEole
#ParseDico

TC=/sbin/tc
for eth in $(netstat -i | grep ^eth | awk {'print $1'})
do
echo "$eth:"
$TC $1 qdisc show dev $eth
$TC $1 class show dev $eth
$TC $1 filter show dev $eth
done
					  
