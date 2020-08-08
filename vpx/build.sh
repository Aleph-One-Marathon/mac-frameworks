#!/bin/bash

export PROJ="vpx"
export VERSION="1.8.2"
export URL="https://github.com/webmproject/libvpx/archive/v1.8.2.tar.gz"
export DIRNAME="lib$PROJ-$VERSION"
export CONFIGOPTS="--disable-examples --disable-unit-tests --target=x86_64-darwin13-gcc"
export PATH_EXTRA="/usr/local/bin" # for nasm
export NOPACKAGING="1"
export LICENSE="LICENSE"

../build-std.sh
