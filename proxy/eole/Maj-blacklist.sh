#!/bin/bash

. ParseDico
. /etc/eole/containers.conf
. /usr/share/eole/FonctionsEoleNg

# lieu de stockage des bases
SHORT_META_PATH="/var/lib/blacklists/meta/"
META_PATH="$container_path_proxy$SHORT_META_PATH"
SHORT_DB_PATH="/var/lib/blacklists"
DB_PATH="$container_path_proxy$SHORT_DB_PATH"
# fichier de log spécifique EAD
F_LOG="/usr/share/ead2/backend/tmp/blacklist-date.txt"

echo -n "Mise à jour le " > $F_LOG
date '+%d.%m.%Y à %H:%M :' >> $F_LOG

ServBlacklist=`echo "$url_maj_blacklist" |awk -F "/" '{print $3}'`

#La variable d'environment http_proxy est prioritaire
if [ "$activer_proxy" == "oui" ];then  # Si variable Dico
    export http_proxy=${http_proxy=http://$proxy_client_adresse:$proxy_client_port}
fi
if [ -n "$http_proxy" ];then
    # Essai avec Proxy
    echo "Utilisation du Proxy : $http_proxy" | tee -a $F_LOG
    Proxy=` echo $http_proxy | sed -e 's!http://!!' `
    TestService "Serveur Proxy" $Proxy 2>&1
    if [ $? != 0 ];then
        Zephir "ERR" "Le proxy $Proxy ne répond pas !" "Maj-blacklist" 2>&1 | tee -a $F_LOG
	#sed -i 1i"Erreur : impossible d'accéder au site" $F_LOG
        exit 1
    fi
fi
TestService "Contact avec $ServBlacklist" "${ServBlacklist}:80" 2>&1
if [ $? != 0 ];then
    Zephir "ERR" "Impossible d'accéder au site de mise à jour !" "Maj-blacklist" 2>&1 | tee -a $F_LOG
    #sed -i 1i"Erreur : impossible d'accéder au site" $F_LOG
    exit 1
fi

## on se pose dans /tmp ##
cd $DB_PATH/tmp

echo "Téléchargement des bases"

res=`wget --timestamping $url_maj_blacklist/blacklists.tar.gz 2>&1`
if [ $? == 1 ];then
	echo "Le fichier blacklists.tar.gz n'a pas été trouvé !" | tee -a $F_LOG
	sed -i 1i"Erreur : blacklists.tar.gz non disponible" $F_LOG
	exit 1
fi
echo "$res" | grep -q -E "non récupéré|not retrieving"
if [ $? == 0 ];then
	blacklists="0"
else
	blacklists="1"
fi

## Fichier weighted ##
res=`wget --timestamping $url_maj_blacklist/weighted 2>&1`
if [ $? == 1 ];then
	echo "Le fichier weighted n'a pas été trouvé !" | tee -a $F_LOG
	sed -i 1i"Erreur : fichier weighted non disponible" $F_LOG
	exit 1
fi
echo "$res" | grep -q -E "non récupéré|not retrieving"
if [ $? == 0 ];then
	weighted="0"
else
	weighted="1"
fi

## Base blacklists (si nécessaire) ##
if [ "$blacklists" == "1" ];then
	echo "Intégration des bases"
	tar -xzf blacklists.tar.gz
	if [ $? -ne 0 ];then
		echo "L'archive blacklists.tar.gz n'a pas pu être décompressée !" | tee -a $F_LOG
		sed -i 1i"Erreur : décompression de blacklists.tar.gz impossible" $F_LOG
		exit 1
	fi

	## Filtres obligatoires (dans db) ##
	for base in "adult" "redirector"
	do
		[ ! -d $DB_PATH/db/$base ] && mkdir -p $DB_PATH/db/$base
		for file in "$DB_PATH/tmp/blacklists/$base/domains" "$DB_PATH/tmp/blacklists/$base/urls"
		do
			if [ -f $file ];then
				count=`wc -l $file | awk -F " " '{print $1}'`
				if [ ! "$count" -eq "0" ];then
					cp $file $DB_PATH/db/$base
				else
					echo 'le fichier' $file 'est vide !'
				fi
			fi
		done
	done

	## Filtres optionnels (dans eole) ##
	# FIXME : concaténation de bases ?
	for base in "agressif" "audio-video" "drogue" "forums" "gambling" "games" "hacking" "mobile-phone" "phishing" \
		    "publicite" "radio" "tricheur" "warez" "webmail" "strict_redirector" "strong_redirector" "mixed_adult"
	do
		[ ! -d $DB_PATH/eole/$base ] && mkdir -p $DB_PATH/eole/$base
		[ ! -d $DB_PATH/db/$base ] && mkdir -p $DB_PATH/db/$base ## Desuet n'est plus utilise dans dansguardian?
		[ ! -e $DB_PATH/eole/$base/domains ] && touch $DB_PATH/eole/$base/domains
		[ ! -e $DB_PATH/eole/$base/urls ] && touch $DB_PATH/eole/$base/urls

		for file in "$DB_PATH/tmp/blacklists/$base/domains" "$DB_PATH/tmp/blacklists/$base/urls"
		do
			if [ -f $file ];then
				count=`wc -l $file | awk -F " " '{print $1}'`
				if [ ! "$count" -eq "0" ];then
					cp $file $DB_PATH/eole/$base
				else
					echo 'le fichier' $file 'est vide !'
				fi
			fi
		done
	done

	RunCmd "chown -R proxy.proxy $SHORT_DB_PATH/eole/" proxy
	RunCmd "chown -R proxy.proxy $SHORT_DB_PATH/db/"   proxy
else
	echo "Rien à faire pour blacklists.tar.gz"
fi

## Fichier weighted (si nécessaire) ##
if [ $weighted == "1" ]
then
	echo "Copie du fichier weighted"
	cp -f $DB_PATH/tmp/weighted $META_PATH
else
	echo "Rien à faire pour le fichier weighted"
fi


# formatage de la date du fichier pour EAD
bdate=`ls -l --time-style="+%d.%m.%Y %H:%M" blacklists.tar.gz`
echo -n "- bases du " >> $F_LOG
echo -n `echo -n $bdate | awk -F' ' '{print $6} {print $7}'` >> $F_LOG
echo >> $F_LOG
wdate=`ls -l --time-style="+%d.%m.%Y %H:%M" weighted`
echo -n "- fichier weighted du " >> $F_LOG
echo -n `echo -n $bdate | awk -F' ' '{print $6} {print $7}'` >> $F_LOG
echo >> $F_LOG

## Suppression des fichiers
# on laisse le tar.gz pour utiliser l'option --timestamping de wget
rm -rf $DB_PATH/tmp/adult
rm -rf $DB_PATH/tmp/blacklists
#rm -f $DB_PATH/tmp/blacklists.tar.gz
#rm -f $DB_PATH/tmp/weighted

# redémarrage si au moins une modification
if [ "$blacklists" == "1" -o $weighted == "1" ];then
	Service dansguardian restart proxy
fi
