#!/usr/bin/python
# -*- coding: utf-8 -*-

#########################################################
# Utilitaire de génération du mot de passe EAD Amon
# Equipe Eole <eole@ac-dijon.fr>
# juin 2006
#########################################################

import crypt
import getpass
import os
import sys

try:
    num = sys.argv[1]
except:
    sys.exit("Appel incorrect au programme de changement de mot de passe")

if int(num) == 1:
    shadow = '/etc/httpd/shadow'
    user = 'admin'
else:
    shadow = '/etc/httpd/shadow2'
    user = 'administrateur'


login = raw_input("Login de l'utilisateur EAD1 [%s] : "%user)
if login == '':
    login = user

test = False
while test == False :
    pwd = getpass.getpass("Changement du mot de passe %s (5 caractères minimum) : "%login)
    pwd2= getpass.getpass("Confirmation du mot de passe : ")
    if len(pwd) < 5 :
        print "Mot de passe trop court !\n"
    elif (pwd != pwd2) :
        print "Erreur lors de la confirmation du mot de passe ! "
    else:
        test = True

encrypted_username = crypt.crypt(login[0:8],"Za")
encrypted_username+= crypt.crypt(login[8:16],"Za")[2:13]

encrypted_password = crypt.crypt(pwd[0:8],encrypted_username[2:4])
encrypted_password+= crypt.crypt(pwd[8:16],encrypted_username[2:4])[2:13]

try:
    f = open(shadow,'w')
    f.write('%s:%s'%(encrypted_username, encrypted_password))
    f.close()
    os.system("chown www-data:www-data %s"%shadow)
except:
    print "Impossible d'enregistrer le mot de passe"
else:
    print "Modification effectuée"

