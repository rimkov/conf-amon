#!/usr/bin/python
# -*- coding: UTF-8 -*-

import os, sys, shutil

def copie_fich(repsauv):
    #Définition de la liste des fichiers :
      #Bases optionelles
      #Type de filtrage
      #postes interdits (par tranche horaire)
      #règles optionelles
      #sous-résseaux interdits (service => securité perso)
      #horaires personnalisées
      #scripts personnalisés
      #scripts personnalisés (répertoire)
      #kill-p2p
      #base perso, utilisateurs interdits et modérateurs
    LISTE_FICHIERS=['/etc/squid/filtres-users',
    '/var/www/ead/tmp/filtrage-contenu',
    '/var/www/ead/tmp/horaires_ip.txt',
    '/var/www/ead/tmp/regles.csv',
    '/var/www/ead/tmp/poste.txt',
    '/var/www/ead/tmp/horaires.txt',
    '/var/www/ead/serialize_btn.srz',
    '/usr/share/ead/perso/',
    '/var/www/ead/tmp/kill-p2p',
    '/var/lib/blacklists/db/local/']
    for i in LISTE_FICHIERS:
        if os.path.isdir(repsauv+i):
            os.system('cp -Rf '+repsauv+i+'/* '+i)
        if os.path.isfile(repsauv+i):
            shutil.copy(repsauv+i,i)

def copy_modele_parefeu(repsauv):
    os.system('cp -f %s /usr/share/era/modeles/'%os.path.join(repsauv,'*.xml'))

def lance_commandes():
    os.system('/usr/share/ead/engine-ajout_filtres.sh')
    if os.path.isfile('/var/www/ead/tmp/filtrage-contenu'):
        type_filtrage = file('/var/www/ead/tmp/filtrage-contenu').readline().strip()
        type_filtrage_dico = { '0':'--desactive_contenu', '1':'--active_meta', '2':'--active_contenu' }
        os.system('/usr/share/ead/config_dans.py '+type_filtrage_dico[type_filtrage])
    if os.path.isfile('/var/www/ead/tmp/kill-p2p'):
        os.system('/etc/init.d/kill-p2p restart')

def main(repsauv):
    copie_fich(repsauv)
    copy_modele_parefeu(repsauv)
    lance_commandes()

if __name__ == '__main__':
    try:
        repsauv = sys.argv[1]
    except:
        print 'Usage : '+sys.argv[0]+' répertoire contenant la sauvegarde de la configuration Amon'
        sys.exit(1)
    main(repsauv)

