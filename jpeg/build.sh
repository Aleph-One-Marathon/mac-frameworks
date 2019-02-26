#!/bin/bash

export PROJ="jpeg"
export VERSION="9c"
export URL="http://www.ijg.org/files/jpegsrc.v9c.tar.gz"
export CONFIGOPTS="--disable-static"
export LICENSE="README"

../build-std.sh
