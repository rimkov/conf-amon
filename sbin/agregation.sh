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
. /usr/lib/eole/zephir.sh

#Initialisation des variables d'etat
# Dernier etat du lien (0: OK, 1: NOK)
LLS1=0
LLS2=0
# Dernier etat du host
LHS1=0
LHS2=0
# Etat actuel du host
CHS1=0
CHS2=0
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
# $1 : message
# $2 : Zephir
# $3 : envoyer le message par mail
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
    # Si demande d'envoi d'un mail
    if [ "$3" = "oui" ] && [ "$ag_active_mail" = "oui" ]; then
        SubJ="Liaison $nom_domaine_local_supp  ($numero_etab)"
        if [ -z "${CC[@]}" ] ; then
            echo "$MssG"|mutt -s "$SubJ" "$DEST"
        else
            echo "$MssG"|mutt -s "$SubJ" "$DEST" -c "${CC[@]}"
        fi
    fi
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
        if [ -n "`/sbin/iptables -t nat -S POSTROUTING $i|grep SNAT|grep "o $nom_zone_eth0"`" ];then
            /sbin/iptables -t nat -D POSTROUTING $i
        else
            let i++
        fi
    done
}

#Vidage des règles iptables de MANGLE $1 = nom de la carte
iptablesmangleclear () {
    i=1
    while [ "$i" -le `/sbin/iptables -t mangle -S PREROUTING|wc -l` ]; do
        if [ -n "`/sbin/iptables -t mangle -S PREROUTING $i|grep " -i $1 "`" ]; then
            /sbin/iptables -t mangle -D PREROUTING $i
        else
            let i++
        fi
    done
}

