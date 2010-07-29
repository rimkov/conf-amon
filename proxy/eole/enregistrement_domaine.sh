#!/bin/bash
#################################################
# enregistrement_domaine.sh
#################################################

. ParseDico
. /etc/eole/containers.conf
. /usr/share/eole/FonctionsEoleNg

#redemarrage de samba
echo "*** Redémarrage des services pour l'enregistrement au domaine ***"
Service winbind stop proxy &>/dev/null
Service smbd restart proxy &>/dev/null
Service winbind start proxy &>/dev/null

if [ -e "$container_path_proxy/var/run/samba/winbindd_privileged" ]; then
    RunCmd "chgrp proxy /var/run/samba/winbindd_privileged" proxy
    Service squid restart proxy
fi

#inscription de la station dans un domaine
echo
echo "Entrer le nom de l'administrateur du serveur Windows :"
read user_admin
echo "Entrer le mot de passe de l'administrateur du serveur Windows :"
read -s mdp_admin
RunCmd "/usr/bin/net ads join -U $user_admin%$mdp_admin" proxy #&>dev/null

#test de l'intégration
echo

RunCmd "/usr/bin/wbinfo -t" proxy #&> /dev/null
if [ $? -eq 1 ]; then
    EchoRouge "L'intégration au domaine a échoué"
else
    EchoVert "L'intégration au domaine a réussi"
fi
