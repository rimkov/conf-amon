#!/bin/bash
##############################
# Script Agregation de lien  #
# Gabriel CORGNE (Ac-Nantes) #
##############################

# Ajout marquage de packet pour SNAT
# ac-creteil.fr Olivier Sauzet - Rachid Bouhassoun
# le 10 Juin 2009

[ -e /etc/agregation.conf ] || {
    # Pas de fichier de configuration
    echo "Fichier de configuration /etc/agregation.conf  non trouve"
    exit 1
}
. /etc/agregation.conf

#Initialisation des variables d'etat
# Dernier etat du lien
LLS1=1
LLS2=1
# Dernier etat du host
LHS1=1
LHS2=1
# Etat actuel du host
CHS1=1
CHS2=1
# Le lien doit changer
CLS1=1
CLS2=1
# Nombre de changement d'etat
COUNT1=0
COUNT2=0
# Nombre de serveurs DNS a tester
ID1_C=${#DNS1[@]}
ID2_C=${#DNS2[@]}
# Nombre de mires a tester
IM_C=${#MIRE[@]}
# Calcul du coefficient pour iptables
WCO=$[$[$W2*1000]/$[$W1+$W2]]

# Chargement de la bibliotheque Eole
[ -x /usr/share/eole/FonctionsEole ] || {
        echo "Pas de bibliotheque Eole !"
        exit 1
}
. /usr/share/eole/FonctionsEole

echo "Initialisation de l'agregation de liens"

# Fonction explicitant les messages d'etat
expl() {
	if [ $1 -eq 0 ];then
		echo "actif"
    else
        echo "inactif"
    fi
}

# Fonction de Log dans /var/log/agregation.log + Zephir
Aecho () {
	DATE=`date +%Y-%m-%d_%H:%M:%S`
	echo "$DATE $1" >> /var/log/agregation.log
	Zecho "$1"
}

#Mise à jour des routes $1=T1
ipruleclear () {
	for r in `ip rule list|grep $1|awk '{print $2"-"$3"-"$4"-"$5"-"$6"-"$7}'`
		do ip rule del `echo $r|sed "s/-/ /g"`
	done
}
		
# Declaration des tables iproute2
cat > /etc/iproute2/rt_tables <<Eof
# reserved values
255	local
254	main
253	default
0	unspec
# local
200 T2
201 T1
Eof

# Vidage du cache
/sbin/ip route flush cache

# Chargement des regles de routage
/sbin/ip route del default

ipruleclear T1
/sbin/ip rule add from $WAN1 table T1
/sbin/ip route add $NET1 dev eth0 src $WAN1 table T1
/sbin/ip route add default via $GW1 table T1
/sbin/ip rule add fwmark 1 table T1

ipruleclear T2
/sbin/ip rule add from $WAN2 table T2
/sbin/ip route add $NET2 dev eth0 src $WAN2 table T2
/sbin/ip route add default via $GW2 table T2
/sbin/ip rule add fwmark 2 table T2

for ip_force1 in ${FORCE1[@]}; do /sbin/ip route add $ip_force1 via $GW1 table main ; done
for ip_force2 in ${FORCE2[@]}; do /sbin/ip route add $ip_force2 via $GW2 table main ; done

for ip_dns1 in ${DNS1[@]}; do /sbin/ip route add $ip_dns1 via $GW1 table main ; done
for ip_dns2 in ${DNS2[@]}; do /sbin/ip route add $ip_dns2 via $GW2 table main ; done

/sbin/ip route add default scope global nexthop via $GW1 dev eth0 weight $W1 nexthop via $GW2 dev eth0 weight $W2
		
## creation de la chaine marquage pour agregation de lien
/sbin/iptables -t mangle -N CONNMARK1
/sbin/iptables -t mangle -A CONNMARK1 -d 10.0.0.0/8 -j RETURN
/sbin/iptables -t mangle -A CONNMARK1 -d 172.16.0.0/12 -j RETURN
/sbin/iptables -t mangle -A CONNMARK1 -d 192.168.0.0/16 -j RETURN
/sbin/iptables -t mangle -A CONNMARK1 -d 161.48.0.0/19 -j RETURN
/sbin/iptables -t mangle -A CONNMARK1 -j MARK --set-mark 1
/sbin/iptables -t mangle -A CONNMARK1 -j CONNMARK --save-mark

/sbin/iptables -t mangle -N CONNMARK2
/sbin/iptables -t mangle -A CONNMARK2 -d 10.0.0.0/8 -j RETURN
/sbin/iptables -t mangle -A CONNMARK2 -d 172.16.0.0/12 -j RETURN
/sbin/iptables -t mangle -A CONNMARK2 -d 192.168.0.0/16 -j RETURN
/sbin/iptables -t mangle -A CONNMARK2 -d 161.48.0.0/19 -j RETURN
/sbin/iptables -t mangle -A CONNMARK2 -j MARK --set-mark 2
/sbin/iptables -t mangle -A CONNMARK2 -j CONNMARK --save-mark

/sbin/iptables -t mangle -N RESTOREMARK
/sbin/iptables -t mangle -A RESTOREMARK -d 10.0.0.0/8 -j RETURN
/sbin/iptables -t mangle -A RESTOREMARK -d 172.16.0.0/12 -j RETURN
/sbin/iptables -t mangle -A RESTOREMARK -d 192.168.0.0/16 -j RETURN
/sbin/iptables -t mangle -A RESTOREMARK -d 161.48.0.0/19 -j RETURN
/sbin/iptables -t mangle -A RESTOREMARK -j CONNMARK --restore-mark

## Mise a jour des règles de SNAT
i=1
while [ $i -le `/sbin/iptables -t nat -S POSTROUTING|wc -l` ]
do
        if [ -n "`/sbin/iptables -t nat -S POSTROUTING $i|grep SNAT|grep "o eth0"`" ];then
                /sbin/iptables -t nat -D POSTROUTING $i
        else
                let i++
        fi
done
/sbin/iptables -t nat -A POSTROUTING -o eth0 -m mark --mark 1 -j SNAT --to-source $WAN1
/sbin/iptables -t nat -A POSTROUTING -o eth0 -m mark --mark 2 -j SNAT --to-source $WAN2


# Test vers $MIRE sur le lien $L
Checkstate () {

L=$1
#Nombre de serveurs DNS a tester
#ID_C=$(eval echo \${#DNS$L[@]})
ID=0
#Nombre de mires a tester
#IM_C=$(eval echo \${#MIRE$L[@]})
IM=0
SUCCES=1
while [ $IM -lt $IM_C ] && [ $SUCCES -eq 1 ] ; do
	while [ $ID -lt $(eval echo \$ID$L\_C) ] && [ $SUCCES -eq 1 ] ; do
		host -W $TIMEOUT ${MIRE[$IM]} $(eval echo \${DNS$L[$ID]})> /dev/null  2>&1
		if [ $? -ne 0 ]; then
			[ $(eval echo \$LLS$L) -eq 0 ] && Aecho "Erreur de resolution de $(eval echo \${MIRE[$IM]}) sur le dns $(eval echo \${DNS$L[$ID]}) du lien $L" 
			ID=$(( $ID + 1 ))
		else
			SUCCES=0
		fi
	done
	IM=$(( $IM + 1 ))
	ID=0
done		
		
	if [ $SUCCES -eq 1 ]; then
		Zecho "Le lien $L est tombe"
		eval CHS$L=1
	else
		eval CHS$L=0
	fi
	if [ $(eval echo \$LHS$L) -ne $(eval echo \$CHS$L) ]; then
		Aecho "L'etat du lien $L a change de $(expl $(eval echo \$LHS$L)) a $(expl $(eval echo \$CHS$L))"
		eval COUNT$L=1
	else
		if [ $(eval echo \$LHS$L) -ne $(eval echo \$LLS$L) ]; then
			eval COUNT$L=$(( $(eval echo \$COUNT$L) + 1 ))
		fi
	fi
	if [[ $(eval echo \$COUNT$L) -ge $NBSUCCES || ($(eval echo \$LLS$L) -eq 0 && $(eval echo \$COUNT$L) -ge $NBECHECS) ]]; then
		Aecho "Le lien $L n'est plus $(expl $(eval echo \$LLS$L))"
		eval CLS$L=0
		eval COUNT$L=0
		if [ $(eval echo \$LLS$L) -eq 1 ]; then
			eval LLS$L=0
		else
			eval LLS$L=1
		fi
	else 
		eval CLS$L=1
	fi

	eval LHS$L=$(eval echo \$CHS$L)
}


# Log du démarrage
Aecho "###### Script /usr/bin/agregation.sh START ######"

while : ; do
	Checkstate 1
	Checkstate 2

	if [[ $CLS1 -eq 0 || $CLS2 -eq 0 ]]; then
		if [[ $LLS1 -eq 1 && $LLS2 -eq 0 ]]; then 
			Aecho "Seul le lien 2 est actif, redirection des flux sur ce lien"
			# Iproute2 sur le lien2
			/sbin/ip route replace default scope global via $GW2 dev eth0
			# Mangle sur le lien2
			/sbin/iptables -t mangle -A PREROUTING -i eth1 -s %%adresse_network_eth1/%%adresse_netmask_eth1 -m state --state NEW -j CONNMARK2
%if %%nombre_interfaces >= "3"
			/sbin/iptables -t mangle -A PREROUTING -i eth2 -s %%adresse_network_eth2/%%adresse_netmask_eth2 -m state --state NEW -j CONNMARK2
%end if
%if %%nombre_interfaces >= "4"
			/sbin/iptables -t mangle -A PREROUTING -i eth3 -s %%adresse_network_eth3/%%adresse_netmask_eth3 -m state --state NEW -j CONNMARK2
%end if
%if %%nombre_interfaces == "5"
			/sbin/iptables -t mangle -A PREROUTING -i eth4 -s %%adresse_network_eth4/%%adresse_netmask_eth4 -m state --state NEW -j CONNMARK2
%end if
		elif [[ $LLS1 -eq 0 && $LLS2 -eq 1 ]]; then
			Aecho "Seul le lien 1 est actif, redirection des flux sur ce lien"
			# Iproute2 sur le lien1
			/sbin/ip route replace default scope global via $GW1 dev eth0
			# Mangle sur lien1
			/sbin/iptables -t mangle -A PREROUTING -i eth1 -s %%adresse_network_eth1/%%adresse_netmask_eth1 -m state --state NEW -j CONNMARK1
%if %%nombre_interfaces >= "3"
			/sbin/iptables -t mangle -A PREROUTING -i eth2 -s %%adresse_network_eth2/%%adresse_netmask_eth2 -m state --state NEW -j CONNMARK1
%end if
%if %%nombre_interfaces >= "4"
			/sbin/iptables -t mangle -A PREROUTING -i eth3 -s %%adresse_network_eth3/%%adresse_netmask_eth3 -m state --state NEW -j CONNMARK1
%end if
%if %%nombre_interfaces == "5"
			/sbin/iptables -t mangle -A PREROUTING -i eth4 -s %%adresse_network_eth4/%%adresse_netmask_eth4 -m state --state NEW -j CONNMARK1
%end if
			# rechargement des tunnels
			/usr/share/eole/magic-rvp &
		elif [[ $LLS1 -eq 0 && $LLS2 -eq 0 ]]; then
			Aecho "Rechargement de la repartition sur les 2 liens"
			# Iproute2 sur les 2 liens
			/sbin/ip route replace default scope global nexthop via $GW1 dev eth0 weight $W1 nexthop via $GW2 dev eth0 weight $W2
			# Mangle sur les 2 liens
			/sbin/iptables -t mangle -A PREROUTING -i eth1 -s %%adresse_network_eth1/%%adresse_netmask_eth1 -m state --state NEW -j CONNMARK1
			/sbin/iptables -t mangle -A PREROUTING -i eth1 -s %%adresse_network_eth1/%%adresse_netmask_eth1 -m state --state NEW -m statistic --mode random --probability 0.$WCO -j CONNMARK2
%if %%nombre_interfaces >= "3"
			/sbin/iptables -t mangle -A PREROUTING -i eth2 -s %%adresse_network_eth2/%%adresse_netmask_eth2 -m state --state NEW -j CONNMARK1
			/sbin/iptables -t mangle -A PREROUTING -i eth2 -s %%adresse_network_eth2/%%adresse_netmask_eth2 -m state --state NEW -m statistic --mode random --probability 0.$WCO -j CONNMARK2
%end if
%if %%nombre_interfaces >= "4"
			/sbin/iptables -t mangle -A PREROUTING -i eth3 -s %%adresse_network_eth3/%%adresse_netmask_eth3 -m state --state NEW -j CONNMARK1
			/sbin/iptables -t mangle -A PREROUTING -i eth3 -s %%adresse_network_eth3/%%adresse_netmask_eth3 -m state --state NEW -m statistic --mode random --probability 0.$WCO -j CONNMARK2
%end if
%if %%nombre_interfaces == "5"
			/sbin/iptables -t mangle -A PREROUTING -i eth4 -s %%adresse_network_eth4/%%adresse_netmask_eth4 -m state --state NEW -j CONNMARK1
			/sbin/iptables -t mangle -A PREROUTING -i eth4 -s %%adresse_network_eth4/%%adresse_netmask_eth4 -m state --state NEW -m statistic --mode random --probability 0.$WCO -j CONNMARK2
%end if
			# rechargement des tunnels
			/usr/share/eole/magic-rvp &
		fi
		# Restauration des marques
		/sbin/iptables -t mangle -A PREROUTING -i eth1 -s %%adresse_network_eth1/%%adresse_netmask_eth1 -j RESTOREMARK
%if %%nombre_interfaces >= "3"
		/sbin/iptables -t mangle -A PREROUTING -i eth2 -s %%adresse_network_eth2/%%adresse_netmask_eth2 -j RESTOREMARK
%end if
%if %%nombre_interfaces >= "4"
		/sbin/iptables -t mangle -A PREROUTING -i eth3 -s %%adresse_network_eth3/%%adresse_netmask_eth3 -j RESTOREMARK
%end if
%if %%nombre_interfaces == "5"
		/sbin/iptables -t mangle -A PREROUTING -i eth4 -s %%adresse_network_eth4/%%adresse_netmask_eth4 -j RESTOREMARK
%end if
	fi

    if [ $PAUSE -le 5 ];then
		sleep 5
	else
		sleep $PAUSE
	fi
done
