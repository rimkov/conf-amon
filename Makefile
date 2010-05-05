#########################
# Makefile pour Amon-Ng #
#########################
DESTDIR=""
SRCDIR=""
EOLE_DIR=$(DESTDIR)/conf-amon/usr/share/eole
EOLE_CONF_DIR=$(EOLE_DIR)/creole
INIT_DIR=$(DESTDIR)/conf-amon/etc/init.d
SBIN_DIR=$(DESTDIR)/conf-amon/usr/sbin
BIN_DIR=$(DESTDIR)/conf-amon/usr/bin
REV_DIR=$(DESTDIR)/eole-reverseproxy
DNS_DIR=$(DESTDIR)/eole-dns
all: install

install:

	# création des répertoires (normalement fait par creole)
	mkdir -p $(EOLE_DIR)
	mkdir -p $(DESTDIR)/conf-amon/etc/sysconfig/eole
	mkdir -p $(SBIN_DIR)
	mkdir -p $(BIN_DIR)
	mkdir -p $(INIT_DIR)
	mkdir -p $(DESTDIR)/conf-amon/var/lib/blacklists/tmp
	mkdir -p $(EOLE_CONF_DIR)

	cp -rf eole/* $(EOLE_DIR)
	# copie des dictionnaires
	cp -rf dicos $(EOLE_CONF_DIR)
	# copie des templates
	cp -rf tmpl $(EOLE_CONF_DIR)/distrib
	# copie des scripts eole
	cp -f sbin/* $(SBIN_DIR)
	cp -f bin/* $(BIN_DIR)
	# copie des scripts d''init Eole ...
	cp -f init.d/* $(INIT_DIR)
	# copie fichier config
	mkdir -p $(DESTDIR)/conf-amon/etc/squid/
	cp -f config/filtres-opt $(DESTDIR)/conf-amon/etc/squid/
	#cp -f config/domaines_noauth $(DESTDIR)/conf-amon/etc/squid/
	#cp -f config/domaines_nocache $(DESTDIR)/conf-amon/etc/squid/
	cp -f config/src_noauth $(DESTDIR)/conf-amon/etc/squid/
	cp -f config/src_nocache $(DESTDIR)/conf-amon/etc/squid/
	cp -f config/disabled.srv $(DESTDIR)/conf-amon/etc/sysconfig/eole

	mkdir -p $(EOLE_DIR)/diagnose/module
	cp -f diagnose/* $(EOLE_DIR)/diagnose/module

	#reverseproxy
	mkdir -p $(REV_DIR)/etc/eole/dicos
	mkdir -p $(REV_DIR)/etc/eole/distrib
	mkdir -p $(REV_DIR)/usr/share/eole
	cp -f reverseproxy/dicos/* $(REV_DIR)/etc/eole/dicos
	cp -f reverseproxy/tmpl/* $(REV_DIR)/etc/eole/distrib
	cp -rf reverseproxy/eole/* $(REV_DIR)/usr/share/eole

	#dns
	mkdir -p $(DNS_DIR)/usr/share/eole
	cp -rf dns/eole/* $(DNS_DIR)/usr/share/eole

uninstall:

	# suppression des anciens templates
	rm -rf $(EOLE_CONF_DIR)/distrib/*
	rm -rf $(EOLE_CONF_DIR)/template/*
