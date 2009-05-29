#Enregistrement de la sonde snort
if [ "sonde_snort" == "oui" ]; then
  echo "Entrer le mot de passe du serveur d'enregitrement Prelude :"
  read mdp_prelude
  /usr/bin/prelude-admin register "snort" "idmef:w admin:r" $adresse_ip_prelude_manager --uid 0 --gid 0 --passwd=$mdp_prelude
fi

#Enregistrement de la sonde samhain
if [ "sonde_samhain" == "oui" ]; then
  echo "Entrer le mot de passe du serveur d'enregitrement Prelude :"
  read mdp_prelude
  /usr/bin/prelude-admin register "samhain" "idmef:w admin:r" $adresse_ip_prelude_manager --uid 0 --gid 0 --passwd=$mdp_prelude
fi

#Enregistrement de la sonde nufw
if [ "sonde_nufw" == "oui" ]; then
  echo "Entrer le mot de passe du serveur d'enregitrement Prelude :"
  read mdp_prelude
  /usr/bin/prelude-admin register "nufw" "idmef:w admin:r" $adresse_ip_prelude_manager --uid 0 --gid 0 --passwd=$mdp_prelude
fi
