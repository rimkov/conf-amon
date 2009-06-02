#!/bin/bash
#################################################
# enregistrement_domaine.sh
#################################################

. ParseDico
. FonctionsEoleNg

#redemarrage de samba
echo "*** Redémarrage des services pour l'enregistrement au domaine ***"
/sbin/invoke-rc.d winbind stop
/sbin/invoke-rc.d samba restart
/sbin/invoke-rc.d winbind start

#inscription de la station dans un domaine
echo "Entrer le nom de l'administrateur du serveur Windows :"
read user_admin
echo "Entrer le mot de passe de l'administrateur du serveur Windows :"
read -s mdp_admin
/usr/bin/net ads join -U $user_admin%$mdp_admin

#test de l'intégration
if [ `/usr/bin/wbinfo -t` -eq 0 ]; then
  EchoRouge "L'intégration au domaine a échoué"
else
  EchoVert "L'intégration au domaine a réussie"
fi
