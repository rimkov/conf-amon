#!/usr/bin/perl
#
use strict ;
#
BEGIN {

  push @INC , '.';  

}

#    Conception :
#    Eole (http://eole.orion.education.fr)
#    Copyright (C) 2002

#    Ce code a été développé par
#    Gwenaël Rémond (gwenael.remond@free.fr)
#    Luc Bourdot (luc.bourdot@ac-dijon.fr)
#    Samuel Morin (samuel.morin@ac-dijon.fr)

#    distribué sous la licence GPL-2 

#    Version $Revision: 1.1.1.1 $

#    En attendant une traduction officielle de la GPL, la notice de 
#    copyright demeure en anglais.

#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#    $Id: classe_ip.pl,v 1.1.1.1 2004/01/05 10:16:50 eole Exp $
#    $Source: /home/cvs/amon/conf-amon/classe_ip.pl,v $


#    Se reporter à la documentation envoyée avec le programme pour la notice.
#    Si elle manquait, envoyer un email à Gwenaël Rémond (gwenael.remond@free.fr)
#    Luc Bourdot (luc.bourdot@ac-dijon.fr)
#    Samuel Morin (samuel.morin@ac-dijon.fr)


# présentation du programme




=pod

=head1 NOM



classe_ip.pl



=cut




=pod

=head1 DESCRIPTION


Convertisseur de netmask (valeur décimale) en valeur CIDR


=cut




=pod

=head1 SYNOPSIS



tapez ./classe_ip.pl -h 



=cut




# fin présentation du programme
# déclaration des prérequis

=pod

=head1 PREREQUIS



=pod

=over 

=cut



=pod

=item I<Getopt::Std>

=cut

use Getopt::Std ;



=pod

=back



=cut



# # fin déclaration des prérequis
# # déclaration des variables utilisées

=pod

=head1 VARIABLES GLOBALES




=cut



=pod

=over 

=cut




=pod


=item I<$opt_h>

Affichage de l'aide

=cut

our $opt_h ;



=pod


=item I<$opt_i>

Initalisation du sphynx

=cut

our $opt_i ;



=pod


=item I<$opt_d>

Ajoute un établissement

=cut

our $opt_d ;



=pod


=item I<$opt_o>

Sortie vers un fichier de configuration

=cut

our $opt_o ;



=pod


=item I<$dico>

fichier dictionnaire

=cut

our $dico ;



=pod


=item I<$spcl>

fichier entrée

=cut

our $spcl ;



=pod


=item I<$spcl_out>

fichier sortie

=cut

our $spcl_out ;




=pod

=back

=cut




=pod

=head1 VARIABLES LOCALES




=cut



=pod

=over 

=cut





=pod

=back

=cut

# fin déclaration des variables

#####################################################
# utilitaire ligne de commande 
#####################################################

# Le message d'aide par défaut.

my $help = "\n";
$help .= "    -h : affiche ce message d'aide.\n";
$help .= "    -i : entree - fichier spcl decimal - (-i <nom_fichier>).\n";
$help .= "    -o : sortie - fichier spcl converti - (-o <nom_fichier>).\n";
$help .= "    -d : fichier dictionnaire (-d <nom_fichier>).\n";
$help .= "\n";

# Nous lisons la liste des options

# parsing validant des options ligne de commande

unless ( getopts( 'i:d:o:h' ) )
{

    print STDERR $help;
    exit 0;

}

# en cas d'inexistence d'au moins une option de ligne de commande, afficher l'aide

unless ( $opt_i || $opt_o || $opt_d || $opt_h )
{

    print STDERR $help;
    exit 0;

}

# -h : affichage de l'aide

if ( $opt_h ) 
{

    print STDERR $help;
    exit 0;

}

if ( $opt_d ) 
{

 $dico = $opt_d ;

}

if ( $opt_i )  
{

 $spcl = $opt_i ;

}

if ( $opt_o ) 
{

 $spcl_out = $opt_o ;

}

#####################################################
# recuperation des noms de variable
#####################################################

# tableau des noms de variable presents dans le fichier spcl
my @variable = () ; 

open ( SP, "$spcl" ) || die "impossible d'ouvrir un fichier : $!" ;

