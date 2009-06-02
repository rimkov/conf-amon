#!/bin/bash
. ParseDico
. FonctionsEoleNg

EchoRouge " *** Attention ! Le serveur d'enregistrement Prelude doit être lancé sur Prelude-Manager ***"

if [ -n "$0" ]; then
  echo "Usage : `basename $0` (reconfigure|enregistrement)"
  exit 0
fi

if [ $0 == "reconfigure" ]; then
  reconfigure
else
  enregistrement
fi

reconfigure () {
  /bin/rm -rf /etc/prelude/profile/
  enregistrement
}

enregistrement (){

  #Enregistrement de la sonde snort
  if [ "sonde_snort" == "oui" ]; then
    echo "Entrer le mot de passe du serveur d'enregitrement Prelude pour la sonde Snort:"
    read -s mdp_prelude
    /usr/bin/prelude-admin register "snort" "idmef:w admin:r" $adresse_ip_prelude_manager --uid 0 --gid 0 --passwd=$mdp_prelude &> /dev/null
    if [ $? -eq 0 ]; then
      EchoRouge "L'enregistrement de la sonde Snort a échoué"
    else
      EchoVert "L'enregistrement de la sonde Snort a réussie"
    fi
  fi

  #Enregistrement de la sonde samhain
  if [ "sonde_samhain" == "oui" ]; then
    echo "Entrer le mot de passe du serveur d'enregitrement Prelude pour la sonde Samhain:"
    read -s mdp_prelude
    /usr/bin/prelude-admin register "samhain" "idmef:w admin:r" $adresse_ip_prelude_manager --uid 0 --gid 0 --passwd=$mdp_prelude &> /dev/null
    if [ $? -eq 0 ]; then
      EchoRouge "L'enregistrement de la sonde Samhain a échoué"
    else
      EchoVert "L'enregistrement de la sonde Samhain a réussie"
    fi
  fi

  #Enregistrement de la sonde nufw
  if [ "sonde_nufw" == "oui" ]; then
    echo "Entrer le mot de passe du serveur d'enregitrement Prelude pour la sonde NuFW:"
    read -s mdp_prelude
    /usr/bin/prelude-admin register "nufw" "idmef:w admin:r" $adresse_ip_prelude_manager --uid 0 --gid 0 --passwd=$mdp_prelude &> /dev/null
    if [ $? -eq 0 ]; then
      EchoRouge "L'enregistrement de la sonde NuFW a échoué"
    else
      EchoVert "L'enregistrement de la sonde NuFW a réussie"
    fi
  fi

}
