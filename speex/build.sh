#!/bin/bash

export PROJ="speex"
export VERSION="1.2.0"
export URL="http://downloads.xiph.org/releases/speex/$PROJ-$VERSION.tar.gz"
export CONFIGOPTS="--disable-static"
export LICENSE="COPYING"

../build-std.sh
