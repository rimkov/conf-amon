#! /usr/bin/perl
#---------------------------------------------------------------------
#
#  Ecran Filtre pour AMON
#
# D'après blocked.cgi de  Pål Baltzersen 1998
# Luc Bourdot (08/2001)A
# $Id: filtre.cgi,v 1.1.1.1.4.2 2004/09/02 09:01:18 sam Exp $
#---------------------------------------------------------------------

$QUERY_STRING = $ENV{'QUERY_STRING'};
$DOCUMENT_ROOT = $ENV{'DOCUMENT_ROOT'};

$ban = "";
$clientaddr = "";
$clientname = "";
$etabname = "";
$clientident = "";
$srcclass = "";
$targetclass = "";
$url = "";
$time = time;
# Lecture des variables
while ($QUERY_STRING =~ /^\&?([^&=]+)=([^&=]*)(.*)/) {
  $key = $1;
  $value = $2;
  $QUERY_STRING = $3;
  if ($key =~ /^(clientaddr|clientname|clientident|srcclass|targetclass|url|etabname|ban)$/) {
    eval "\$$key = \$value";
  }
  if ($QUERY_STRING =~ /^url=(.*)/) {
    $url = $1;
    $QUERY_STRING = ""; }
}

# Mise en Page

  print "Content-type: text/html\n";
  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time);
  printf "Expires: %s, %02d-%s-%02d %02d:%02d:%02d GMT\n\n", $day[$wday],$mday,$month[$mon],$year,$hour,$min,$sec;
  print "<HTML>\n\n  <HEAD>\n    <TITLE>SITE INTERDIT</TITLE>\n  </HEAD>\n\n";
  print "  <BODY BGCOLOR=\"#FFFFCC\">\n";
  print "    <P ALIGN=RIGHT>\n";
  print "      <IMG SRC=\"http://$adresse_ip_eth2:8500/icons/Logo.gif\"\n";
  print "         BORDER=0></A>\n      </P>\n\n";
  if ( $ban eq "oui")
  {
  print "    <H3 ALIGN=CENTER>Toutes vos demandes sont enregistr&eacute;es.  Des filtres sont appliqués.<P>
                         Vous n'&ecirc;tes pas autoris&eacute &agrave; surfer !. </H3>\n\n";
		 }
	  else {
  print "    <H3 ALIGN=CENTER>Toutes vos demandes sont enregistr&eacute;es.  Des filtres sont appliqués.<P>
                         Votre demande concerne un serveur Non autoris&eacute;. </H3>\n\n";
		 }
    print "    <TABLE BORDER=0 ALIGN=CENTER>\n";
    print "      <TR><TH ALIGN=RIGHT>Etablissement:<TH ALIGN=CENTER>=<TH ALIGN=LEFT>$etabname\n";
    print "      <TR><TH ALIGN=RIGHT>Votre adresse<TH ALIGN=CENTER>=<TH ALIGN=LEFT>$clientaddr\n";
    print "      <TR><TH ALIGN=RIGHT>Identification<TH ALIGN=CENTER>=<TH ALIGN=LEFT>$clientident\n";
    print "    </TABLE>\n\n";
    print "    </P>\n\n";
 print <<__EOF__
<B>
Vous avez fait une tentative d'acc&egrave;s &agrave; un site Web qui ne pr&eacute;sente  aucun int&eacute;r&ecirc;t pour des besoins d'information p&eacute;dagogique  ou technique correspondant &agrave; votre classe d'utilisation
<P>Pour toute r&eacute;clamation, adressez un message &agrave;
       <A HREF="mailto:cachemaster\@%%nom_academie.%%suffixe_domaine_academique?subject=[plainte%20Dansguardian]%20$url">cachemaster\@%%nom_academie.%%suffixe_domaine_academique<?/A> en pr&eacute;cisant l'url :

__EOF__
;

print " $url ";
print "  </BODY>\n\n</HTML>\n";
exit 0;

