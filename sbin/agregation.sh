#!/bin/bash
##############################
# Script Agregation de lien  #
# Gabriel CORGNE             #
##############################

# Ajout marquage de packet pour SNAT
# ac-creteil.fr Olivier Sauzet - Rachid Bouhassoun
# le 10 Juin 2009

[ -e /etc/agregation.conf ] || {
    # Pas de fichier de configuration
    echo "Fichier de configuration /etc/agregation.conf non trouvé"
    exit 1
}
. /etc/agregation.conf
# Chargement de la bibliotheque Eole
[ -x /usr/share/eole/FonctionsEoleNg ] || {
        echo "Pas de bibliotheque Eole !"
        exit 1
}
. /usr/share/eole/FonctionsEoleNg
#Chargement des dicos
. ParseDico
#

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
# Le lien doit changer (O:oui , 1:non)
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
if [ -n "$W1" -a -n "$W2" ];then
WCO=$[$[$W2*1000]/$[$W1+$W2]]
fi

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
    if [ -z "$2" ];then
        level="ERR"
    else
        level=$2
    fi
    DATE=`date +%Y-%m-%d_%H:%M:%S`
    echo "$DATE $1" >> /var/log/agregation.log
    [ "$level" != 'ERR' ] && echo "$1"
    Zephir "$level" "$1" agregation
}

#Mise à jour des routes $1=T1
ipruleclear () {
    for r in `ip rule list|grep $1|awk '{print $2"-"$3"-"$4"-"$5"-"$6"-"$7}'`
        do ip rule del `echo $r|sed "s/-/ /g"`
    done
}

#Vidage des règles iptables de SNAT
iptablessnatclear () {
	i=1
	while [ $i -le `/sbin/iptables -t nat -S POSTROUTING|wc -l` ]
	do
		if [ -n "`/sbin/iptables -t nat -S POSTROUTING $i|grep SNAT|grep "o eth0"`" ];then
			/sbin/iptables -t nat -D POSTROUTING $i
		else
			let i++
		fi
	done
}

#Vidage des règles iptables de MANGLE $1 = nom de la carte
iptablesmangleclear () {
	i=1
	while [ "$i" -le `/sbin/iptables -t mangle -S PREROUTING|wc -l` ]
	do
		if [ -n "`/sbin/iptables -t mangle -S PREROUTING $i|grep "i $1"`" ];then
			/sbin/iptables -t mangle -D PREROUTING $i
		else
			let i++
		fi
	done
}

