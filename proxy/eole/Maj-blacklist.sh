#!/bin/bash

. ParseDico
. /usr/share/eole/FonctionsEoleNg

# lieu de stockage des bases
META_PATH="/var/lib/blacklists/meta/"
DB_PATH="/var/lib/blacklists"
# fichier de log spécifique EAD
F_LOG="/usr/share/ead2/backend/tmp/blacklist-date.txt"

echo -n "Mise à jour le " > $F_LOG
date '+%d.%m.%Y à %H:%M :' >> $F_LOG

ServBlacklist=`echo "$url_maj_blacklist" |awk -F "/" '{print $3}'`
echo "Contact du serveur de Maj $ServBlacklist"
/usr/bin/tcpcheck 3 ${ServBlacklist}:80 | grep -q alive
if [ $? == 1 ];then
	# Essai avec Proxy
	# la variable à utiliser sur Amon est $nom_cache_pere et pas $serveur_proxy 
	if [ -n "$nom_cache_pere" ];then
		http_proxy=${http_proxy=http://$nom_cache_pere:$port_cache_pere}
	else
		http_proxy=${http_proxy=http://localhost:3128} # Pour Amon
	fi
	export http_proxy
	echo "Utilisation du Proxy: $http_proxy" | tee -a $F_LOG
	Proxy=` echo $http_proxy | sed -e 's!http://!!' `
	/usr/bin/tcpcheck 3 $Proxy | grep -q "alive"
	if [ "$?" == 1 ];then
		Zephir "ERR" "Le proxy $Proxy ne répond pas !" "Maj-blacklist" 2>&1 | tee -a $F_LOG
		sed -i 1i"Erreur : impossible d'accéder au site" $F_LOG
		exit 1
	fi
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
echo "$res" | grep -q -E "pas de récupération.|not retrieving."
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
echo "$res" | grep -q -E "pas de récupération.|not retrieving."
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

	chown -R proxy.proxy $DB_PATH/eole/
	chown -R proxy.proxy $DB_PATH/db/
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
	/etc/init.d/dansguardian restart
fi
