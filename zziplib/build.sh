#!/bin/bash

export PROJ="zziplib"
export VERSION="0.13.71"
export URL="https://github.com/gdraheim/zziplib/archive/v0.13.71.tar.gz"
export CONFIGOPTS="--disable-static"
export DYLIBNAME_libzziplib="libzzip.dylib"
export LICENSE="COPYING.LIB"

../build-std.sh
