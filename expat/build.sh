#!/bin/bash

set -e

DEV="$(xcode-select -p)"
# Note: yasm must be installed; add its directory to STOCKPATH if needed
STOCKPATH="$DEV/usr/bin:/usr/bin:/bin"
SRCDIR="$PWD/src"
COMPILEDIR="$PWD/objs"
INSTALLDIR="$PWD/installs"
FWKDIR="$PWD"
PLIST_TEMPLATE="$PWD/../Info-template.plist"
CONFIGOPTS="--disable-static --without-png"
FWKS=(libexpat)
FWK_VERSION="2.1.1"


# unpack source
if [ -d "$SRCDIR" ]; then rm -r "$SRCDIR"; fi
tar xzf expat-$FWK_VERSION.tar.bz2
mv "expat-$FWK_VERSION" "$SRCDIR"

if [ -d "$COMPILEDIR" ]; then rm -r "$COMPILEDIR"; fi
if [ -d "$INSTALLDIR" ]; then rm -r "$INSTALLDIR"; fi

IDIR="$INSTALLDIR/x86_64"
mkdir -p "$IDIR"
CDIR="$COMPILEDIR/x86_64"
mkdir -p "$CDIR"
cd "$CDIR"

SDK="$DEV/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.6.sdk"
export PATH="$SDK/usr/bin:$STOCKPATH"
FLAGS="-arch x86_64 -mmacosx-version-min=10.6 -isysroot $SDK"

env \
  CC="$DEV/usr/bin/gcc-4.2" \
  CPP="$DEV/usr/bin/gcc-4.2 -E" \
  LD="$DEV/usr/bin/g++-4.2" \
  CFLAGS="$FLAGS" \
  LDFLAGS="$FLAGS" \
  "$SRCDIR/configure" --prefix="$IDIR" $CONFIGOPTS \
  --host="x86_64-apple-darwin10"
make
make install

# Done with compiling
rm -rf "$COMPILEDIR"
rm -r "$SRCDIR"

# Update shared-library paths 
LIBDIR="$INSTALLDIR/x86_64/lib"
for lib in "${FWKS[@]}"; do
  lname=${lib#lib}
  install_name_tool -id "@executable_path/../Frameworks/$lname.framework/Versions/A/$lname" "$LIBDIR/$lib.dylib"

  # fix links to sibling libraries
  for elib in "${FWKS[@]}"; do
    ename=${elib#lib}
    install_name_tool -change "$LIBDIR/$elib.dylib" "@executable_path/../Frameworks/$ename.framework/Versions/A/$ename" "$LIBDIR/$lib.dylib"
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
  
  # create universal binary
  lipo \
    "$INSTALLDIR/x86_64/lib/$lib.dylib" \
    -create -o "$FDIR/Versions/A/$lname"
  
  # create Info.plist
  cp "$PLIST_TEMPLATE" "$FDIR/Resources/Info.plist"
  sed -i '' -e s/\$FRAMEWORK_NAME/$lname/g "$FDIR/Resources/Info.plist"
  sed -i '' -e s/\$FRAMEWORK_VERSION/$FWK_VERSION/g "$FDIR/Resources/Info.plist"
done


# done with installdir
rm -r "$INSTALLDIR"
