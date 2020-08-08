#!/bin/bash

export PROJ="vorbis"
export VERSION="1.3.7"
export URL="http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.gz"
export DIRNAME="lib$PROJ-$VERSION"
OGGBASE=$(cd "../ogg/installs/x86_64" && pwd)
export CONFIGOPTS="--disable-shared --disable-oggtest --with-ogg-libraries=$OGGBASE/lib --with-ogg-includes=$OGGBASE/include"
export NOPACKAGING="1"
export LICENSE="COPYING"

../build-std.sh
