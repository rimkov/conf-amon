#!/usr/bin/perl 

###############################################################
# script de détection des alertes sur les bases de données rrd
# (charge réseau)
# par bruno boiget (CETIAD)
# #############################################################

use RRDs;
use strict;
use Getopt::Std;

# gestion d'alarme dans une base rrd
my $alerte = 0;
my $pair = 0;
my $output = 0;
my $input = 0;
my $seuil = 0;
my $interf = "";
my $fic_alerte = "/usr/share/ead/rrd/alerte.tmp";
my $rep_bas_rrd = "/usr/share/ead/rrd/";
my $rep_scripts= "/usr/share/eole";
			

# A chaque appel du script, la base de données et le seuil limite sont passés en paramètre
use vars qw($opt_i $opt_s);

# message d'aide :
my $help = "\n usage : alerte.pl -i<interface> -s<seuil de charge>";

# Nous lisons la liste des options

unless( getopts('i:s:') )
{
	print STDERR $help;
	exit 0;
}

if( $opt_i )
{
	$interf = $opt_i;
}
unless( $opt_i )
{
	print STDERR $help;
	print STDERR "\n*** Erreur : Spécifiez l'interface réseau\n             (eth0,eth1,...,squid)\n";
	exit 0;
}

if( $opt_s )
{
	$seuil = $opt_s;
}
unless( $opt_s )
{
	print STDERR $help;
	print STDERR "\n*** Erreur : Spécifiez le seuil de surcharge\n";
	exit 0;
}	


# print "\n arguments: ", $interf, " - ", $seuil, ".\n";

# on récupère la moyenne sur les 5 dernières minutes (dernières valeurs enregistrées)
my ($start,$step,$names,$data) = RRDs::fetch ("$rep_bas_rrd/".$interf.".rrd", "--start=-900", "AVERAGE");


# test des valeurs récuperées
 foreach my $line (@$data[3])
 {
	foreach my $val (@$line) 
	{
		if ($pair == 1)
		{
			$pair = 0
		}
		else
		{
			$pair = 1
		}


		if ( ("$interf" eq "squid_system") && ($pair == 0) )
		{
			# cas spécial : cas de la charge cpu/mémoire squid
			# ici, les 2 valeurs ont des échelles différentes
			#                         
			# on ramène la valeur de la mémoire à un pourcentage
			# pour avoir le même seuil que pour le cpu
			#
			# on récupère la taille mémoire
		
			my $mem_physique = `cat /proc/meminfo | grep MemTotal: |mawk -F " " '{print $2}'`;
			# on passe la valeur de Koctets à octets
			$val = $val * 1000;
			# et on calcule le % d'occupation
			$val = ($val * 100) / $mem_physique;
		}
		
		#printf "%d \n", $val;
		if (($seuil - $val) le 0)
		{
			$alerte = 1;
		}
	}
}

if ($alerte == 1) {
	print "\n !!! Attention : ", $interf, " actuellement en surcharge !!! \n";
	# vérification de la durée de la surcharge	
	# on vérifie la moyenne de charge sur les 20 dernières minutes
	# si elle est supérieure ou égale au seuil -> alerte visuelle
	# les données retournées par rrdool étant alternées en entrée/sortie,
	# on utilise un flag pair/impair pour pouvoir les différencier
	
	# calcul de la moyenne
	# on ajoute les 4 dernières moyennes (sur 5 minutes)
	foreach my $line (@$data[0,1,2,3])
	{
		foreach my $val (@$line)
		{
			# printf "%d \n", $val;
			
			if ($pair == 1)
			{
				$pair = 0
			}
			else
			{
				$pair = 1
			}
			
			if ($pair == 1)
			{
				$input += $val;
			}
			else
			{
				$output += $val;
			}	
		}
	}
	# puis, on divise le tout par quatre pour obtenir la moyenne sur les 20 dernières minutes
	# (les valeurs étant en octets/s, on divise par 1000 pour obtenir des Ko/s)
	$input = $input/4;
	$output = $output/4;
	printf "\n Moyennes sur les 20 dernières minutes \n -- Entrée : %6.1f Ko/s \n -- Sortie : %6.1f Ko/s \n\n", ($input/1000), ($output/1000);

	# Si la moyenne sur 20 minutes dépasse le seuil et qu'il n'existe pas encore de fichier d'alerte :
	# on remonte l'alerte
	
	if ( ($input > $seuil) || ($output > $seuil) )
	{
		# à moins que l'alerte soit déjà déclarée
		unless ( open (FIC_TEST, "$fic_alerte" ) )
		{
			# appel du script permettant la remontée de l'alerte dans les logs (Zephir)
			system("$rep_scripts/logalerte.sh", "$interf", "début") == 0 || die "erreur lors du log zephir";

			# on créé un fichier temporaire pour signaler l'alerte
			open (FIC_OUT, ">$fic_alerte" ) || die "impossible de créer le fichier $fic_alerte" ;
			# on stocke la date (timestamp) de l'alerte dans le fichier
			# Cette date n'est pas utilisée actuellement
			print FIC_OUT time,"\n";
		}
	}
}
else
{
	print "\n charge normale pour ",$interf, "\n";
	# on désactive l'alerte si elle existait
	if ( open (FIC_TEST, "$fic_alerte" ) )
	{
		#  on était auparavant en alerte => on annule celle-ci en supprimant le fichier temporaire
		unlink ($fic_alerte);
		# on signale la fin de l'alerte dans les logs
		system("$rep_scripts/logalerte.sh", "$interf", "fin") == 0 || die "erreur lors du log zephir";
	}
}
