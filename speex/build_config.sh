#!/bin/bash
set -o errexit

## general compilation targets
arches=( i386 ppc )
sdk="/Developer/SDKs/MacOSX10.4u.sdk"
minver="10.4"
gccver="4.0"

## project-specific options
proj="speex"
config_h_filename="config.h"
config_h_dir="."
extra_config_opts=""

### end of config


# make clean copy of config.h directory
configdir="config"
if [ -e $configdir ]; then
  rm -rf $configdir
fi
mkdir $configdir
outconfig="$configdir/$config_h_filename"
touch $outconfig

# make clean copy of source tree
libdir="lib$proj"
tempdir="temp_$libdir"
if [ -e $tempdir ]; then
  rm -rf $tempdir
fi
cp -a $libdir $tempdir
inconfig="$tempdir/$config_h_dir/$config_h_filename"

# configure for each arch
export CC=gcc-$gccver
export CXX=g++-$gccver
export LD=g++-$gccver
for arch in "${arches[@]}"; do
  export CFLAGS="-arch $arch -isysroot $sdk -mmacosx-version-min=$minver"
  export CXXFLAGS="$CFLAGS"
  export LDFLAGS="$CFLAGS"
  export OBJCFLAGS="$CFLAGS"
  
  # all set up, now run
  pushd $tempdir
  ./configure $extra_config_opts
  popd
  
  # add this config.h to the master copy
  cat >> $outconfig <<EOM
#ifdef __${arch}__
EOM
  cat $inconfig >> $outconfig
  cat >> $outconfig <<EOM
#endif
EOM

done

# remove source tree copy
rm -rf $tempdir
