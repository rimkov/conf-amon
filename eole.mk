# 
# NE PAS EDITER CE FICHIER
#
# Utiliser <appli>.mk à inclure à la fin de Makefile

#################
# Sanity checks #
#################

ifeq (, $(DESTDIR))
$(warning $$(DESTDIR) is empty, installation will be done in /)
endif

ifeq (, $(filter-out XXX-XXX, $(strip $(SOURCE))))
$(error $$(SOURCE) variable has incorrect value '$(SOURCE)')
endif

#########################
# Variables definitions #
#########################

INSTALL                 := install
INSTALL_DATA            := install -m 644
INSTALL_PROGRAM         := install -m 755
INSTALL_DIRECTORY       := install -m 755 -d
INSTALL_RECURSIVE       := cp -dr --no-preserve=ownership

# Base
eole_DIR                := $(DESTDIR)/usr/share/eole

ifeq ($(strip $(EOLE_VERSION)), 2.3)
diagnose_PROG_DIR       := $(eole_DIR)/diagnose/module
else
diagnose_PROG_DIR       := $(eole_DIR)/diagnose/
endif

# Creole
creole_DIR              := $(eole_DIR)/creole
dicos_DATA_DIR          := $(creole_DIR)/dicos
tmpl_DATA_DIR           := $(creole_DIR)/distrib
pretemplate_PROG_DIR    := $(eole_DIR)/pretemplate
posttemplate_PROG_DIR   := $(eole_DIR)/posttemplate
postservice_PROG_DIR    := $(eole_DIR)/postservice
firewall_DATA_DIR       := $(eole_DIR)/firewall
bacula_restore_DATA_DIR := $(eole_DIR)/bacula/restore
bacula_fichier_DATA_DIR := $(DESTDIR)/etc/bacula/baculafichiers.d
schedule_pre_PROG_DIR   := $(eole_DIR)/schedule/pre
schedule_post_PROG_DIR  := $(eole_DIR)/schedule/post
extra_REC_DIR		:= $(creole_DIR)/extra

# Zéphir
zephir_DATA_DIR         := $(DESTDIR)/usr/share/zephir
zephir_configs_DATA_DIR := $(zephir_DATA_DIR)/monitor/configs
zephir_srv_DATA_DIR     := $(zephir_configs_DATA_DIR)/services

# SSO
sso_DATA_DIR            := $(DESTDIR)/usr/share/sso
sso_filtres_DATA_DIR    := $(sso_DATA_DIR)/app_filters
sso_user-info_DATA_DIR  := $(sso_DATA_DIR)/user_infos

# EAD
ead_DATA_DIR            := $(DESTDIR)/usr/share/ead2/backend/config
ead_actions_DATA_DIR    := $(ead_DATA_DIR)/actions
ead_perms_DATA_DIR      := $(ead_DATA_DIR)/perms
ead_roles_DATA_DIR      := $(ead_DATA_DIR)/roles

# Program libraries goes under /usr/lib/<PROGRAM>/
lib_$(SOURCE)_DATA_DIR	:= $(DESTDIR)/usr/lib/$(SOURCE)

# Scripts Eole
scripts_PROG_DIR        := $(eole_DIR)/sbin
lib_eole_DATA_DIR	:= $(DESTDIR)/usr/lib/eole

# LDAP
ldap_passwords_DATA_DIR := $(eole_DIR)/annuaire/password_files

# LXC
lxc_DATA_DIR            := $(eole_DIR)/lxc
lxc_fstab_DATA_DIR      := $(lxc_DATA_DIR)/fstab
lxc_hosts_DATA_DIR	:= $(lxc_DATA_DIR)/hosts

# SQL
sql_DATA_DIR            := $(eole_DIR)/mysql/$(SOURCE)
sql_gen_DATA_DIR        := $(sql_DATA_DIR)/gen
sql_updates_DATA_DIR    := $(sql_DATA_DIR)/updates

sql_conf_gen_DATA_DIR		:= $(eole_DIR)/applications/gen
sql_conf_passwords_DATA_DIR	:= $(eole_DIR)/applications/passwords
sql_conf_updates_DATA_DIR	:= $(eole_DIR)/applications/updates/$(SOURCE)

# Certifs
certs_DATA_DIR		:= $(eole_DIR)/certs

# Logrotate
logrotate_DATA_DIR      := $(DESTDIR)/etc/logrotate.d


# Python modules
ifneq ($(DESTDIR),)
PYTHON_OPTS     := --root $(DESTDIR)
endif

#############################################
# Common directories and files installation #
#############################################

all:

install:: install-dirs install-files

# $1 = command to run
# $2 = source directory
# $3 = destination directory
define fc_install_file  
	if [ -d $2 ]; then					\
		for file in `ls -1 $2/`; do			\
		   $1 $2/$$file $3 || true;			\
	    done;						\
	fi
endef

##
## Directory creation
##

# use % to catch local name in $*
# data, program and recursive directory require a corresponding
# directory in local sources
%_DATA_DIR %_PROG_DIR %REC_DIR:
	test ! -d $(subst _,/,$*) || $(INSTALL_DIRECTORY) $($@)

# Create the directory referenced by the variable without a local one.
%_DIR:
	$(INSTALL_DIRECTORY) $($@)

##
## Install files present directly under data, program and recursive directories
##

# $*   : name of variable
# $($*): value of variable 
%-instdata:
	$(call fc_install_file, $(INSTALL_DATA), $(subst _,/,$(subst _DATA_DIR,,$*)), $($*))

%-instprog:
	$(call fc_install_file, $(INSTALL_PROGRAM), $(subst _,/,$(subst _PROG_DIR,,$*)), $($*))

%-instrec:
	$(call fc_install_file, $(INSTALL_RECURSIVE), $(subst _,/,$(subst _REC_DIR,,$*)), $($*))


# Use second expansion as variables may be created in included
# Makefiles
.SECONDEXPANSION:

# List of all directories
installdirs_LIST	= $(foreach V, $(filter %_DIR, $(.VARIABLES)),	\
				$(if $(filter file, $(origin $(V))),	\
					$(V)))
# List of data directories
installdata_LIST	= $(filter %_DATA_DIR, $(installdirs_LIST))
# List of program directories
installprog_LIST	= $(filter %_PROG_DIR, $(installdirs_LIST))
# List of recursive directories
installrec_LIST	 	= $(filter %_REC_DIR, $(installdirs_LIST))

# Expand directories to create as dependency
# Use double-colon to permit user to define additionnal install-dirs
install-dirs:: $$(installdirs_LIST)

# Expand files to install as dependency
# Use double-colon to permit user to define additionnal install-files
install-files:: install-data-files install-prog-files install-rec-dirs

install-data-files: $$(patsubst %,%-instdata,$$(installdata_LIST))

install-prog-files: $$(patsubst %,%-instprog,$$(installprog_LIST))

install-rec-dirs:   $$(patsubst %,%-instrec,$$(installrec_LIST))

# Installation of python modules
ifeq ($(shell test -f setup.py && echo 0), 0)
install-files::
	python setup.py install --no-compile --install-layout=deb $(PYTHON_OPTS)
endif

.PHONY: install install-dirs install-files install-data-files install-prog-files install-rec-dirs
