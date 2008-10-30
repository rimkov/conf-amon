#########################
# Makefile pour Amon-Ng #
#########################
DESTDIR=""
SRCDIR=""
EOLE_CONF_DIR=$(DESTDIR)/etc/eole
EOLE_DIR=$(DESTDIR)/usr/share/eole
INIT_DIR=$(DESTDIR)/etc/init.d
SBIN_DIR=$(DESTDIR)/usr/sbin
BIN_DIR=$(DESTDIR)/usr/bin
all: install

install: 

	# création des répertoires (normalement fait par creole)
	mkdir -p $(EOLE_DIR)
	mkdir -p $(EOLE_CONF_DIR)/dicos/local
	mkdir -p $(EOLE_CONF_DIR)/dicos/variante
	mkdir -p $(EOLE_CONF_DIR)/distrib
	mkdir -p $(EOLE_CONF_DIR)/modif
	mkdir -p $(EOLE_CONF_DIR)/patch/variante
	mkdir -p $(EOLE_CONF_DIR)/template
	mkdir -p $(DESTDIR)/etc/sysconfig/eole
	mkdir -p $(SBIN_DIR)
	mkdir -p $(BIN_DIR)
	mkdir -p $(INIT_DIR)
	mkdir -p $(DESTDIR)/var/lib/blacklists/tmp

	# fichier d'identification du module
	cp -f version $(EOLE_CONF_DIR)

	# copie des dictionnaires
	cp -rf dicos/* $(EOLE_CONF_DIR)/dicos/
	# copie des templates
	cp -f tmpl/* $(EOLE_CONF_DIR)/distrib
	# copie des scripts eole
	cp -rf eole/* $(EOLE_DIR)
	cp -f sbin/* $(SBIN_DIR)
	cp -f bin/* $(BIN_DIR)
	# copie des scripts d''init Eole ...
	cp -f init.d/* $(INIT_DIR)
	# copie fichier config
	mkdir -p $(DESTDIR)/etc/squid/
	cp -f config/filtres-opt $(DESTDIR)/etc/squid/
	cp -f config/domaines_noauth $(DESTDIR)/etc/squid/
	cp -f config/domaines_nocache $(DESTDIR)/etc/squid/
	cp -f config/src_noauth $(DESTDIR)/etc/squid/
	cp -f config/src_nocache $(DESTDIR)/etc/squid/
	cp -f config/disabled.srv $(DESTDIR)/etc/sysconfig/eole

	mkdir -p $(EOLE_DIR)/diagnose/module
	cp -f diagnose/* $(EOLE_DIR)/diagnose/module

uninstall:

	# suppression des anciens templates
	rm -rf $(EOLE_CONF_DIR)/distrib/*
	rm -rf $(EOLE_CONF_DIR)/template/*
