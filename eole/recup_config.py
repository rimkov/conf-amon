#!/usr/bin/python
# -*- coding: UTF-8 -*-

import os, sys, shutil
from creole.parsedico import parse_dico

def copie_fich(repsauv):
    if os.path.isdir(repsauv):
        print 'Le répertoire "'+repsauv+'" existe déjà.\nErreur'
        sys.exit(1)
    try:
        os.makedirs(repsauv)
    except:
        print 'Création du répertoire '+repsauv+' impossible.\nErreur'
        sys.exit(1)
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
        if os.path.isdir(i):
            if not os.path.isdir(repsauv+i):
                os.makedirs(repsauv+i)
            os.system('cp -R '+i+'/* '+repsauv+i)
        if os.path.isfile(i):
            if not os.path.isdir(repsauv+os.path.dirname(i)):
                os.makedirs(repsauv+os.path.dirname(i))
            shutil.copy(i,repsauv+os.path.dirname(i))

def copy_modele_parefeu(repsauv):
    modele = parse_dico()['type_amon']
    shutil.copy('/usr/share/era/modeles/'+modele+'.xml',repsauv)

def main(repsauv):
    copie_fich(repsauv)
    copy_modele_parefeu(repsauv)

if __name__ == '__main__':
    try:
        repsauv = sys.argv[1]
    except:
        print 'Usage : '+sys.argv[0]+' repertoire (ne doit pas exister)'
        sys.exit(1)
    main(repsauv)