while ( $_ = <SP> ) {

    chomp ( $_ ) ;

    # nous regardons s'il y a une variable de type netmask dans la ligne
     if ( $_ =~ m/adresse_netmask/ )  {

       my  @decoupe = split( /adresse_netmask/, $_ ) ;    
       # nous reperons la deuxieme partie de la variable
       my $decoupe = @decoupe[1] ;
       # nous recuperons la suite du nom sans les pourcentages
       @decoupe = split ( /%%/ , $decoupe ) ;

       $decoupe = @decoupe[0] ;
       # nous reconstituons le noms de variable 
       push ( @variable , $decoupe ) ;


      }
 
}

close ( SP ) ;

# print Dumper( @variable ) ;
# 

#####################################################
# recuperation des valeurs des variables
#####################################################

my %netmask = () ;

foreach my $item ( @variable ) {

    my $nom_variable = "adresse_netmask".$item ;

    open ( DICO , "$dico") || die "impossible d'ouvrir un fichier : $!" ;
    
    while ( <DICO> ) {
        
        chomp ; 
        
	if ( $_ =~ m/^$nom_variable/ )  {

	    my  @decoupe = split( /@@/ , $_ ) ;    

	    # nous recuperons la valeur de la variable 
	    @decoupe = split ( /\#/ , @decoupe[1] ) ;

	    # nous construisons le hash de donnees
	    $netmask{$nom_variable} = $decoupe[0] ;
	}    

    }

    close ( DICO ) ;
}
# print Dumper ( %netmask ) ; 

#####################################################
# conversion des valeurs decimales 
#####################################################

my %conversion = (
    '128.0.0.0' => '1'
    , '192.0.0.0' => '2'
    , '224.0.0.0' => '3'
    , '240.0.0.0' => '4'
    , '248.0.0.0' => '5'
    , '252.0.0.0' => '6'
    , '254.0.0.0' => '7'
    , '255.0.0.0' => '8'
    , '255.128.0.0' => '9'
    , '255.192.0.0' => '10'
    , '255.224.0.0' => '11'
    , '255.240.0.0' => '12'
    , '255.248.0.0' => '13'
    , '255.252.0.0' => '14'
    , '255.254.0.0' => '15'
    , '255.255.0.0' => '16'
    , '255.255.128.0' => '17'
    , '255.255.192.0' => '18'
    , '255.255.224.0' => '19'
    , '255.255.240.0' => '20'
    , '255.255.248.0' => '21'
    , '255.255.252.0' => '22'
    , '255.255.254.0' => '23'
    , '255.255.255.0' => '24'
    , '255.255.255.128' => '25'
    , '255.255.255.192' => '26'
    , '255.255.255.224' => '27'
    , '255.255.255.240' => '28'
    , '255.255.255.248' => '29'
    , '255.255.255.252' => '30'
    , '255.255.255.254' => '31'
    , '255.255.255.255' => '32'
	       ) ;
# hash de mise en bijection 
my %netmask_cidr = () ;

foreach my $item ( keys ( %netmask ) ) {

    $netmask_cidr{ $item } = $conversion{ $netmask{ $item } } ;

}

# print Dumper ( %netmask_cidr ) ;

#####################################################
# insertion des classes ip dans le fichier spcl
#####################################################

# nouveau nom de fichier 
# my $spcl_out = $spcl.".modif_classe_ip" ;

# le fichier spcl est pousse dans une variable ;
my $fichier ;

open ( SP, "$spcl" ) || die "impossible d'ouvir un fichier : $!" ;
while ( my $ligne = <SP> )  
{

    $fichier .= $ligne ;

}

close ( SP ) ;

# print $fichier ;


    foreach my $item ( keys ( %netmask_cidr ) ) {

	if ( $fichier =~ m/$item/ ) {

	    $fichier =~ s/%%($item)%%/$netmask_cidr{ $item }/g ;

	}
    
    }

# ecriture dans le fichier de sortie

open ( SPOUT, ">$spcl_out" ) || die "impossible d'ouvir un fichier : $!" ;

print SPOUT $fichier ;

close ( SPOUT ) ; 




=pod

=head1 VOIR AUSSI


Pour toute information complémentaire, veuillez vous rendre
sur le site du Projet classe_ip à l'adresse suivante : 

TODO 

Reportez-vous aussi s'il vous plaît au site générique du projet Eole :

http://eole.orion.education.fr



=cut







