#!/usr/bin/env python
# -*- coding: UTF-8 -*-
"""

Utilitaire magic_rvp


%prog [options]

- parse la sortie de la commande eroute
- récupère le rightsubnet et le left_subnet
- parse le ipsec.conf
- trouve la connexion correspondante dans le ipsec.conf

return codes :

- 0 si aucune action n'a été effectuée
- 1 si un ``/etc/init.d/rvp restart`` a été effectué
- 2 si une exception a été levée
- 3 si un tunnel a été relancé

"""

__version__ = "1.0"

## début de la section de configuration

# mode debug
debug = False

# mode verbose
verbose = False

# fichier de conf ipsec
# ipsec_conf = './ipsec.conf'
ipsec_conf = '/etc/freeswan/ipsec.conf'

# la commande eroute
eroute_command = "ipsec status"

# la command de redémarrage du tunnel
tunnel_restart = """ipsec auto --down %s >/dev/null 2>&1
ipsec auto --up %s >/dev/null 2>&1"""

# l'exécutable test-rvp
test_rvp = "/usr/share/eole/test-rvp"

## fin de la section de configuration (please do not modify after this point)

import commands
import os
import sys
import time
import traceback
import re
from optparse import OptionParser

return_code = 0

# ---- sortie ipsec eroute ----
ip_regexp = "\d+\.\d+\.\d+\.\d+"

def exec_status():
    """
    execute la commande ipsec eroute et récupère sa sortie
    @return : les right subnet et les left subnet
    [(left, right), ...]
    """

    if verbose :
        print eroute_command
    output = commands.getoutput(eroute_command)
    lines = output.split('\n')

    # constrution de la liste des subnet
    subnets = []
    if lines <> ['']:
        for line in lines:
            if '---' in line and not line[4:].startswith('#'):
                if 'erouted' not in line:
                    # récupération des adresses des subnets
                    ips = re.findall(ip_regexp, line)
                    subnets.append((ips[0], ips[-1]))

    return subnets

# ---- ipsec.conf ----

def _parse_connexions(filename):
    """
    parse le fichier de conf ipsec.conf
    @param filename: ipsec.conf
    """
    # parsing du fichier
    fh = file(filename, 'r')
    content = fh.read()
    fh.close()
    # récupère les sections de connexion
    # remarque : les '#DEB' et les '#FIN' ne sont pas pris en compte
    connexions = content.split("conn ")
    # retire la conf par défaut
    return connexions[2:]

def get_subnets(filename):
    """
    dictionnaire subnets:connexion

    @param filename: fichier ipsec.conf
    @return: le left subnet et le right subnet pour une connexion
    {connexion:(lef,right), ... }
    """
    connexions = _parse_connexions(filename)
    subnets = {}
    for conn in connexions:
        # lignes de la section de connexion
        lines = conn.split()
        conn_name = lines[0].strip()
        for line in lines:
            if 'rightsubnet' in line:
                right = _get_subnet(line)
            if 'leftsubnet' in line:
                left = _get_subnet(line)
        # on ajoute le subnet à la liste
        subnets[(left,right)]=conn_name
    return subnets

def _get_subnet(line):
    """
    @param line : la ligne comprenant le subnet :

    rightsubnet=172.30.107.240/255.255.255.240
    @return: le subnet (par exemple : 172.30.107.240)
    """
    # ce qui est à droite de l'égalité
    ip_network = line.split('=')[1]
    # ce qui est à gauche du / (l'ip, donc)
    ip = ip_network.split('/')[0]
    return ip

def find_connexions():
    """
    - exécute ipsec eroute
    - parse ipsec.conf
    @return: les connexions matchées par eroute
    """
    # les subnets apparus dans eroute
    if verbose : print "execution ipsec eroute"
    subnets = exec_status()
    # les connexions présentes dans la conf
    subnets_conn = get_subnets(ipsec_conf)

    connexions = []
    for subnet in subnets:

        if subnet not in subnets_conn.keys():
            raise Exception, "attention, un des subnets n'a pas ete trouve dans le fichier ipsec.conf"
        else:
            # ajoute la connexion trouvée
            connexions.append(subnets_conn[subnet])

    return connexions


# ---- test-rvp ----

def _parse_test_rvp(filename):
    """
    lit dans le fichier test_rvp  les ip de la patte interne du sphynx
    correspondant aux connexions, et execute la commande fping
    @return: liste [(connexion, fping)]
    """
    # contenu du fichier
    fh = file(filename, 'r')
    content = fh.readlines()
    fh.close()
    result = []
    for line in content:
        if 'fping' in line:
            fping = line.strip()
            result.append(fping)
    return result

def restart_tunnels(connexions):
    """
    relance le tunnel au cas où il serait tombé
    @param connexions: les connexions qui sont par terre
    """
    for conn in connexions:
        if not debug:
            os.system( tunnel_restart % (conn, conn) )
	    global return_code
            return_code = 3
            if verbose:
                print tunnel_restart % (conn, conn)

        if debug:
            print tunnel_restart % (conn, conn)

def restart_unreachable():
    """
    relance les tunnels qui ne peuvent pas être pingés
    si c'est 'unreachable', on lance un /etc/init.d/rvp restart
    """
    fpings = _parse_test_rvp(test_rvp)
    unreachable_flag = False

    for fping in fpings:
        # exécutons le fping
        ping_output = commands.getoutput(fping)
        # parsons la sortie du ping
        if 'unreachable' in ping_output.lower():
            unreachable_flag = True
        if verbose : print fping
    if unreachable_flag:
        if verbose : print "redemarrage du RVP"
        os.system('/etc/init.d/rvp restart >/dev/null 2>&1')
	global return_code
        return_code = 1

## parsing de la ligne de commande

def parse_command_line():
    parser = OptionParser(__doc__, version='%%prog version %s' % __version__)
    parser.add_option('-v', '--verbose', action='store_true', dest='verbose',
                      help='mode verbose', default=False,
                      metavar='VERBOSE_MODE')
    parser.add_option('-d', '--debug', action='store_true', dest='debug',
                      help='mode debug', default=False,
                      metavar='DEBUG_MODE')

    options, args = parser.parse_args()
    if len(args) >= 1:
        parser.error("le script ne prend pas d'argument")

    return options, args


def main():
    options, args = parse_command_line()
    global verbose
    global debug
    if options.verbose:
        verbose=True
    if options.debug: debug=True

    try:
        # connexion qui posent problème d'après le eroute
        if verbose : print "recherche des connexions ..."
        connexions = find_connexions()
        # redémarrons le tunnel pour ces connexions
        restart_unreachable()
        time.sleep(3)
        if verbose and connexions : print "redemarrage des tunnels tombes..."
        restart_tunnels(connexions)

    except Exception, e:
        if debug:
            print e.__class__, e
            traceback.print_exc()
        print "une erreur est survenue"
        sys.exit(2)
    sys.exit(return_code)

def test():
    print parse_test_rvp(test_rvp)

if __name__ == '__main__':
    main()
