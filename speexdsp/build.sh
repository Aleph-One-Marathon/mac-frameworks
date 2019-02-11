#!/bin/bash

export PROJ="speexdsp"
export VERSION="1.2rc3"
export URL="http://downloads.xiph.org/releases/speex/$PROJ-$VERSION.tar.gz"
export CONFIGOPTS="--disable-static"

../build-std.sh
