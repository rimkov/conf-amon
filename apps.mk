# 
# NE PAS EDITER CE FICHIER
#
# Voir Makefile


##########################
# Application web envole #
##########################
ifneq (, $(filter oui web, $(PKGAPPS)))
#
# Sanity check
#
ifeq (, $(filter-out X.X, $(strip $(VERSION))))
$(error $$(VERSION) variable has incorrect value '$(VERSION)')
endif

# Where to store web application files
WEB_PATH				:= $(DESTDIR)/var/www/html

# Envole
sharenvole_PROG_DIR			:= $(DESTDIR)/usr/share/envole/$(SOURCE)

src_$(SOURCE)-$(VERSION)_REC_DIR	:= $(WEB_PATH)/$(SOURCE)
src_plugins-$(VERSION)_REC_DIR		:= $(WEB_PATH)/$(SOURCE)/plugin
src_lang-$(VERSION)_REC_DIR		:= $(WEB_PATH)/$(SOURCE)/lang

endif

##########################
# Application EOLE flask #
##########################
ifneq (, $(filter flask, $(PKGAPPS)))
#
# Sanity check
#
ifeq (, $(filter-out XXX, $(strip $(FLASK_MODULE))))
$(error $$(FLASK_MODULE) variable has incorrect value '$(FLASK_MODULE)')
endif

ifeq (, $(strip $(wildcard src/$(FLASK_MODULE).conf)))
$(error missing eoleflask configuration file 'src/$(FLASK_MODULE).conf')
endif

# Everything is related to mount point
APPS_MOUNT_POINT	:= $(shell sed -ne 's|^"MOUNT_POINT"[[:space:]]*:[[:space:]]*"/\([^"]*\)",|\1|p' \
	src/$(FLASK_MODULE).conf)

ifeq (, $(strip $(APPS_MOUNT_POINT)))
$(error no "MOUNT_POINT" in eoleflask configuration file 'src/$(FLASK_MODULE).conf')
endif

# eole-flask configuration
src_DATA_DIR		:= $(DESTDIR)/etc/eole/flask/available

# Where to store flask application files
FLASK_PATH		:= $(eole_DIR)/flask/$(APPS_MOUNT_POINT)

# static files
src_$(FLASK_MODULE)_static_REC_DIR	:= $(FLASK_PATH)/static
src_$(FLASK_MODULE)_templates_REC_DIR	:= $(FLASK_PATH)/templates
src_$(FLASK_MODULE)_instance_REC_DIR	:= $(FLASK_PATH)/resources

endif
