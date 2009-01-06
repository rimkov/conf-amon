#!/usr/bin/python
# -*- coding: UTF-8 -*-

#####################
# Parse pour Certificat
# Version Alpha
# LB 12/2002
# $Id: ParsePEM.py,v 1.1.1.1 2004/01/05 10:50:56 eole Exp $
#####################
import string,getopt,sys


def Usage():
	print "Usage : "
	print "ParsePem -i FichierPem -o Repertoire de destination"
	print """
Fonction: 
         Recuperer les 2 Certificats (CA+Serveur)
         contenus dans le fichier en entré et creer
         deux fichiers CertifCa et CertifServeur
         dans le Repertoire de destination
	 """
	sys.exit

def Option():
	global Input , Output
	try:
		(opt, args) = getopt.getopt(sys.argv[1:], "hi:o:" ,["help","input=","output="])
   	except: 
	   getopt.GetoptError
	   Usage()
	   sys.exit(1)
        #print "opt=%s" % opt	
	for (o , ch) in opt:
		if o in ("-h", "--help"):
			Usage()
			sys.exit()
		if o in ("-o","--output"):
			if ch == "":
				Usage()
			Output = ch
		if o in ("-i","--intput"):
			if ch == "":
				Usage()
			Input = ch

def CreFic(Nom):
	
	Fichier = Output+"/"+Nom
	print "%s" % Fichier
	try:
		Desc= open(Fichier,"w")
	except:
		print "Fichier %s Non créé" % Fichier
		sys.exit(2)
	return(Desc)

def Avance(Cherche):
    global ligne		
    while ( ligne.find(Cherche)== -1 ):
        #print "Ligne=%s" % ligne
        ligne=Fic.readline()
        if ligne=='':
            print "Erreur Fichier %s Non conforme" % Input 
            print "Chaine %s non trouvéé" % Cherche 
	    sys.exit(2)

##################### MAIN ################	
Input=Output=""
Option()
print "In=%s Out=%s" % (Input , Output)
if (Input==""):
	Fic=sys.stdin
else:
   try:
	Fic= open(Input,"r")
   except:
	print "Fichier %s Non trouvé" % Input
	sys.exit(2)

C1=CreFic("CertifCa.pem")

ligne=Fic.readline()
Avance("-BEGIN CERTIF")
#Certif CA trouvé  "   
while (ligne.find("-END CERTIF")==-1):
    C1.write(ligne)
    ligne=Fic.readline()
    if ligne=='':
        print "Erreur Cerificat CA  "
	sys.exit(2)
C1.write(ligne)

Avance("subject=")
(Bid,CN)=ligne.split("CN=")
outf="%s.pem" % CN.strip()
C2=CreFic(outf)
Avance("-BEGIN CERTIF")
#Certif Client  trouvé  "   
while (ligne.find("-END CERTIF")==-1):
    C2.write(ligne)
    ligne=Fic.readline()
    if ligne=='':
        print "Erreur Cerificat Serveur "
	sys.exit(2)
C2.write(ligne)



        


