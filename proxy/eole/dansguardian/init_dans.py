#!/usr/bin/python
# -*- coding: utf-8 -*-
###########################################################################
# Eole NG - 2008
# Copyright Pole de Competence Eole  (Ministere Education - Academie Dijon)
# Licence CeCill  cf /root/LicenceEole.txt
# eole@ac-dijon.fr
#
# initialisation de dansguardian
#
###########################################################################
from amon.backend import get_zones
from amon.dansguardian import init_dans

ifaces = get_zones()[0]
init_dans.create_dansguardian_conf_files(ifaces)
