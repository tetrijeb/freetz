$(call PKG_INIT_BIN,$(if $(FREETZ_PACKAGE_OPENVPN_VERSION_2_2),2.2.2,2.3.2))
$(PKG)_SOURCE_MD5_2.2.2:=c5181e27b7945fa6276d21873329c5c7
$(PKG)_SOURCE_MD5_2.3.2:=06e5f93dbf13f2c19647ca15ffc23ac1
$(PKG)_SOURCE_MD5:=$($(PKG)_SOURCE_MD5_$($(PKG)_VERSION))
$(PKG)_SOURCE:=$(pkg)-$($(PKG)_VERSION).tar.gz
$(PKG)_SITE:=http://swupdate.openvpn.net/community/releases

$(PKG)_CONDITIONAL_PATCHES+=$($(PKG)_VERSION)
ifeq ($(strip $(FREETZ_PACKAGE_OPENVPN_WITH_TRAFFIC_OBFUSCATION)),y)
$(PKG)_CONDITIONAL_PATCHES+=$($(PKG)_VERSION)/obfuscation
endif

$(PKG)_BINARY:=$($(PKG)_DIR)/$(if $(FREETZ_PACKAGE_OPENVPN_VERSION_2_2),openvpn,src/openvpn/openvpn)
$(PKG)_TARGET_BINARY:=$($(PKG)_DEST_DIR)/usr/sbin/openvpn

$(PKG)_STARTLEVEL=81

$(PKG)_DEPENDS_ON += $(if $(FREETZ_PACKAGE_OPENVPN_OPENSSL),openssl)
$(PKG)_DEPENDS_ON += $(if $(FREETZ_PACKAGE_OPENVPN_POLARSSL),polarssl)
$(PKG)_DEPENDS_ON += $(if $(FREETZ_PACKAGE_OPENVPN_WITH_LZO),lzo)

$(PKG)_REBUILD_SUBOPTS += FREETZ_PACKAGE_OPENVPN_VERSION_2_2
$(PKG)_REBUILD_SUBOPTS += FREETZ_PACKAGE_OPENVPN_VERSION_2_3
$(PKG)_REBUILD_SUBOPTS += FREETZ_PACKAGE_OPENVPN_OPENSSL
$(PKG)_REBUILD_SUBOPTS += FREETZ_OPENSSL_SHLIB_VERSION
$(PKG)_REBUILD_SUBOPTS += FREETZ_PACKAGE_OPENVPN_POLARSSL
$(PKG)_REBUILD_SUBOPTS += FREETZ_PACKAGE_OPENVPN_WITH_LZO
$(PKG)_REBUILD_SUBOPTS += FREETZ_PACKAGE_OPENVPN_WITH_TRAFFIC_OBFUSCATION
$(PKG)_REBUILD_SUBOPTS += FREETZ_PACKAGE_OPENVPN_WITH_MGMNT
$(PKG)_REBUILD_SUBOPTS += FREETZ_PACKAGE_OPENVPN_ENABLE_SMALL
$(PKG)_REBUILD_SUBOPTS += FREETZ_PACKAGE_OPENVPN_USE_IPROUTE
$(PKG)_REBUILD_SUBOPTS += FREETZ_PACKAGE_OPENVPN_STATIC
$(PKG)_REBUILD_SUBOPTS += FREETZ_TARGET_IPV6_SUPPORT
$(PKG)_REBUILD_SUBOPTS += FREETZ_LIB_libpolarssl_WITH_BLOWFISH

ifeq ($(strip $(FREETZ_PACKAGE_OPENVPN_VERSION_2_2)),y)
$(PKG)_EXTRA_LIBS += $(if $(FREETZ_PACKAGE_OPENVPN_OPENSSL),-ldl)
$(PKG)_CONFIGURE_OPTIONS += --disable-http
# ipv6 patch modifies both files, touch them to prevent configure from being regenerated
$(PKG)_CONFIGURE_PRE_CMDS += touch -t 200001010000.00 ./configure.ac; touch ./Makefile.in ./configure;
endif

ifeq ($(strip $(FREETZ_PACKAGE_OPENVPN_VERSION_2_3)),y)
$(PKG)_CONFIGURE_OPTIONS += --disable-http-proxy
$(PKG)_CONFIGURE_PRE_CMDS += $(call PKG_PREVENT_RPATH_HARDCODING,./configure)
$(PKG)_CONFIGURE_PRE_CMDS += $(call PKG_MAKE_AC_VARIABLES_PACKAGE_SPECIFIC,lib_polarssl_ssl_init lib_polarssl_aes_crypt_cbc)
endif

