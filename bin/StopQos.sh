#!/bin/bash
#
#---------------------------------------------------
# Stop QOS  AMON 1.5
#
# Version  1
# EOLE  Dijon 09-2006
# $Id:  
#---------------------------------------------------

#[ -x /usr/share/eole/FonctionsEole ] || {
#       echo "Pas de bibliotheque Eole"
#       exit 1
#}

#. /usr/share/eole/FonctionsEole
#ParseDico


# Un peu rustique mais comme on ne sait pas ce qui a été fait
# On coupe tout sur toutes les interfaces!

TC=/sbin/tc
echo "Arret Qos sur toutes les interfaces"
for eth in $(netstat -i | grep ^eth | awk {'print $1'})
do
$TC qdisc del dev $eth root > /dev/null 2>&1
$TC qdisc del dev $eth ingress > /dev/null 2>&1
done
exit 0
					  
