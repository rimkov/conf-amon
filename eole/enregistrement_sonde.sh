#!/bin/bash
. ParseDico
. FonctionsEoleNg

if [ -z "$1" ]; then
  echo "Usage : enregistrement_sonde.sh (reconf|enreg)"
  exit 0
fi

reconf() {
  /bin/rm -rf /etc/prelude/profile/
  enreg
}

enreg() {
if [ "$activer_sonde_prelude" == "oui" ]; then

  EchoRouge " *** Attention ! Le serveur d'enregistrement Prelude doit être lancé sur Prelude-Manager ***"

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

fi
}

case "$1" in
        reconf)
                reconf
                ;;
        enreg)
                enreg
                ;;
        esac
