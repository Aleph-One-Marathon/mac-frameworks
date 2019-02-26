#!/bin/bash

DEV="/Applications/Xcode.app/Contents/Developer"
SDKROOT="$DEV/Platforms/MacOSX.platform/Developer/SDKs"
STOCKPATH="$DEV/usr/bin:/usr/bin:/bin"
STOCKPKGCONFIG="/usr/lib/pkgconfig"
SRCDIR="$PWD/src"
COMPILEDIR="$PWD/objs"
INSTALLDIR="$PWD/installs"
FWKDIR="$PWD"
PLIST_TEMPLATE="$PWD/../Info-template.plist"

if [ "$DLNAME" == "" ]; then DLNAME="${URL##*/}"; fi
if [ "$DIRNAME" == "" ]; then DIRNAME="$PROJ-$VERSION"; fi
if [ "$FWKS" == "" ]; then FWKS="lib$PROJ"; fi
if [ "$HEADERROOT" == "" ]; then HEADERROOT="include"; fi

FWKS=( $FWKS )

# grab source
if [ ! -f "$DLNAME" ]; then
  curl -L -o "$DLNAME" "$URL"
fi

# unpack source
if [ -d "$SRCDIR" ]; then rm -r "$SRCDIR"; fi
case "$DLNAME" in
  *.tar.bz2 ) tar xjf "$DLNAME" ;;
  *.tar.gz  ) tar xzf "$DLNAME" ;;
  *         ) echo "Cannot unpack $DLNAME" ; exit ;;
esac
mv "$DIRNAME" "$SRCDIR"

if [ "$LICENSE" != "" ]; then
  if [ -f "$SRCDIR/$LICENSE" ]; then
    cp "$SRCDIR/$LICENSE" "License.txt"
  fi
fi

if [ -d "$COMPILEDIR" ]; then rm -r "$COMPILEDIR"; fi
if [ -d "$INSTALLDIR" ]; then rm -r "$INSTALLDIR"; fi

# x86_64 build
IDIR="$INSTALLDIR/x86_64"
mkdir -p "$IDIR"
CDIR="$COMPILEDIR/x86_64"
mkdir -p "$CDIR"
cd "$CDIR"

export PATH="$PATH_OVERRIDE:$STOCKPATH:$PATH_EXTRA"
export PKG_CONFIG_PATH="$PKGCONFIG_OVERRIDE:$STOCKPKGCONFIG"
export ENVP="MACOSX_DEPLOYMENT_TARGET=10.9"
FLAGS="-arch x86_64 -mmacosx-version-min=10.9"

env -i \
  CC="$DEV/usr/bin/gcc" \
  CPP="$DEV/usr/bin/gcc -E" \
  LD="$DEV/usr/bin/g++" \
  CFLAGS="$FLAGS" \
  LDFLAGS="$FLAGS" \
  PATH="$PATH" \
  PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
  "$SRCDIR/configure" --prefix="$IDIR" $CONFIGOPTS
env -i \
  CC="$DEV/usr/bin/gcc" \
  CPP="$DEV/usr/bin/gcc -E" \
  LD="$DEV/usr/bin/g++" \
  CFLAGS="$FLAGS" \
  LDFLAGS="$FLAGS" \
  PATH="$PATH" \
  PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
  make
env -i \
  CC="$DEV/usr/bin/gcc" \
  CPP="$DEV/usr/bin/gcc -E" \
  LD="$DEV/usr/bin/g++" \
  CFLAGS="$FLAGS" \
  LDFLAGS="$FLAGS" \
  PATH="$PATH" \
  PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
  make install

# Done with compiling
if [ "$DEBUG" == "" ]; then
  rm -rf "$COMPILEDIR"
  rm -r "$SRCDIR"
fi

if [ "$NOPACKAGING" == "1" ]; then exit; fi

# Update shared-library paths
for arch in x86_64; do
  LIBDIR="$INSTALLDIR/$arch/lib"
  for lib in "${FWKS[@]}"; do
    lname=${lib#lib}
    dylibvar="DYLIBNAME_$lib"
    dylibname="${!dylibvar}"
    if [ "$dylibname" == "" ]; then dylibname="$lib.dylib"; fi
    install_name_tool -id "@executable_path/../Frameworks/$lname.framework/Versions/A/$lname" "$LIBDIR/$dylibname"
    
    # fix links to sibling libraries
    for elib in "${FWKS[@]}"; do
      ename=${elib#lib}
      edylibvar="DYLIBNAME_$elib"
      edylibname="${!edylibvar}"
      if [ "$edylibname" == "" ]; then edylibname="$elib.dylib"; fi
      install_name_tool -change "$LIBDIR/$edylibname" "@executable_path/../Frameworks/$ename.framework/Versions/A/$ename" "$LIBDIR/$dylibname"
    done
  done
done

# Set up frameworks
for lib in "${FWKS[@]}"; do
  # set up directory structure
  lname=${lib#lib}
  FDIR="$FWKDIR/$lname.framework"
  if [ -d "$FDIR" ]; then rm -r "$FDIR"; fi
  mkdir -p "$FDIR/Versions/A/Headers"
  mkdir -p "$FDIR/Versions/A/Resources"
  
  cd "$FDIR/Versions"
  ln -s A Current
  
  cd "$FDIR"
  ln -s Versions/Current/Headers
  ln -s Versions/Current/Resources
  ln -s Versions/Current/$lname
  
  # copy binary
  dylibvar="DYLIBNAME_$lib"
  dylibname="${!dylibvar}"
  if [ "$dylibname" == "" ]; then dylibname="$lib.dylib"; fi
  cp "$INSTALLDIR/x86_64/lib/$dylibname" "$FDIR/Versions/A/$lname"
  
  # create Info.plist
  cp "$PLIST_TEMPLATE" "$FDIR/Resources/Info.plist"
  sed -i '' -e s/\$FRAMEWORK_NAME/$lname/g "$FDIR/Resources/Info.plist"
  sed -i '' -e s/\$FRAMEWORK_VERSION/$VERSION/g "$FDIR/Resources/Info.plist"
  
  # copy headers
  HNAME="$FDIR/Headers"
  mkdir -p "$HNAME"
  cd "$INSTALLDIR/x86_64/include"
  for hfile in `find . -type f`; do
    mkdir -p "$HNAME"/`dirname $hfile`
    cp $hfile "$HNAME/$hfile"
  done
    
done


# done with installdir
if [ "$DEBUG" == "" ]; then rm -r "$INSTALLDIR"; fi
