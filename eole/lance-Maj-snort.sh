#!/bin/bash

############################################################
#
## Appel du script de MAJ des régles de snort depuis la crontab
#
## Equipe Eole eole@ac-dijon.fr, septembre 2005
#
############################################################

## Tirage aléatoire de l'heure de Maj des blacklists
HMAJ=$[( $RANDOM % 5) +1]
MMAJ=$[( $RANDOM % 60) +1]

## suppression des tâches redondantes
for i in `grep "oinkmaster" /var/spool/cron/atjobs/* | awk -F: '{print $1}'`  
do
       	rm -f $i  
done

## appel différé grâce à la commande "at" 
echo "/usr/sbin/oinkmaster -o /etc/snort/rules >/dev/null 2>&1" | /usr/bin/at $HMAJ:$MMAJ

