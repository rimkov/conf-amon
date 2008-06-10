#!/usr/bin/perl 

###############################################################
# script de d�tection des alertes sur les bases de donn�es rrd
# (charge r�seau)
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
			

# A chaque appel du script, la base de donn�es et le seuil limite sont pass�s en param�tre
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
	print STDERR "\n*** Erreur : Sp�cifiez l'interface r�seau\n             (eth0,eth1,...,squid)\n";
	exit 0;
}

if( $opt_s )
{
	$seuil = $opt_s;
}
unless( $opt_s )
{
	print STDERR $help;
	print STDERR "\n*** Erreur : Sp�cifiez le seuil de surcharge\n";
	exit 0;
}	


# print "\n arguments: ", $interf, " - ", $seuil, ".\n";

# on r�cup�re la moyenne sur les 5 derni�res minutes (derni�res valeurs enregistr�es)
my ($start,$step,$names,$data) = RRDs::fetch ("$rep_bas_rrd/".$interf.".rrd", "--start=-900", "AVERAGE");


# test des valeurs r�cuper�es
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
			# cas sp�cial : cas de la charge cpu/m�moire squid
			# ici, les 2 valeurs ont des �chelles diff�rentes
			#                         
			# on ram�ne la valeur de la m�moire � un pourcentage
			# pour avoir le m�me seuil que pour le cpu
			#
			# on r�cup�re la taille m�moire
		
			my $mem_physique = `cat /proc/meminfo | grep MemTotal: |mawk -F " " '{print $2}'`;
			# on passe la valeur de Koctets � octets
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
	# v�rification de la dur�e de la surcharge	
	# on v�rifie la moyenne de charge sur les 20 derni�res minutes
	# si elle est sup�rieure ou �gale au seuil -> alerte visuelle
	# les donn�es retourn�es par rrdool �tant altern�es en entr�e/sortie,
	# on utilise un flag pair/impair pour pouvoir les diff�rencier
	
	# calcul de la moyenne
	# on ajoute les 4 derni�res moyennes (sur 5 minutes)
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
	# puis, on divise le tout par quatre pour obtenir la moyenne sur les 20 derni�res minutes
	# (les valeurs �tant en octets/s, on divise par 1000 pour obtenir des Ko/s)
	$input = $input/4;
	$output = $output/4;
	printf "\n Moyennes sur les 20 derni�res minutes \n -- Entr�e : %6.1f Ko/s \n -- Sortie : %6.1f Ko/s \n\n", ($input/1000), ($output/1000);

	# Si la moyenne sur 20 minutes d�passe le seuil et qu'il n'existe pas encore de fichier d'alerte :
	# on remonte l'alerte
	
	if ( ($input > $seuil) || ($output > $seuil) )
	{
		# � moins que l'alerte soit d�j� d�clar�e
		unless ( open (FIC_TEST, "$fic_alerte" ) )
		{
			# appel du script permettant la remont�e de l'alerte dans les logs (Zephir)
			system("$rep_scripts/logalerte.sh", "$interf", "d�but") == 0 || die "erreur lors du log zephir";

			# on cr�� un fichier temporaire pour signaler l'alerte
			open (FIC_OUT, ">$fic_alerte" ) || die "impossible de cr�er le fichier $fic_alerte" ;
			# on stocke la date (timestamp) de l'alerte dans le fichier
			# Cette date n'est pas utilis�e actuellement
			print FIC_OUT time,"\n";
		}
	}
}
else
{
	print "\n charge normale pour ",$interf, "\n";
	# on d�sactive l'alerte si elle existait
	if ( open (FIC_TEST, "$fic_alerte" ) )
	{
		#  on �tait auparavant en alerte => on annule celle-ci en supprimant le fichier temporaire
		unlink ($fic_alerte);
		# on signale la fin de l'alerte dans les logs
		system("$rep_scripts/logalerte.sh", "$interf", "fin") == 0 || die "erreur lors du log zephir";
	}
}