#Definition de la repartition par interface $1 = nom de la carte
_active_balancing_to() {
    interface=$1
    network=$2
    #Si non NEW
    /sbin/iptables -t mangle -A PREROUTING -i $interface -s $network -m state ! --state NEW -j RESTOREMARK
    /sbin/iptables -t mangle -A PREROUTING -i $interface -s $network -m state ! --state NEW -j RETURN
    #Routes forcees
    for ip_force1 in ${FORCE1[@]}; do
        /sbin/iptables -t mangle -A PREROUTING -i $interface -s $network -d $ip_force1 -m state --state NEW -j T1
        /sbin/iptables -t mangle -A PREROUTING -i $interface -s $network -d $ip_force1 -m state --state NEW -j RETURN
    done
    for ip_force2 in ${FORCE2[@]}; do
        /sbin/iptables -t mangle -A PREROUTING -i $interface -s $network -d $ip_force2 -m state --state NEW -j T2
        /sbin/iptables -t mangle -A PREROUTING -i $interface -s $network -d $ip_force2 -m state --state NEW -j RETURN
    done
    #Si NEW et recent alors Tag puis RETURN
    /sbin/iptables -t mangle -A PREROUTING -i $interface -s $network -m state --state NEW -m recent --name T1 --update --rdest --seconds 3600 -j T1
    /sbin/iptables -t mangle -A PREROUTING -i $interface -s $network -m state --state NEW -m recent --name T1 --update --rdest --seconds 3600 -j RETURN
    /sbin/iptables -t mangle -A PREROUTING -i $interface -s $network -m state --state NEW -m recent --name T2 --update --rdest --seconds 3600 -j T2
    /sbin/iptables -t mangle -A PREROUTING -i $interface -s $network -m state --state NEW -m recent --name T2 --update --rdest --seconds 3600 -j RETURN
    #Si NEW sans recent alors Tag puis RETURN
    #FIXME pas compris a quoi ca sert
    /sbin/iptables -t mangle -A PREROUTING -i $interface -s $network -m state --state NEW -j T2
    #repertition entre lien 1 et 2
    /sbin/iptables -t mangle -A PREROUTING -i $interface -s $network -m state --state NEW -m statistic --mode random --probability 0.$WCO -m recent --name T2 --set --rdest -j RETURN
    /sbin/iptables -t mangle -A PREROUTING -i $interface -s $network -m state --state NEW -m recent --name T1 --set --rdest -j T1
}
active_balancing_to() {
    ointerface=$(CreoleGet nom_carte_eth${1})
    network=$(CreoleGet adresse_network_eth${1})/$(CreoleGet adresse_netmask_eth${1})
    iptablesmangleclear $ointerface
    _active_balancing_to $ointerface $network
    if [ "$(CreoleGet vlan_eth${1})" = "oui" ]; then
        VLAN_ID=($(CreoleGet vlan_id_eth${1}))
        VLAN_Network=($(CreoleGet vlan_network_eth${1}))
        VLAN_Netmask=($(CreoleGet vlan_netmask_eth${1}))
        NB_VLAN=${#VLAN_ID[*]}
        for ((id=0; id < $NB_VLAN; id+=1))
        do
            interface_vlan="$ointerface.${VLAN_ID[id]}"
            iptablesmangleclear $interface_vlan
            network_vlan="${VLAN_Network[id]}/${VLAN_Netmask[id]}"
            _active_balancing_to $interface_vlan $network_vlan
        done
    fi
    if [ "$(CreoleGet alias_eth${1})" = "oui" ]; then
        ALIAS_IP=($(CreoleGet alias_ip_eth${1}))
        ALIAS_Network=($(CreoleGet alias_network_eth${1}))
        ALIAS_Netmask=($(CreoleGet alias_netmask_eth${1}))
        NB_ALIAS=${#ALIAS_IP[*]}
        for ((id=0; id < $NB_ALIAS; id+=1))
        do
            interface_alias="$ointerface"
            network_alias="${ALIAS_Network[id]}/${ALIAS_Netmask[id]}"
            _active_balancing_to $interface_alias $network_alias
        done
    fi
}

#Definition du flux par interface
#$1 = numero de la carte (0, 1, 2, ...)
#$2 = T1 ou T2

_active_link_to() {
    interface=$1
    network=$2
    link=$3
    #Si non NEW
    /sbin/iptables -t mangle -A PREROUTING -i $interface -s $network -m state ! --state NEW -j RESTOREMARK
    /sbin/iptables -t mangle -A PREROUTING -i $interface -s $network -m state ! --state NEW -j RETURN
    #Marques sur $2
    /sbin/iptables -t mangle -A PREROUTING -i $interface -s $network -m state --state NEW -j $link
}
active_link_to() {
    ointerface=$(CreoleGet nom_carte_eth${1})
    network=$(CreoleGet adresse_network_eth${1})/$(CreoleGet adresse_netmask_eth${1})
    link=$2
    iptablesmangleclear $ointerface
    _active_link_to $ointerface $network $link
    if [ "$(CreoleGet vlan_eth${1})" = "oui" ]; then
        VLAN_ID=($(CreoleGet vlan_id_eth${1}))
        VLAN_Network=($(CreoleGet vlan_network_eth${1}))
        VLAN_Netmask=($(CreoleGet vlan_netmask_eth${1}))
        NB_VLAN=${#VLAN_ID[*]}
        for ((id=0; id < $NB_VLAN; id+=1))
        do
            interface_vlan="$ointerface.${VLAN_ID[id]}"
            iptablesmangleclear $interface_vlan
            network_vlan="${VLAN_Network[id]}/${VLAN_Netmask[id]}"
            _active_link_to $interface_vlan $network_vlan $link
        done
    fi
    if [ "$(CreoleGet alias_eth${1})" = "oui" ]; then
        ALIAS_IP=($(CreoleGet alias_ip_eth${1}))
        ALIAS_Network=($(CreoleGet alias_network_eth${1}))
        ALIAS_Netmask=($(CreoleGet alias_netmask_eth${1}))
        NB_ALIAS=${#ALIAS_IP[*]}
        for ((id=0; id < $NB_ALIAS; id+=1))
        do
            interface_alias="$ointerface"
            network_alias="${ALIAS_Network[id]}/${ALIAS_Netmask[id]}"
            _active_link_to $interface_alias $network_alias
        done
    fi

}
## Initialisation
# Large recent table
/sbin/modprobe ipt_recent ip_list_tot=4000

# Vidage du cache et des regles de routage
/sbin/ip route flush cache
/sbin/ip route del default
/sbin/ip route delete default via $GW1 dev $nom_zone_eth0
/sbin/ip route delete default via $GW2 dev $nom_zone_eth0
ipruleclear T1
ipruleclear T2

# Chargement des regles de routage
/sbin/ip rule add from $WAN1 table T1
/sbin/ip route add $NET1 dev $nom_zone_eth0 src $WAN1 table T1
/sbin/ip route add default via $GW1 table T1
/sbin/ip rule add fwmark 1 table T1
# 19643 : on ajoute les réseaux internes dans la table de routage T1
if [ "$(CreoleGet net_route_T1)" == "oui" ] && [ "$(CreoleGet net_route_T2)" == "non" ] ; then
  id=1
  while [ $id -le $(CreoleGet nombre_interfaces) ] && [ $id -ne $(CreoleGet nombre_interfaces) ] ; do
    ointerface=$(CreoleGet nom_carte_eth${id})
    network=$(CreoleGet adresse_network_eth${id})/$(CreoleGet adresse_netmask_eth${id})
    /sbin/ip route add $network dev $ointerface via $(CreoleGet adresse_ip_eth$id) table T1
    let id++
  done
fi

/sbin/ip rule add from $WAN2 table T2
/sbin/ip route add $NET2 dev $nom_zone_eth0 src $WAN2 table T2
/sbin/ip route add default via $GW2 table T2
/sbin/ip rule add fwmark 2 table T2
# 19643 :on ajoute les réseaux internes dans la table de routage T2
if [ "$(CreoleGet net_route_T2)" == "oui" ] && [ "$(CreoleGet net_route_T1)" == "non" ] ; then
  id=1
  while [ $id -le $(CreoleGet nombre_interfaces) ] && [ $id -ne $(CreoleGet nombre_interfaces) ] ; do
    ointerface=$(CreoleGet nom_carte_eth${id})
    network=$(CreoleGet adresse_network_eth${id})/$(CreoleGet adresse_netmask_eth${id})
    /sbin/ip route add $network dev $ointerface via $(CreoleGet adresse_ip_eth$id) table T2
    let id++
  done
fi

#for ip_force1 in ${FORCE1[@]}; do
#    /sbin/ip route add $ip_force1 via $GW1 table main
#done
#for ip_force2 in ${FORCE2[@]}; do
#    /sbin/ip route add $ip_force2 via $GW2 table main
#done

for ip_dns1 in ${DNS1[@]}; do
    /sbin/ip route add $ip_dns1 via $GW1 table main
done
for ip_dns2 in ${DNS2[@]}; do
    /sbin/ip route add $ip_dns2 via $GW2 table main
done


####################

# Vidage des chaines MANGLE
check_T1=$(iptables-save |grep "T1" |wc -l)
check_T2=$(iptables-save |grep "T2" | wc -l)
check_RESTOREMARK=$(iptables-save |grep "RESTOREMARK" |wc -l)
check_PREROUTING=$(iptables-save |grep "PREROUTING" |wc -l)
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
if [ -z "$chaine_T2" ] ; then
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
/sbin/iptables -t nat -A POSTROUTING -o $nom_zone_eth0 -m mark --mark 1 -j SNAT --to-source $WAN1
/sbin/iptables -t nat -A POSTROUTING -o $nom_zone_eth0 -m mark --mark 2 -j SNAT --to-source $WAN2


# Test vers $MIRE sur le lien $L
Checkstate() {
    L=$1
    ID=0
    IM=0
    SUCCES=1
    while [ $IM -lt $IM_C ] && [ $SUCCES -eq 1 ]; do
        while [ "$ID" -lt $(eval echo \$ID$L\_C) ] && [ $SUCCES -eq 1 ]; do
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
    essai=$(eval echo \$COUNT$L)
    if [ $(eval echo \$LHS$L) -ne $(eval echo \$CHS$L) ]; then
        if [ $(eval echo \$LLS$L) -eq 1 ]; then
            msg=" (essai $essai/$NBSUCCES)"
        fi
        Aecho "L'etat du lien $L a change de $(expl $(eval echo \$LHS$L)) a $(expl $(eval echo \$CHS$L))$msg"
        eval COUNT$L=1
    elif [ $(eval echo \$LHS$L) -ne $(eval echo \$LLS$L) ]; then
        Aecho "L'etat du lien $L est bien change (essai $essai/$NBSUCCES)"
        eval COUNT$L=$(( $(eval echo \$COUNT$L) + 1 ))
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

# redirection de tous les flux vers un lien
# $1 : numero du lien (1 ou 2) vers lequel on bascule
# $2 : numero du lien (1 ou 2) inactif
active_link () {
    # 15268 : lien T1/2
    Tlink=T$link
    # lien 1 ou 2
    link=$1
    oldlink=$2
    GW=$(eval echo \$GW$link)
    Aecho "Seul le lien $link est actif, redirection des flux sur ce lien" "" "oui"
    # Iproute2 sur le lien $link
    /sbin/ip route replace default via $GW dev $nom_zone_eth0
    # bascule des destinations forcées de $oldlink vers le lien $link
    for ip_force in $(eval echo \$\{FORCE$oldlink\[@\]\}); do
        /sbin/ip route replace $ip_force via $GW dev $nom_zone_eth0
    done
    # Mangle sur le lien $Tlink
    # 15268 : mangle sur le lien OK et pas de mangle sur le lien NOK
    idint=1
    while [ $idint -le $(CreoleGet nombre_interfaces) ] && [ $idint -ne $(CreoleGet nombre_interfaces) ]; do
        active_link_to $idint $Tlink
        let idint++
    done
}

active_forced_links () {
    # retablit les destination forcees lien 1
    for ip_force in ${FORCE1[@]}; do
        /sbin/ip route replace $ip_force via $GW1 dev $nom_zone_eth0
    done
    # retablit les destination forcees lien 2
    for ip_force in ${FORCE2[@]}; do
        /sbin/ip route replace $ip_force via $GW2 dev $nom_zone_eth0
    done
}

activate() {
    if [ $ag_mode == "mode_lb" ] ; then
        # load balancing
        # Iproute2 sur les 2 liens
        /sbin/ip route replace default proto static nexthop via $GW1 dev $nom_zone_eth0 weight $W1 nexthop via $GW2 dev $nom_zone_eth0 weight $W2
        active_forced_links
        # Mangle sur les 2 liens
        # 14123 : par défaut on balance pour toutes les interfaces sauf eth0
        if [ "$(CreoleGet ag_force_int_eth0)" == "non" ] ; then
            idint=1
            while [ $idint -le $(CreoleGet nombre_interfaces) ] && [ $idint -ne $(CreoleGet nombre_interfaces) ] ; do
                active_balancing_to $idint
                let idint++
            done
        # 14123 : on balance eth1/eth2 et on force eth3/eth4 sur le lien T1
        elif [ "$(CreoleGet ag_force_int_eth0)" == "oui" ] && [ "$(CreoleGet ag_force_int_eth0_0)" == "non" ] ; then
            active_balancing_to 1
            active_balancing_to 2
            for int_force_ in ${INT1[@]}; do
                active_link_to $(echo $int_force_ | cut -d"h" -f2) T1
            done
        # 14123 : on balance eth1/eth2 et on force eth3/eth4 sur le lien T2
        elif [ "$(CreoleGet ag_force_int_eth0_0)" == "oui" ] && [ "$(CreoleGet ag_force_int_eth0)" == "non" ]; then
            active_balancing_to 1
            active_balancing_to 2
            for int_force_ in ${INT2[@]}; do
                active_link_to $(echo $int_force_ | cut -d"h" -f2) T2
            done
        fi
    elif [ $ag_mode == "mode_fo" ] ; then
        #mode fail-over
        active_forced_links
        if [ $ag_fo_etat_eth0 == "actif" ] && [ $ag_fo_etat_eth0_0 == "passif" ] ; then
            /sbin/ip route replace default via $GW1 dev $nom_zone_eth0
        elif [ $ag_fo_etat_eth0 == "passif" ] && [ $ag_fo_etat_eth0_0 == "actif" ] ; then
            /sbin/ip route replace default via $GW2 dev $nom_zone_eth0
        fi
    fi
}

# Log du démarrage
Aecho "Initialisation de l'agregation de liens" 'MSG'
activate

#Boucle infini pour tester les liens
while : ; do
    Checkstate 1
    Checkstate 2

    # Si au moins un lien doit changer
    if [[ $CLS1 -eq 0 || $CLS2 -eq 0 ]]; then
        # Dernier état du lien 1 NOK et du lien 2 OK
        if [[ $LLS1 -eq 1 && $LLS2 -eq 0 ]]; then
            active_link 2 1
        # Dernier état du lien 1 OK et du lien 2 NOK
        elif [[ $LLS1 -eq 0 && $LLS2 -eq 1 ]]; then
            active_link 1 2
        # Dernier état du lien 1 OK et du lien 2 OK
        elif [[ $LLS1 -eq 0 && $LLS2 -eq 0 ]]; then
            Aecho "Rechargement de la repartition sur les 2 liens" 'MSG' 'oui'
            activate
        fi
    fi

    sleep $PAUSE
done
