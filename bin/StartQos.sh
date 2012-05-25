#!/bin/bash
#
#---------------------------------------------------
# Active la qualité de service sur AMON 2.3
#
# Version  1
# EOLE  Dijon 09-2006
# MAJ 05-2012 (#3529)
#---------------------------------------------------
# Attention cette version de  script réinialise les tables mangle.
# Si votre parefeu fait aussi un marquage de paquets des adaptations
# sont à faire.
#---------------------------------------------------
# VARIABLES DE CONFIGURATION

#  Ces variables sont à renseigner dans le  fichier /etc/qoseole.conf
# NB_Inter=3 # Nombre de cartes sur lesquelles on applique la qos
# DEBITS en kbits (mettre un peu en dessous des débits réels)
# DOWN=1000 # Traffic entrant = Flux descendant (download)
# UP=100    # Traffic sortant = Flux montant    (upload)
# TAUX (%) #
# Attention: le cumul des taux < = 100% ! #
# TX_INT_0=50
# TX_INT_1=25
# TX_INT_2=25
# TX_INT_X=XX #

# Ces variables peuvent être modifiées
# INTERFACES #
NET=eth0   # interface externe
INT_0=eth0 # reseau 1
INT_1=eth1 # reseau 2
INT_2=eth2 # reseau 3
INT_3=eth3 # reseau 3
# On  prend en compte tous le réseau classe C
Netmask_INT_0=24
Netmask_INT_1=24
Netmask_INT_2=24
Netmask_INT_3=24
# INT_X=ethX # sous réseau X
# Netmask_INT_X=X # Netmask

#---------------------------------------------------

# Variables internes
IPTABLES=/sbin/iptables
#IPTABLES=echo
TC=/sbin/tc
#TC=echo

[ -e /etc/qoseole.conf ] || {
    # Pas de fichier de configuration
    echo "Fichier de configuration /etc/qoseole.conf  non trouvé"
    exit 1
    }

. /etc/qoseole.conf

# Format entier
declare -i I J Max NB_Inter

#[ -x /usr/share/eole/FonctionsEole ] || {
#
#       echo "Pas de bibliotheque Eole"
#  #     exit 1
#}
#
#. /usr/share/eole/FonctionsEole
. ParseDico




### Vidage table mangle ###
## Plus utilise car mangle gere au niveau d'era
#$IPTABLES -t mangle -F

### Marquage des paquets      ###
### sur l'interface d'origine ###
Max=$NB_Inter-1
I=0
while [ $I -le $Max ]
do
Inter=INT_$I
$IPTABLES -t mangle -A FORWARD -i ${!Inter}  -j MARK --set-mark  $[$I+1]
I=$I+1
done



### Suppression des listes d'attente ###
$TC qdisc del dev $NET root 2>&1 >/dev/null
$TC qdisc del dev $NET ingress 2>&1 >/dev/null


echo Mise en place Q.O.S
echo "Bande passante disponible"
echo Flux Montant $UP kbit en sortie
echo Flux Descendant  $DOWN kbit en entrée
echo
echo "Répartition : "


###### Flux descendant ######

$TC qdisc add dev $NET handle ffff: ingress

Max=$NB_Inter-1
I=0
while [ $I -le $Max ]
do
Inter=INT_$I
Ip=adresse_ip_eth$I
NetMask=Netmask_INT_$I
echo Interface  ${!Inter} ${!Ip} ${!NetMask} taux=$[TX_INT_$I]%  $[$[TX_INT_$I]*$DOWN/100]kbit en sortie $[$[TX_INT_$I]*$UP/100]kbit en entrée
$TC filter add dev $NET parent ffff: protocol ip prio 1 u32 match ip dst ${!Ip}/${!NetMask}  police rate $[$[TX_INT_$I]*$DOWN/100]kbit burst $[$DOWN/30]k drop flowid :1
I=$I+1
done
# $TC filter add dev $NET parent ffff: protocol ip prio 1 u32 match ip dst X.X.X.X/X \
#    police rate $[TX_INT_X*$DOWN/100]kbit burst $[$DOWN/30]k drop flowid :1
# police rate $[TX_INT_X*$DOWN/100]kbit burst $[$DOWN/30]k drop flowid :1

### Flux prioritaires (ICMP + SSH/TELNET...) ###
$TC filter add dev $NET parent ffff: protocol ip prio 1 u32 match ip protocol 1 0xff flowid :1
$TC filter add dev $NET parent ffff: protocol ip prio 1 u32 match ip tos 0x10 0xff flowid :1

###### Flux montant ######

$TC qdisc add dev $NET root handle 1: htb default 11

$TC class add dev $NET parent 1: classid 1:1 htb rate ${UP}kbit ceil ${UP}kbit

Max=$NB_Inter-1
I=0
while [ $I -le $Max ]
do
Inter=INT_$I
$TC class add dev $NET parent 1:1 classid 1:$[$I+11] htb rate $[$[TX_INT_$I]*$UP/100]kbit ceil ${UP}kbit
$TC filter add dev $NET parent 1: protocol ip handle 1 fw flowid  1:$[$I+11]  #
$TC qdisc add dev $NET parent 1:$[$I+11] sfq perturb 10
I=$I+1
done
# $TC class add dev $NET parent 1:1 classid 1:1X htb rate $[$TX_INT_X*$UP/100]kbit ceil ${UP}kbit
# handle X = marquage sur l'interface INT_X
# $TC filter add dev $NET parent 1: protocol ip handle X fw flowid 1:1X # INT_X
# $TC qdisc add dev $NET parent 1:1X sfq perturb 10

### Flux prioritaires (ICMP + SSH/TELNET...) ###
$TC filter add dev $NET parent 1: protocol ip u32 match ip protocol 1 0xff flowid 1:1
$TC filter add dev $NET parent 1: protocol ip u32 match ip tos 0x10 0xff flowid 1:1

exit 0
