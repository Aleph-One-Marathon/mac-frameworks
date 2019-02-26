#!/bin/bash

export PROJ="png"
export VERSION="1.6.36"
export URL="https://download.sourceforge.net/libpng/libpng-1.6.36.tar.gz"
export DIRNAME="lib$PROJ-$VERSION"
export CONFIGOPTS="--disable-static"
export LICENSE="LICENSE"

../build-std.sh

mv png.framework/Versions/A/Headers/libpng16/*.h png.framework/Versions/A/Headers/
rmdir png.framework/Versions/A/Headers/libpng16
