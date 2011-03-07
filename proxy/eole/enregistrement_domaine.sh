#!/bin/bash
#################################################
# enregistrement_domaine.sh
#################################################

. ParseDico
. /etc/eole/containers.conf
. /usr/share/eole/FonctionsEoleNg

RunCmd "/usr/bin/wbinfo -t" proxy &>/dev/null
if [ $? -eq 0 ];then
    QUESTION="Le serveur est déjà intégré à un domaine\nRelancer l'intégration ?"
    Question_ouinon $QUESTION non warn
    [ $? -ne 0 ] && exit 0
fi

#redemarrage de samba
echo "*** Redémarrage des services pour l'enregistrement au domaine ***"
Service winbind stop proxy &>/dev/null
Service smbd restart proxy &>/dev/null
Service winbind start proxy &>/dev/null

#inscription de la station dans un domaine
echo
echo "Entrer le nom de l'administrateur du serveur Windows :"
read user_admin
echo "Entrer le mot de passe de l'administrateur du serveur Windows :"
read -s mdp_admin
RunCmd "/usr/bin/net ads join -S $ip_serveur_krb -U $user_admin%$mdp_admin" proxy
echo

#redemarrage de samba
echo "*** Redémarrage des services pour confirmer l'enregistrement au domaine ***"
Service winbind stop proxy &>/dev/null
Service smbd restart proxy &>/dev/null
Service winbind start proxy &>/dev/null

#test de l'intégration
RunCmd "/usr/bin/wbinfo -t" proxy &>/dev/null
if [ $? -eq 1 ]; then
    EchoRouge "L'intégration au domaine a échoué"
else
    EchoVert "L'intégration au domaine a réussi"
fi
