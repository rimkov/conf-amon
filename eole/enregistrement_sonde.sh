#!/bin/bash
. ParseDico
. FonctionsEoleNg

if [ -z "$1" ]; then
  echo "Usage : enregistrement_sonde.sh (reconf|enreg)"
  exit 0
fi

if [ "-ead" == "$2" ]; then
    EAD="EAD"
fi

reconf() {
#  /bin/rm -rf /etc/prelude/profile/
  /bin/mkdir -p /etc/prelude/profile/
  [ -n "$EAD" ] && exit 0
  enreg
}

test_serv() {
  tcpcheck 2 $adresse_ip_prelude_manager:5553 | grep -qi alive
  if [ "$?" -ne "0" ]; then
    EchoRouge " Attention ! Le serveur d'enregistrement Prelude n'est pas joignable ($adresse_ip_prelude_manager:5553)"
    EchoRouge " Il doit être lancé sur le serveur Prelude-Manager"
    echo -n "Voulez-vous continuer l'enregistrement [O/N] ? "
    read Rep
    if [ "oui" != "$Rep" ] && [ "o" != "$Rep" ] && [ "O" != "$Rep" ]; then
      return 1
    fi
    return 0
  fi
}

enreg() {
if [ "$activer_sonde_prelude" == "oui" ]; then

  #Enregistrement de la sonde snort
  if [ "$sonde_snort" == "oui" ]; then
    if [ ! -f /etc/prelude/profile/snort/key ]; then
      echo
      echo "*** Enregistrement de la sonde Snort ***"
      test_serv
      if [ "$?" -eq "0" ]; then
        echo -n "Entrer le mot de passe du serveur d'enregitrement Prelude pour la sonde Snort : "
        read -s mdp_prelude
        echo
        echo "Pour continuer, veuillez accepter l'enregistrement sur le serveur Prelude-Manager ($adresse_ip_prelude_manager)..."
        /usr/bin/prelude-admin register "snort" "idmef:w admin:r" $adresse_ip_prelude_manager --uid 0 --gid 0 --passwd=$mdp_prelude &> /dev/null
        if [ $? -ne 0 ]; then
          EchoRouge "L'enregistrement de la sonde Snort a échoué"
        else
          EchoVert "L'enregistrement de la sonde Snort a réussie"
        fi
      fi
    fi
  fi

  #Enregistrement de la sonde samhain
  if [ "$sonde_samhain" == "oui" ]; then
    echo
    echo "*** Enregistrement de la sonde Samhain ***"
    test_serv
    if [ "$?" -eq "0" ]; then
      echo -n "Entrer le mot de passe du serveur d'enregitrement Prelude pour la sonde Samhain : "
      read -s mdp_prelude
      echo
      echo "Pour continuer, veuillez accepter l'enregistrement sur le serveur Prelude-Manager ($adresse_ip_prelude_manager)..."
      /usr/bin/prelude-admin register "samhain" "idmef:w admin:r" $adresse_ip_prelude_manager --uid 0 --gid 0 --passwd=$mdp_prelude &> /dev/null
      if [ $? -ne 0 ]; then
        EchoRouge "L'enregistrement de la sonde Samhain a échoué"
      else
        EchoVert "L'enregistrement de la sonde Samhain a réussie"
      fi
    fi
  fi

  #Enregistrement de la sonde nufw
  if [ "$sonde_nufw" == "oui" ]; then
    echo
    echo "*** Enregistrement de la sonde NuFW ***"
    test_serv
    if [ "$?" -eq "0" ]; then
      echo -n "Entrer le mot de passe du serveur d'enregitrement Prelude pour la sonde NuFW : "
      read -s mdp_prelude
      echo
      echo "Pour continuer, veuillez accepter l'enregistrement sur le serveur Prelude-Manager ($adresse_ip_prelude_manager)..."
      /usr/bin/prelude-admin register "nufw" "idmef:w admin:r" $adresse_ip_prelude_manager --uid 0 --gid 0 --passwd=$mdp_prelude &> /dev/null
      if [ $? -ne 0 ]; then
        EchoRouge "L'enregistrement de la sonde NuFW a échoué"
      else
        EchoVert "L'enregistrement de la sonde NuFW a réussie"
      fi
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
