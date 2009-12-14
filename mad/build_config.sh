#!/bin/bash
set -o errexit

## general compilation targets
arches=( x86_64 i386 ppc )
sdks=( /Developer/SDKs/MacOSX10.6.sdk /Developer/SDKs/MacOSX10.4u.sdk /Developer/SDKs/MacOSX10.4u.sdk )
minvers=( 10.6 10.4 10.4 )
gccvers=( 4.2 4.0 4.0 )

## project-specific options
proj="mad"
config_h_filenames=( config.h )
config_h_indirs=( . )
config_h_outdirs=( . )
extra_config_opts=""

### end of config


# make clean copy of config.h directory
configdir="config"
if [ -e $configdir ]; then
  rm -rf $configdir
fi
idx=0
while [ "$idx" -lt "${#config_h_filenames[@]}" ]; do
  mkdir -p "$configdir/${config_h_outdirs[idx]}"
  outconfig="$configdir/${config_h_outdirs[idx]}/${config_h_filenames[idx]}"
  touch $outconfig
  ((idx++))
done

# make clean copy of source tree
libdir="lib$proj"
tempdir="temp_$libdir"
if [ -e $tempdir ]; then
  rm -rf $tempdir
fi
cp -a $libdir $tempdir

# configure for each arch
idx=0
while [ "$idx" -lt "${#arches[@]}" ]; do
  arch=${arches[idx]}
  export CC=gcc-${gccvers[idx]}
  export CXX=g++-${gccvers[idx]}
  export LD=g++-${gccvers[idx]}
  export CFLAGS="-arch $arch -isysroot ${sdks[idx]} -mmacosx-version-min=${minvers[idx]}"
  export CXXFLAGS="$CFLAGS"
  export LDFLAGS="$CFLAGS"
  export OBJCFLAGS="$CFLAGS"
  
  # all set up, now run
  pushd $tempdir
  ./configure $extra_config_opts
  popd
  
  # add this config.h to the master copy
  jdx=0
  while [ "$jdx" -lt "${#config_h_filenames[@]}" ]; do
    inconfig="$tempdir/${config_h_indirs[jdx]}/${config_h_filenames[jdx]}"
    outconfig="$configdir/${config_h_outdirs[jdx]}/${config_h_filenames[jdx]}"
  
    fpm=DEFAULT
    if [ "$arch" == "x86_64" ]; then
      fpm=INTEL
    fi
    if [ "$arch" == "i386" ]; then
      fpm=INTEL
    fi
    if [ "$arch" == "ppc" ]; then
      fpm=PPC
    fi
    
    cat >> $outconfig <<EOM
#ifdef __${arch}__
#define FPM_$fpm
EOM
    cat $inconfig >> $outconfig
    cat >> $outconfig <<EOM
#endif
EOM
    ((jdx++))
  done
  ((idx++))
done

# remove source tree copy
rm -rf $tempdir
