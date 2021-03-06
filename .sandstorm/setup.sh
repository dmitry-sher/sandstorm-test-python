#!/bin/bash
set -euo pipefail
# This script is run in the VM once when you first run `vagrant-spk up`.  It is
# useful for installing system-global dependencies.  It is run exactly once
# over the lifetime of the VM.
#
# This is the ideal place to do things like:
#
#    export DEBIAN_FRONTEND=noninteractive
#    apt-get update
#    apt-get install -y nginx nodejs nodejs-legacy python2.7 mysql-server
#
# If the packages you're installing here need some configuration adjustments,
# this is also a good place to do that:
#
#    sed --in-place='' \
#            --expression 's/^user www-data/#user www-data/' \
#            --expression 's#^pid /run/nginx.pid#pid /var/run/nginx.pid#' \
#            --expression 's/^\s*error_log.*/error_log stderr;/' \
#            --expression 's/^\s*access_log.*/access_log off;/' \
#            /etc/nginx/nginx.conf

# Install sandstorm and pycapnp dependencies from apt repos.
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y build-essential libcap-dev xz-utils zip unzip imagemagick \
    strace curl clang discount git autoconf pkg-config libtool \
    python3 python3-pip python3-dev

# Install capnproto from source, since Sandstorm currently depends on unreleased capnproto features.
if [ ! -e /usr/local/bin/capnp ]; then
    [ -d capnproto ] || git clone https://github.com/sandstorm-io/capnproto
    pushd capnproto/c++
    autoreconf -i && ./configure && make -j2 && sudo make install
    popd
fi

# Install pycapnp from PyPI, which should use the system libcapnp we just installed
pip3 install pycapnp flask

# Remove python3-dev, then remove any dependencies it pulled in.
# We need python3-dev to make "pip3 install" work, but it adds 55 MB of stuff in /usr/lib/python3.4
# (a folder which we need to include unconditionally because tracing is hard), so we remove it once
# we're done installing from pip.
apt-get -y remove python3-dev
apt-get -y autoremove