#Definition de la repartition par interface $1 = nom de la carte
balance () {
	iptablesmangleclear $1
	network="$(eval echo \$adresse_network_$1)/$(eval echo \$adresse_netmask_$1)"
	#Si non NEW
	/sbin/iptables -t mangle -A PREROUTING -i $1 -s $network -m state ! --state NEW -j RESTOREMARK
	/sbin/iptables -t mangle -A PREROUTING -i $1 -s $network -m state ! --state NEW -j RETURN
	#Routes forcees
	for ip_force1 in ${FORCE1[@]}; do
		/sbin/iptables -t mangle -A PREROUTING -i $1 -s $network -d $ip_force1 -m state --state NEW -j T1
		/sbin/iptables -t mangle -A PREROUTING -i $1 -s $network -d $ip_force1 -m state --state NEW -j RETURN ; done
	for ip_force2 in ${FORCE2[@]}; do
		/sbin/iptables -t mangle -A PREROUTING -i $1 -s $network -d $ip_force2 -m state --state NEW -j T2
		/sbin/iptables -t mangle -A PREROUTING -i $1 -s $network -d $ip_force2 -m state --state NEW -j RETURN ; done
	#Si NEW et recent alors Tag puis RETURN
	/sbin/iptables -t mangle -A PREROUTING -i $1 -s $network -m state --state NEW -m recent --name T1 --update --rdest --seconds 3600 -j T1
	/sbin/iptables -t mangle -A PREROUTING -i $1 -s $network -m state --state NEW -m recent --name T1 --update --rdest --seconds 3600 -j RETURN
	/sbin/iptables -t mangle -A PREROUTING -i $1 -s $network -m state --state NEW -m recent --name T2 --update --rdest --seconds 3600 -j T2
	/sbin/iptables -t mangle -A PREROUTING -i $1 -s $network -m state --state NEW -m recent --name T2 --update --rdest --seconds 3600 -j RETURN
	#Si NEW sans recent alors Tag puis RETURN
	/sbin/iptables -t mangle -A PREROUTING -i $1 -s $network -m state --state NEW -j T2
	/sbin/iptables -t mangle -A PREROUTING -i $1 -s $network -m state --state NEW -m statistic --mode random --probability 0.$WCO -m recent --name T2 --set --rdest -j RETURN
	/sbin/iptables -t mangle -A PREROUTING -i $1 -s $network -m state --state NEW -m recent --name T1 --set --rdest -j T1
}
#Definition du flux par interface $1 = nom de la carte
wan1 () {
	iptablesmangleclear $1
	network="$(eval echo \$adresse_network_$1)/$(eval echo \$adresse_netmask_$1)"
	#Si non NEW
	/sbin/iptables -t mangle -A PREROUTING -i $1 -s $network -m state ! --state NEW -j RESTOREMARK
	/sbin/iptables -t mangle -A PREROUTING -i $1 -s $network -m state ! --state NEW -j RETURN
	#Marques sur T1
	/sbin/iptables -t mangle -A PREROUTING -i $1 -s $network -m state --state NEW -j T1
}
#Definition du flux par interface $1 = nom de la carte
wan2 () {
	iptablesmangleclear $1
	network="$(eval echo \$adresse_network_$1)/$(eval echo \$adresse_netmask_$1)"
	#Si non NEW
	/sbin/iptables -t mangle -A PREROUTING -i $1 -s $network -m state ! --state NEW -j RESTOREMARK
	/sbin/iptables -t mangle -A PREROUTING -i $1 -s $network -m state ! --state NEW -j RETURN
	#Marques sur T2
	/sbin/iptables -t mangle -A PREROUTING -i $1 -s $network -m state --state NEW -j T2
}
## Initialisation
# Large recent table
/sbin/modprobe ipt_recent ip_list_tot=4000
# Declaration des tables iproute2
cat > /etc/iproute2/rt_tables <<Eof
# reserved values
255	local
254	main
253	default
0	unspec
# local
2 T2
1 T1
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

####################
# test mode load balancing ou fail-over (actif/passif)
if [ $ag_mode == "mode_lb" ] ; then
	/sbin/ip route delete default via $GW1 dev eth0
	/sbin/ip route delete default via $GW2 dev eth0
	/sbin/ip route add default scope global nexthop via $GW1 dev eth0 weight $W1 nexthop via $GW2 dev eth0 weight $W2
fi

if [ $ag_mode == "mode_fo" ] ;then
    if [ $ag_fo_etat_eth0 == "actif" ] && [ $ag_fo_etat_eth0_0 == "passif" ] ; then
        /sbin/ip route delete default
        /sbin/ip route add default via $GW1 dev eth0
    elif [ $ag_fo_etat_eth0 == "passif" ] && [ $ag_fo_etat_eth0_0 == "actif" ] ; then
        /sbin/ip route delete default
        /sbin/ip route add default via $GW2 dev eth0
    fi
fi
####################

# Vidage des chaines MANGLE
check_T1=$(iptables-save |grep "RESTOREMARK" |wc -l)
check_T2=$(iptables-save |grep "T2" | wc -l)
check_RESTOREMARK=$(iptables-save |grep "T1" |wc -l)
check_PREROUTING=$(iptables-save |grep "T1" |wc -l)
if [ "$check_PREROUTING" -gt "1" ] ; then
/sbin/iptables -t mangle -F PREROUTING
fi
if [ "$check_T1" -gt "1" ] ; then
/sbin/iptables -t mangle -F T1
fi
if [ "$check_T2" -gt "1" ] ; then
/sbin/iptables -t mangle -F T2
fi
if [ "$check_RESTOREMARK" -gt "1" ] ; then
/sbin/iptables -t mangle -F RESTOREMARK
fi

