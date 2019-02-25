#!/bin/bash

export PROJ="vpx"
export VERSION="1.8.0"
export URL="https://github.com/webmproject/libvpx/archive/v1.8.0.tar.gz"
export DIRNAME="lib$PROJ-$VERSION"
export CONFIGOPTS="--disable-examples --disable-unit-tests --target=x86_64-darwin13-gcc"
export NOPACKAGING="1"

../build-std.sh
