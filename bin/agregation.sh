#!/bin/bash
##############################
# Script Agregation de lien  #
# Gabriel CORGNE (Ac-Nantes) #
##############################

[ -e /etc/agregation.conf ] || {
    # Pas de fichier de configuration
    echo "Fichier de configuration /etc/qoseole.conf  non trouve"
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
#Nombre de serveurs DNS a tester
ID1_C=${#DNS1[@]}
ID2_C=${#DNS2[@]}
#Nombre de mires a tester
IM_C=${#MIRE[@]}
# Chargement de la bibliothèque Eole
[ -x /usr/share/eole/FonctionsEole ] || {
        echo "Pas de bibliotheque Eole !"
        exit 1
}
. /usr/share/eole/FonctionsEole

# Déclaration des tables
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

# Chargement des règles de routage
/sbin/ip route del default

/sbin/ip rule del from $WAN1 table T1
/sbin/ip rule add from $WAN1 table T1
/sbin/ip route add $NET1 dev eth0 src $WAN1 table T1
/sbin/ip route add default via $GW1 table T1

/sbin/ip rule del from $WAN2 table T2
/sbin/ip rule add from $WAN2 table T2
/sbin/ip route add $NET2 dev eth0 src $WAN2 table T2
/sbin/ip route add default via $GW2 table T2

for ip_force1 in ${FORCE1[@]}; do /sbin/ip route add $ip_force1 via $GW1 table main ; done
for ip_force2 in ${FORCE2[@]}; do /sbin/ip route add $ip_force2 via $GW2 table main ; done

for ip_dns1 in ${DNS1[@]}; do /sbin/ip route add $ip_dns1 via $GW1 table main ; done
for ip_dns2 in ${DNS2[@]}; do /sbin/ip route add $ip_dns2 via $GW2 table main ; done

/sbin/ip route add default scope global nexthop via $GW1 dev eth0 weight $W1 nexthop via $GW2 dev eth0 weight $W2

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
			[ $(eval echo \$LLS$L) -eq 0 ] && Zecho "Erreur de resolution de $(eval echo \${MIRE[$IM]}) sur le dns $(eval echo \${DNS$L[$ID]}) du lien $L"
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
		Zecho "L'etat du lien $L a change de $(eval echo \$LHS$L) a $(eval echo \$CHS$L)"
		eval COUNT$L=1
	else
		if [ $(eval echo \$LHS$L) -ne $(eval echo \$LLS$L) ]; then
			eval COUNT$L=$(( $(eval echo \$COUNT$L) + 1 ))
		fi
	fi
	if [[ $(eval echo \$COUNT$L) -ge $NBSUCCES || ($(eval echo \$LLS$L) -eq 0 && $(eval echo \$COUNT$L) -ge $NBECHECS) ]]; then
		Zecho "L'etat du lien $L va changer de $(eval echo \$LLS$L)"
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



while : ; do
	Checkstate 1
	Checkstate 2

	if [[ $CLS1 -eq 0 || $CLS2 -eq 0 ]]; then
		if [[ $LLS1 -eq 1 && $LLS2 -eq 0 ]]; then 
			Zecho "Passage sur le lien 2"
			/sbin/ip route replace default scope global via $GW2 dev eth0
		elif [[ $LLS1 -eq 0 && $LLS2 -eq 1 ]]; then
			Zecho "Passage sur le lien 1"
			/sbin/ip route replace default scope global via $GW1 dev eth0
		elif [[ $LLS1 -eq 0 && $LLS2 -eq 0 ]]; then
			Zecho "Rechargement de la repartition sur les 2 liens"
            /sbin/ip route replace default scope global nexthop via $GW1 dev eth0 weight $W1 nexthop via $GW2 dev eth0 weight $W2
		fi
	fi
        if [ $PAUSE -le 5 ];then
			sleep 5
		else
			sleep $PAUSE
		fi
done