## creation de la chaine marquage pour agregation de lien
chaine_T1=$(iptables-save | grep ":T1")
if [ -z "$chaine_T1" ] ; then
/sbin/iptables -t mangle -N T1
/sbin/iptables -t mangle -A T1 -d 10.0.0.0/8 -j RETURN
/sbin/iptables -t mangle -A T1 -d 172.16.0.0/12 -j RETURN
/sbin/iptables -t mangle -A T1 -d 192.168.0.0/16 -j RETURN
/sbin/iptables -t mangle -A T1 -d 161.48.0.0/19 -j RETURN
/sbin/iptables -t mangle -A T1 -j MARK --set-mark 1
/sbin/iptables -t mangle -A T1 -j CONNMARK --save-mark
fi
chaine_T2=$(iptables-save | grep ":T2")
if [ -z "$chaine_T1" ] ; then
/sbin/iptables -t mangle -N T2
/sbin/iptables -t mangle -A T2 -d 10.0.0.0/8 -j RETURN
/sbin/iptables -t mangle -A T2 -d 172.16.0.0/12 -j RETURN
/sbin/iptables -t mangle -A T2 -d 192.168.0.0/16 -j RETURN
/sbin/iptables -t mangle -A T2 -d 161.48.0.0/19 -j RETURN
/sbin/iptables -t mangle -A T2 -j MARK --set-mark 2
/sbin/iptables -t mangle -A T2 -j CONNMARK --save-mark
fi
chaine_RESTOREMARK=$(iptables-save | grep ":RESTOREMARK")
if [ -z "$chaine_RESTOREMARK" ] ; then
/sbin/iptables -t mangle -N RESTOREMARK
/sbin/iptables -t mangle -A RESTOREMARK -d 10.0.0.0/8 -j RETURN
/sbin/iptables -t mangle -A RESTOREMARK -d 172.16.0.0/12 -j RETURN
/sbin/iptables -t mangle -A RESTOREMARK -d 192.168.0.0/16 -j RETURN
/sbin/iptables -t mangle -A RESTOREMARK -d 161.48.0.0/19 -j RETURN
/sbin/iptables -t mangle -A RESTOREMARK -j CONNMARK --restore-mark
fi

## Mise a jour des règles de SNAT
iptablessnatclear
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
	while [ "$ID" -lt $(eval echo \$ID$L\_C) ] && [ $SUCCES -eq 1 ] ; do
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
		Aecho "Le lien $L est tombe"
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
		if [ $(eval echo \$LLS$L) -eq "1" ]; then
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
Aecho "Initialisation de l'agregation de liens" 'MSG'

