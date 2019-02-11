#!/bin/bash

export PROJ="zziplib"
export VERSION="0.13.69"
export URL="https://github.com/gdraheim/zziplib/archive/v0.13.69.tar.gz"
export CONFIGOPTS="--disable-static"
export DYLIBNAME_libzziplib="libzzip.dylib"

../build-std.sh
