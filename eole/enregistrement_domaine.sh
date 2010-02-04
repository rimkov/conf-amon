#!/bin/bash
#################################################
# enregistrement_domaine.sh
#################################################

. ParseDico
. FonctionsEoleNg

#redemarrage de samba
echo "*** Redémarrage des services pour l'enregistrement au domaine ***"
/sbin/invoke-rc.d winbind stop &> /dev/null
/sbin/invoke-rc.d samba restart &> /dev/null
/sbin/invoke-rc.d winbind start &> /dev/null

if [ -e /var/run/samba/winbindd_privileged ]; then
	/bin/chgrp proxy /var/run/samba/winbindd_privileged
	/usr/sbin/invoke-rc.d squid restart
fi

#inscription de la station dans un domaine
echo
echo "Entrer le nom de l'administrateur du serveur Windows :"
read user_admin
echo "Entrer le mot de passe de l'administrateur du serveur Windows :"
read -s mdp_admin
/usr/bin/net ads join -U $user_admin%$mdp_admin &> /dev/null

#test de l'intégration
echo

/usr/bin/wbinfo -t &> /dev/null
if [ $? -eq 1 ]; then
  EchoRouge "L'intégration au domaine a échoué"
else
  EchoVert "L'intégration au domaine a réussi"
fi
