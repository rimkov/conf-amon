#########################
# Makefile pour Amon-Ng #
#########################
DESTDIR=""
SRCDIR=""
EOLE_DIR=/usr/share/eole
EOLE_CONF_DIR=$(EOLE_DIR)/creole
AGENT_DIR=/usr/share/zephir/monitor/configs
EAD_DIR=/usr/share/ead2/backend/config
INIT_DIR=/etc/init.d
#SBIN_DIR=/usr/sbin
BIN_DIR=/usr/bin
#REP de creation des differents paquets
CONFAMON_DIR=$(DESTDIR)/conf-amon
REV_DIR=$(DESTDIR)/eole-reverseproxy
DNS_DIR=$(DESTDIR)/eole-dns
NUAUTH_DIR=$(DESTDIR)/eole-nuauth
RADIUS_DIR=$(DESTDIR)/eole-radius
PROXY_DIR=$(DESTDIR)/eole-proxy
RVP_DIR=$(DESTDIR)/eole-rvp
DHCRELAY_DIR=$(DESTDIR)/eole-dhcrelay

all: install

install:

	#conf-amon
	mkdir -p $(CONFAMON_DIR)/$(EOLE_DIR)
	mkdir -p $(CONFAMON_DIR)/$(SBIN_DIR)
	mkdir -p $(CONFAMON_DIR)/$(BIN_DIR)
	mkdir -p $(CONFAMON_DIR)/$(INIT_DIR)
	mkdir -p $(CONFAMON_DIR)/$(EOLE_CONF_DIR)
	mkdir -p $(CONFAMON_DIR)/etc/eole/
	mkdir -p $(CONFAMON_DIR)/$(EAD_DIR)

	cp -rf eole/* $(CONFAMON_DIR)/$(EOLE_DIR)
	# copie des dictionnaires
	cp -rf dicos $(CONFAMON_DIR)/$(EOLE_CONF_DIR)
	# copie des templates
	cp -rf tmpl $(CONFAMON_DIR)/$(EOLE_CONF_DIR)/distrib
	# copie des scripts eole
	#cp -f sbin/* $(CONFAMON_DIR)/$(SBIN_DIR)
	cp -f bin/* $(CONFAMON_DIR)/$(BIN_DIR)
	# copie des scripts d''init Eole ...
	cp -f init.d/* $(CONFAMON_DIR)/$(INIT_DIR)
	# configuration EAD
	cp -rf ead/* $(CONFAMON_DIR)/$(EAD_DIR)

	#reverseproxy
	mkdir -p $(REV_DIR)/$(EOLE_CONF_DIR)
	mkdir -p $(REV_DIR)/$(EOLE_DIR)/diagnose/module
	cp -rf reverseproxy/eole/* $(REV_DIR)/$(EOLE_DIR)
	cp -rf reverseproxy/dicos $(REV_DIR)/$(EOLE_CONF_DIR)/dicos
	cp -rf reverseproxy/tmpl $(REV_DIR)/$(EOLE_CONF_DIR)/distrib
	cp -rf reverseproxy/diagnose/* $(REV_DIR)/$(EOLE_DIR)/diagnose/module

	#dns
	mkdir -p $(DNS_DIR)/$(EOLE_CONF_DIR)
	mkdir -p $(DNS_DIR)/$(EOLE_DIR)/diagnose/module
	mkdir -p $(DNS_DIR)/$(AGENT_DIR)
	cp -rf dns/eole/* $(DNS_DIR)/$(EOLE_DIR)
	cp -rf dns/dicos $(DNS_DIR)/$(EOLE_CONF_DIR)/dicos
	cp -rf dns/tmpl $(DNS_DIR)/$(EOLE_CONF_DIR)/distrib
	cp -rf dns/diagnose/* $(DNS_DIR)/$(EOLE_DIR)/diagnose/module
	cp -rf dns/zephir/* $(DNS_DIR)/$(AGENT_DIR)

	#nuauth
	mkdir -p $(NUAUTH_DIR)/$(EOLE_CONF_DIR)
	mkdir -p $(NUAUTH_DIR)/$(EOLE_DIR)/diagnose/module
	mkdir -p $(NUAUTH_DIR)/$(AGENT_DIR)
	cp -rf nuauth/eole/* $(NUAUTH_DIR)/$(EOLE_DIR)
	cp -rf nuauth/dicos $(NUAUTH_DIR)/$(EOLE_CONF_DIR)/dicos
	cp -rf nuauth/tmpl $(NUAUTH_DIR)/$(EOLE_CONF_DIR)/distrib
	cp -f  nuauth/diagnose/* $(NUAUTH_DIR)/$(EOLE_DIR)/diagnose/module
	cp -f  nuauth/zephir/* $(NUAUTH_DIR)/$(AGENT_DIR)

	#radius
	mkdir -p $(RADIUS_DIR)/$(EOLE_CONF_DIR)
	cp -rf radius/dicos $(RADIUS_DIR)/$(EOLE_CONF_DIR)/dicos
	cp -rf radius/tmpl $(RADIUS_DIR)/$(EOLE_CONF_DIR)/distrib

	#proxy
	mkdir -p $(PROXY_DIR)/$(EOLE_CONF_DIR)
	mkdir -p $(PROXY_DIR)/$(EOLE_DIR)/diagnose/module
	mkdir -p $(PROXY_DIR)/$(AGENT_DIR)
	mkdir -p $(PROXY_DIR)/$(EAD_DIR)
	cp -rf proxy/eole/* $(PROXY_DIR)/$(EOLE_DIR)
	cp -rf proxy/dicos $(PROXY_DIR)/$(EOLE_CONF_DIR)/dicos
	cp -rf proxy/tmpl $(PROXY_DIR)/$(EOLE_CONF_DIR)/distrib
	cp -f proxy/diagnose/* $(PROXY_DIR)/$(EOLE_DIR)/diagnose/module
	cp -rf proxy/zephir/* $(PROXY_DIR)/$(AGENT_DIR)
	cp -rf proxy/ead/* $(PROXY_DIR)/$(EAD_DIR)

	#rvp
	mkdir -p $(RVP_DIR)/$(EOLE_CONF_DIR)
	mkdir -p $(RVP_DIR)/$(EOLE_DIR)/diagnose/module
	mkdir -p $(RVP_DIR)/$(AGENT_DIR)
	mkdir -p $(RVP_DIR)/etc/init.d/
	cp -rf rvp/eole/* $(RVP_DIR)/$(EOLE_DIR)
	cp -rf rvp/dicos $(RVP_DIR)/$(EOLE_CONF_DIR)/dicos
	cp -rf rvp/tmpl $(RVP_DIR)/$(EOLE_CONF_DIR)/distrib
	cp -f  rvp/diagnose/* $(RVP_DIR)/$(EOLE_DIR)/diagnose/module
	cp -f  rvp/zephir/* $(RVP_DIR)/$(AGENT_DIR)
	cp -f rvp/init.d/* $(RVP_DIR)/etc/init.d/

	#dhcrelay
	mkdir -p $(DHCRELAY_DIR)/$(EOLE_CONF_DIR)/distrib
	#mkdir -p $(DHCRELAY_DIR)/$(EOLE_DIR)/diagnose/module
	#mkdir -p $(DHCRELAY_DIR)/$(AGENT_DIR)
	#cp -rf dhcrelay/eole/* $(DHCRELAY_DIR)/$(EOLE_DIR)
	cp -rf dhcrelay/dicos $(DHCRELAY_DIR)/$(EOLE_CONF_DIR)/dicos
	#cp -f  rvp/diagnose/* $(DHCRELAY_DIR)/$(EOLE_DIR)/diagnose/module
	cp -rd dhcrelay/tmpl/* $(DHCRELAY_DIR)/$(EOLE_CONF_DIR)/distrib

