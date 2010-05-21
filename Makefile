#########################
# Makefile pour Amon-Ng #
#########################
DESTDIR=""
SRCDIR=""
EOLE_DIR=/usr/share/eole
EOLE_CONF_DIR=$(EOLE_DIR)/creole
INIT_DIR=/etc/init.d
SBIN_DIR=/usr/sbin
BIN_DIR=/usr/bin
#REP de creation des differents paquets
CONFAMON_DIR=$(DESTDIR)/conf-amon
REV_DIR=$(DESTDIR)/eole-reverseproxy
DNS_DIR=$(DESTDIR)/eole-dns
NUAUTH_DIR=$(DESTDIR)/eole-nuauth
RADIUS_DIR=$(DESTDIR)/eole-radius
PROXY_DIR=$(DESTDIR)/eole-proxy

all: install

install:

	# création des répertoires (normalement fait par creole)
	mkdir -p $(CONFAMON_DIR)/$(EOLE_DIR)
	mkdir -p $(CONFAMON_DIR)/$(SBIN_DIR)
	mkdir -p $(CONFAMON_DIR)/$(BIN_DIR)
	mkdir -p $(CONFAMON_DIR)/$(INIT_DIR)
	mkdir -p $(CONFAMON_DIR)/var/lib/blacklists/tmp
	mkdir -p $(CONFAMON_DIR)/$(EOLE_CONF_DIR)

	cp -rf eole/* $(CONFAMON_DIR)/$(EOLE_DIR)
	# copie des dictionnaires
	cp -rf dicos $(CONFAMON_DIR)/$(EOLE_CONF_DIR)
	# copie des templates
	cp -rf tmpl $(CONFAMON_DIR)/$(EOLE_CONF_DIR)/distrib
	# copie des scripts eole
	cp -f sbin/* $(CONFAMON_DIR)/$(SBIN_DIR)
	cp -f bin/* $(CONFAMON_DIR)/$(BIN_DIR)
	# copie des scripts d''init Eole ...
	cp -f init.d/* $(CONFAMON_DIR)/$(INIT_DIR)
	# copie fichier config
	mkdir -p $(CONFAMON_DIR)/etc/squid/
	cp -f config/filtres-opt $(CONFAMON_DIR)/etc/squid/
	#cp -f config/domaines_noauth $(DESTDIR)/conf-amon/etc/squid/
	#cp -f config/domaines_nocache $(DESTDIR)/conf-amon/etc/squid/
	cp -f config/src_noauth $(CONFAMON_DIR)/etc/squid/
	cp -f config/src_nocache $(CONFAMON_DIR)/etc/squid/

	mkdir -p $(CONFAMON_DIR)/$(EOLE_DIR)/diagnose/module
	cp -f diagnose/* $(CONFAMON_DIR)/$(EOLE_DIR)/diagnose/module

	#reverseproxy
	mkdir -p $(REV_DIR)/$(EOLE_CONF_DIR)
	cp -rf reverseproxy/eole/* $(REV_DIR)/$(EOLE_DIR)
	cp -rf reverseproxy/dicos $(REV_DIR)/$(EOLE_CONF_DIR)/dicos
	cp -rf reverseproxy/tmpl $(REV_DIR)/$(EOLE_CONF_DIR)/distrib

	#dns
	mkdir -p $(DNS_DIR)/$(EOLE_CONF_DIR)
	cp -rf dns/eole/* $(DNS_DIR)/$(EOLE_DIR)
	cp -rf dns/dicos $(DNS_DIR)/$(EOLE_CONF_DIR)/dicos
	cp -rf dns/tmpl $(DNS_DIR)/$(EOLE_CONF_DIR)/distrib

	#nuauth
	mkdir -p $(NUAUTH_DIR)/$(EOLE_CONF_DIR)
	cp -rf nuauth/dicos $(NUAUTH_DIR)/$(EOLE_CONF_DIR)/dicos
	cp -rf nuauth/tmpl $(NUAUTH_DIR)/$(EOLE_CONF_DIR)/distrib

	#radius
	mkdir -p $(RADIUS_DIR)/$(EOLE_CONF_DIR)
	cp -rf radius/dicos $(RADIUS_DIR)/$(EOLE_CONF_DIR)/dicos
	cp -rf radius/tmpl $(RADIUS_DIR)/$(EOLE_CONF_DIR)/distrib
	
	#proxy
	mkdir -p $(PROXY_DIR)/$(EOLE_CONF_DIR)
	mkdir -p $(PROXY_DIR)/var/lib/blacklists
	cp -rf proxy/eole/* $(PROXY_DIR)/$(EOLE_DIR)
	cp -rf proxy/dicos $(PROXY_DIR)/$(EOLE_CONF_DIR)/dicos
	cp -rf proxy/tmpl $(PROXY_DIR)/$(EOLE_CONF_DIR)/distrib
	cp -rf proxy/blacklists/* $(PROXY_DIR)/var/lib/blacklists

uninstall:

	# suppression des anciens templates
	rm -rf $(EOLE_CONF_DIR)/distrib/*
	rm -rf $(EOLE_CONF_DIR)/template/*
