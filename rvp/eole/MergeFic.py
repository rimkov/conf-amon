#!/usr/bin/python
# -*- coding: UTF-8 -*-
#####################
# Merge 
# Version Alpha
# LB 12/2002
# $Id: MergeFic.py,v 1.1.1.1.4.1 2004/12/10 10:19:11 sam Exp $
#####################
import string,getopt,sys


def Usage():
	print "Usage : "
	print "MergeFic -i Fichier-A-Inserer -o Fichier-A-Modifier -r Fichier-Resultat -d Chaine Deb -f Chaine Fin"
	print """
Fonction: 
	 Inserer le contenu d'un fichier cible
	 dans un fichier destination
	 en fonction de deux balises (Debut et Fin)
	 """
	sys.exit

def Option():
        global Input , Output , Deb , Fin , Result
	try:
		(opt, args) = getopt.getopt(sys.argv[1:], "hi:o:d:f:r:" ,["help","input=","output=","deb=","fin=","result"])
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
		if o in ("-d","--deb"):
			if ch == "":
				Usage()
			Deb = ch
		if o in ("-f","--fin"):
			if ch == "":
				Usage()
			Fin = ch
		if o in ("-r","--result"):
			if ch == "":
				Usage()
			Result = ch

def CreFic(Nom):
	
	Fichier = Nom
	try:
		Desc= open(Fichier,"w")
	except:
		print "Fichier %s Non créé" % Fichier
		sys.exit(2)
	return(Desc)

def Avance(Fic,Cherche):
    global ligne		
    while ( ligne.find(Cherche)== -1 ):
        ligne=Fic.readline()
        if ligne=='':
            print "\nErreur Fichier Non conforme"  
            print "Chaine %s non trouvéé" % Cherche 
	    sys.exit(2)

##################### MAIN ################	
Input=Output=Deb=Fin=Result=""
Option()
#print "In=%s Out=%s" % (Input , Output)
#print "Deb=%s Fin=%s" % (Deb , Fin)
if (Input==""):
	Fic=sys.stdin
else:
   try:
	FicIn= open(Input,"r")
   except:
	print "Fichier %s Non trouvé" % Input
	sys.exit(2)
try:
	FicDest= open(Output,"r")
except:
	print "Fichier %s Non trouvé" % Output
	sys.exit(2)
if (Result==""):
	C1=sys.stdout
else:
	C1=CreFic(Result)

# Traitement Principal
# On ecrit jusqu'a trouver la chaine de Debut ou de Fin
Sligne=ligne=FicDest.readline()
while (  (ligne.find(Deb)==-1) and (ligne.find(Fin)==-1) and (ligne!='')):
    C1.write(ligne)
    ligne=FicDest.readline()
    Sligne=ligne


# On Avance dans le fichier à inserer 
# jusqu'a trouver la chaine de Debut
# Stop si pas trouvé!

ligne=FicIn.readline()
Avance(FicIn,Deb)

# On ecrit depuis le fichier à insere
# jusqu'a la chaine FIN

while (ligne.find(Fin)==-1):
    C1.write(ligne)
    ligne=FicIn.readline()
    if ligne=='':
          print "Erreur Fichier %s Non conforme" % Input 
          print "Chaine de FIN %s non trouvéé" % Fin 
          sys.exit(2)
C1.write(ligne)

# On Avance dans le fichier initial 
# jusqu'a trouver la chaine de FIN
# Stop si pas trouvé!

ligne=Sligne
if (ligne!=''):
	Avance(FicDest,Fin)
	ligne=FicDest.readline()
	while (ligne!=''):
    	   C1.write(ligne)
           ligne=FicDest.readline()
        


