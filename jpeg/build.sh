#!/bin/bash

export PROJ="jpeg"
export VERSION="9d"
export URL="http://www.ijg.org/files/jpegsrc.v9d.tar.gz"
export CONFIGOPTS="--disable-static"
export LICENSE="README"

../build-std.sh