# 2.3 doesn't support --with-*-path options
$(PKG)_CONFIGURE_PRE_CMDS += $(call PKG_MAKE_AC_VARIABLES_PACKAGE_SPECIFIC,path_IFCONFIG path_IPROUTE path_ROUTE)
$(PKG)_CONFIGURE_ENV += $(pkg)_path_IFCONFIG=/sbin/ifconfig
$(PKG)_CONFIGURE_ENV += $(pkg)_path_IPROUTE=/sbin/ip
$(PKG)_CONFIGURE_ENV += $(pkg)_path_ROUTE=/sbin/route

# add EXTRA_CFLAGS, EXTRA_LDFLAGS, EXTRA_LIBS make variables
$(PKG)_CONFIGURE_PRE_CMDS += find $(abspath $($(PKG)_DIR)) -name Makefile.in -type f -exec $(SED) -i -r -e 's,^((C|LD)FLAGS|LIBS)[ \t]*=[ \t]*@\1@,& $$$$(EXTRA_\1),' \{\} \+;

$(PKG)_EXTRA_CFLAGS  += -ffunction-sections -fdata-sections
$(PKG)_EXTRA_LDFLAGS += -Wl,--gc-sections
$(PKG)_EXTRA_LDFLAGS += $(if $(FREETZ_PACKAGE_OPENVPN_STATIC),$(if $(FREETZ_PACKAGE_OPENVPN_VERSION_2_2),-static,-all-static))

$(PKG)_CONFIGURE_OPTIONS += --sysconfdir=/mod/etc/openvpn
$(PKG)_CONFIGURE_OPTIONS += $(if $(FREETZ_PACKAGE_OPENVPN_WITH_LZO),--enable-lzo,--disable-lzo)
$(PKG)_CONFIGURE_OPTIONS += --disable-debug
$(PKG)_CONFIGURE_OPTIONS += --disable-multihome
$(PKG)_CONFIGURE_OPTIONS += --disable-plugins
$(PKG)_CONFIGURE_OPTIONS += --disable-port-share
$(PKG)_CONFIGURE_OPTIONS += $(if $(FREETZ_PACKAGE_OPENVPN_WITH_MGMNT),--enable-management,--disable-management)
$(PKG)_CONFIGURE_OPTIONS += --disable-pkcs11
$(PKG)_CONFIGURE_OPTIONS += --disable-socks
$(PKG)_CONFIGURE_OPTIONS += --enable-password-save
$(PKG)_CONFIGURE_OPTIONS += $(if $(FREETZ_PACKAGE_OPENVPN_POLARSSL),--with-crypto-library=polarssl)
$(PKG)_CONFIGURE_OPTIONS += $(if $(FREETZ_PACKAGE_OPENVPN_USE_IPROUTE),--enable-iproute2)
$(PKG)_CONFIGURE_OPTIONS += $(if $(FREETZ_PACKAGE_OPENVPN_ENABLE_SMALL),--enable-small,--disable-small)
$(PKG)_CONFIGURE_OPTIONS += $(if $(FREETZ_TARGET_IPV6_SUPPORT),--enable-ipv6,--disable-ipv6)

$(PKG_SOURCE_DOWNLOAD)
$(PKG_UNPACKED)
$(PKG_CONFIGURED_CONFIGURE)

$($(PKG)_BINARY): $($(PKG)_DIR)/.configured
	$(SUBMAKE) -C $(OPENVPN_DIR) \
		EXTRA_CFLAGS="$(OPENVPN_EXTRA_CFLAGS)" \
		EXTRA_LDFLAGS="$(OPENVPN_EXTRA_LDFLAGS)" \
		EXTRA_LIBS="$(OPENVPN_EXTRA_LIBS)" \
		SOCKETS_LIBS=""

$($(PKG)_TARGET_BINARY): $($(PKG)_BINARY)
	$(INSTALL_BINARY_STRIP)

$(pkg):

$(pkg)-precompiled: $($(PKG)_TARGET_BINARY)

$(pkg)-clean:
	-$(SUBMAKE) -C $(OPENVPN_DIR) clean
	$(RM) $(OPENVPN_FREETZ_CONFIG_FILE)

$(pkg)-uninstall:
	$(RM) $(OPENVPN_TARGET_BINARY)

$(PKG_FINISH)