while : ; do
	Checkstate 1
	Checkstate 2

    if [[ $CLS1 -eq 0 || $CLS2 -eq 0 ]]; then

        if [[ $LLS1 -eq 1 && $LLS2 -eq 0 ]]; then

			Aecho "Seul le lien 2 est actif, redirection des flux sur ce lien"

            if [ "$ag_active_mail" == "oui" ] ; then
				MssG="Seul le lien 2 est actif, redirection des flux sur ce lien"
				SubJ="Liaison $nom_domaine_local_supp  ($numero_etab)"
                if [ -z "${CC[@]}" ] ; then
                    echo "$MssG"|mutt -s "$SubJ" "$DEST"
                else
                    echo "$MssG"|mutt -s "$SubJ" "$DEST" -c "${CC[@]}"
                fi
	        fi

                # Iproute2 sur le lien2
	                /sbin/ip route replace default via $GW2 dev eth0
				# bascule des destinations forcées (lien 1) sur le lien 2
				for ip_force in ${FORCE1[@]} ; do
					/sbin/ip route replace $ip_force via $GW2 dev eth0
				done
				# Mangle sur le lien2
	                        wan2 eth1
	                        [ $nombre_interfaces -ge 3 ] && wan2 eth2
	                        [ $nombre_interfaces -ge 4 ] && wan2 eth3
	                        [ $nombre_interfaces -eq 5 ] && wan2 eth4

        elif [[ $LLS1 -eq 0 && $LLS2 -eq 1 ]]; then
            Aecho "Seul le lien 1 est actif, redirection des flux sur ce lien"

            if [ "$ag_active_mail" == "oui" ] ; then
				MssG="Seul le lien 1 est actif, redirection des flux sur ce lien"
				SubJ="Liaison $nom_domaine_local_supp  ($numero_etab)"
                if [ -z "${CC[@]}" ] ; then
                    echo "$MssG"|mutt -s "$SubJ" "$DEST"
                else
                    echo "$MssG"|mutt -s "$SubJ" "$DEST" -c "${CC[@]}"
                fi
            fi

                # Iproute2 sur le lien1
	                /sbin/ip route replace default via $GW1 dev eth0
				# bascule des destinations forcées (lien 2) sur le lien 1
				for ip_force in ${FORCE2[@]} ; do
					/sbin/ip route replace $ip_force via $GW1 dev eth0
				done

			        # Mangle sur lien1
                    wan1 eth1
                    [ $nombre_interfaces -ge 3 ] && wan1 eth2
                    [ $nombre_interfaces -ge 4 ] && wan1 eth3
                    [ $nombre_interfaces -eq 5 ] && wan1 eth4

        elif [[ $LLS1 -eq 0 && $LLS2 -eq 0 ]]; then
			Aecho "Rechargement de la repartition sur les 2 liens" 'MSG'

            if [ "$ag_active_mail" == "oui" ] ; then
				MssG="Rechargement de la repartition sur les 2 liens"
				SubJ="Liaison $nom_domaine_local_supp  ($numero_etab)"
                if [ -z "${CC[@]}" ] ; then
                    echo "$MssG"|mutt -s "$SubJ" "$DEST"
                else
                    echo "$MssG"|mutt -s "$SubJ" "$DEST" -c "${CC[@]}"
                fi
	        fi

			# Iproute si mode load balancing
            if [ $ag_mode == "mode_lb" ] ; then
    	    	# Iproute2 sur les 2 liens
	    	    /sbin/ip route replace default proto static nexthop via $GW1 dev eth0 weight $W1 nexthop via $GW2 dev eth0 weight $W2

                # retablit les destination forcees lien 1
	            for ip_force in ${FORCE1[@]} ; do
                    /sbin/ip route replace $ip_force via $GW1 dev eth0
                done
                # retablit les destination forcees lien 2
	            for ip_force in ${FORCE2[@]} ; do
                    /sbin/ip route replace $ip_force via $GW2 dev eth0
                done

                # Mangle sur les 2 liens
	            balance eth1
	            [ $nombre_interfaces -ge 3 ] && balance eth2
	            [ $nombre_interfaces -ge 4 ] && wan2 eth3
    	        [ $nombre_interfaces -eq 5 ] && wan2 eth4
			else
                #mode fail-over
                # retablit les destination forcees lien 1
	            for ip_force in ${FORCE1[@]} ; do
                    /sbin/ip route replace $ip_force via $GW1 dev eth0
                done
                # retablit les destination forcees lien 2
	            for ip_force in ${FORCE2[@]} ; do
                    /sbin/ip route replace $ip_force via $GW2 dev eth0
                done
                if [ $ag_fo_etat_eth0 == "actif" ] && [ $ag_fo_etat_eth0_0 == "passif" ] ; then
                    /sbin/ip route replace default via $GW1 dev eth0
                elif [ $ag_fo_etat_eth0 == "passif" ] && [ $ag_fo_etat_eth0_0 == "actif" ] ; then
                    /sbin/ip route replace default via $GW2 dev eth0
                fi

	    		# Mangle sur les 2 liens
	            balance eth1
	            [ $nombre_interfaces -ge 3 ] && balance eth2
	            [ $nombre_interfaces -ge 4 ] && wan2 eth3
	            [ $nombre_interfaces -eq 5 ] && wan2 eth4
			fi

		fi
		# rechargement des tunnels, plus utile en 2.3
		#/usr/share/eole/magic-rvp &
	fi

    if [ $PAUSE -le 5 ];then
		sleep 5
	else
		sleep $PAUSE
	fi
done
