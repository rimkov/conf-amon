#! /usr/bin/env python
# -*- coding: UTF-8 -*-
from zephir.lib_zephir import *
from zephir.zephir_conf.zephir_conf import id_serveur, adresse_zephir
import sys,xmlrpclib,os

try:
    # arguments
    login=sys.argv[1]
    passwd=sys.argv[2]
    id_sphynx=sys.argv[3]
    path=sys.argv[4]
    try:
        zephir=xmlrpclib.ServerProxy("https://%s:%s@%s:7080" % (login,passwd,adresse_zephir), transport=TransportEole())
    except xmlrpclib.ProtocolError:
        sys.exit("Erreur d'authentification zephir")
    # récupération de l'archive de configuration vpn
    contenu_b64 = zephir.uucp.sphynx_get(id_sphynx,id_serveur)
    contenu = xmlrpclib.base64.decodestring(contenu_b64[1])
    # écriture du fichier tar
    archive = path+os.sep+'vpn_%star.gz' % id_sphynx
    f=open(archive,"w")
    f.write(contenu)
    f.close()
    # décompression de l'archive
    os.system("cd %s;/bin/tar xzf %s" % (path,archive))
    os.unlink(archive)
except:
    # erreur de récupération
    sys.exit("erreur de récupération de l'archive sur zephir")

