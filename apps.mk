# 
# NE PAS EDITER CE FICHIER
#
# Utiliser <appli>.mk à inclure à la fin de Makefile

# Le variables suivantes sont a votre disposition : 
#
# SRC_APPS        : Répertoire des sources de l'application
# SRC_APPS_PLUGIN : Répertoires des plugins pour l'application
# SRC_APPS_LANG   : Répértoires des traductions
#

##########################
# Application web envole #
##########################
ifneq (, $(filter oui web, $(PKGAPPS)))
# Envole
sharenvole_PROG_DIR	:= $(DESTDIR)/usr/share/envole/$(SOURCE)

SRC_APPS		:= src/$(SOURCE)-$(VERSION)
SRC_APPS_PLUGIN		:= src/plugins-$(VERSION)
SRC_APPS_LANG		:= src/lang-$(VERSION)

APPS_DEST		:= $(DESTDIR)/var/www/html/$(SOURCE)
LANG_DEST		:= $(APPS_DEST)/lang
PLUGIN_DEST		:= $(APPS_DEST)/plugin

# Sanity check
ifeq (, $(filter-out X.X, $(strip $(VERSION))))
$(error $$(VERSION) variable has incorrect value '$(VERSION)')
endif

ifeq (, $(strip $(wildcard $(SRC_APPS))))
$(error $$(PKGAPPS) is enable but $$(SRC_APPS)='$(SRC_APPS)' does not exist)
endif

endif

##########################
# Application EOLE flask #
##########################
ifneq (, $(filter flask, $(PKGAPPS)))
# Sanity check
ifeq (, $(filter-out XXX, $(strip $(FLASK_MODULE))))
$(error $$(FLASK_MODULE) variable has incorrect value '$(FLASK_MODULE)')
endif

ifeq (, $(strip $(wildcard src/$(FLASK_MODULE).conf)))
$(error missing eoleflask configuration file 'src/$(FLASK_MODULE).conf')
endif

# Static files
SRC_APPS	:= src/$(FLASK_MODULE)/static
APPS_MOUNT_POINT:= $(shell sed -ne 's|^"MOUNT_POINT"[[:space:]]*:[[:space:]]*"/\([^"]*\)",|\1|p' \
	src/$(FLASK_MODULE).conf)
APPS_DEST	:= $(DESTDIR)/usr/share/eole/flask/$(APPS_MOUNT_POINT)/static

SRC_APPS_PLUGIN	:= nonexistent
SRC_APPS_LANG	:= nonexistent

# eole-flask configuration
src_DATA_DIR	:= $(DESTDIR)/etc/eole/flask/available
endif


################
# Common rules #
################
ifneq (, $(filter oui web flask, $(PKGAPPS)))

install-apps-dirs::
	test ! -d $(SRC_APPS)           || $(INSTALL_DIRECTORY) $(APPS_DEST)
	test ! -d $(SRC_APPS_LANG)      || $(INSTALL_DIRECTORY) $(LANG_DEST)
	test ! -d $(SRC_APPS_PLUGIN)    || $(INSTALL_DIRECTORY) $(PLUGIN_DEST)

install-apps:: install-apps-dirs
	# Installation de l'application
	$(call fc_install_file,$(INSTALL_RECURSIVE),$(SRC_APPS),$(APPS_DEST))

	# Installation des répertoires de plugins
	$(call fc_install_file,$(INSTALL_RECURSIVE),$(SRC_APPS_PLUGIN),$(PLUGIN_DEST))

	# Installation des répertoires de traductions (lang)
	$(call fc_install_file,$(INSTALL_RECURSIVE),$(SRC_APPS_LANG),$(LANG_DEST))

## Add install-apps
install:: install-apps
endif

.PHONY: install-apps install-apps-dirs
