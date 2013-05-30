#!/usr/bin/python
# -*- coding: UTF-8 -*-

import os, sys, shutil

LISTE_FICHIERS=[
        '/etc/squid/filtres-users',
        '/var/www/ead/tmp/',
        '/usr/share/ead/perso/',
        '/usr/share/ead2/backend/config/roles_local.ini',
        '/usr/share/ead2/backend/config/perm_local.ini',
        '/usr/share/ead2/backend/tmp/ipset_group0.txt',
        '/usr/share/ead2/backend/tmp/ipset_schedules0.pickle',
        '/usr/share/ead2/backend/tmp/ipset_group1.txt',
        '/usr/share/ead2/backend/tmp/ipset_schedules1.pickle',
        '/usr/share/ead2/backend/tmp/regles.csv',
        '/usr/share/ead2/backend/tmp/poste_all0.txt',
        '/usr/share/ead2/backend/tmp/poste_all1.txt',
        '/usr/share/ead2/backend/tmp/horaire_ip0.txt',
        '/usr/share/ead2/backend/tmp/horaire_ip1.txt',
        '/usr/share/ead2/backend/tmp/dest_interdites0.txt',
        '/usr/share/ead2/backend/tmp/dest_interdites1.txt',
        '/usr/share/ead2/backend/tmp/filtrage-contenu0',
        '/usr/share/ead2/backend/tmp/filtrage-contenu1',
        '/var/lib/blacklists/dansguardian0/',
        '/var/lib/blacklists/dansguardian1/',
]

def copie_fich(repsauv):
    #Définition de la liste des fichiers :
      #Bases optionelles
      #Type de filtrage
      #postes interdits (par tranche horaire)
      #règles optionelles
      #sous-résseaux interdits (service => securité perso)

    for i in LISTE_FICHIERS:
        if os.path.isdir(repsauv+i):
            os.system('cp -Rf '+repsauv+i+'/* '+i)
        if os.path.isfile(repsauv+i):
            shutil.copy(repsauv+i,i)

def copy_modele_parefeu(repsauv):
    os.system('cp -f %s /usr/share/era/modeles/'%os.path.join(repsauv,'*.xml'))

def lance_commandes(init_dans=False):
    if init_dans:
        os.system('/usr/share/eole/prereconf/config >/dev/null 2>&1')
        os.system('/etc/init.d/bastion restart')

def main(repsauv):
    copie_fich(repsauv)
    copy_modele_parefeu(repsauv)
    lance_commandes(True)

if __name__ == '__main__':
    try:
        repsauv = sys.argv[1]
    except:
        print 'Usage : '+sys.argv[0]+' répertoire contenant la sauvegarde de la configuration Amon'
        sys.exit(1)
    main(repsauv)

