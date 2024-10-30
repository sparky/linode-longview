#!/bin/sh

DESTDIR="${DESTDIR-/}"

TARGET="${TARGET-site}"

IFS="'" read -r var MODULEDIR colon <<< $(perl -V:${TARGET}lib)
IFS="'" read -r var BINDIR colon <<< $(perl -V:${TARGET}bin)
CONFDIR="/etc/linode/longview.d"
SYSTEMDDIR="/usr/lib/systemd/system"

echo "Installing modules in $DESTDIR$MODULEDIR"
install -d -m755 "$DESTDIR$MODULEDIR"
cp -dpr --no-preserve=ownership lib/* "$DESTDIR$MODULEDIR"

echo "Installing executables in $DESTDIR$BINDIR"
install -d -m755 "$DESTDIR$BINDIR"
install -m755 bin/* "$DESTDIR$BINDIR"

echo "Installing configuration in $DESTDIR$CONFDIR"
install -d -m755 "$DESTDIR$CONFDIR"
install -m600 -t "$DESTDIR$CONFDIR" Extras/conf/*.conf
touch "$DESTDIR$CONFDIR/../longview.key"
chmod 600 "$DESTDIR$CONFDIR/../longview.key"

echo "Installing service files in $DESTDIR$SYSTEMDDIR"
install -d -m755 "$DESTDIR$SYSTEMDDIR"
install -m644 -t "$DESTDIR$SYSTEMDDIR" "Extras/init/linode-longview.service"
