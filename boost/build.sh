#!/bin/bash -l

export PROJ="boost"
export VERSION="1.73.0"
export VERSIONDL="${VERSION//./_}"
export URL="https://dl.bintray.com/boostorg/release/$VERSION/source/boost_$VERSIONDL.tar.bz2"
export DIRNAME="${PROJ}_${VERSIONDL}"
export FWKS=(libboost_system libboost_filesystem boost)
export CONFIGOPTS=""
export LICENSE="LICENSE_1_0.txt"

DEV="/Applications/Xcode.app/Contents/Developer"
SDKROOT="$DEV/Platforms/MacOSX.platform/Developer/SDKs"
STOCKPATH="$DEV/usr/bin:/usr/bin:/bin"
SRCDIR="$PWD/src"
COMPILEDIR="$PWD/objs"
INSTALLDIR="$PWD/installs"
FWKDIR="$PWD"
PLIST_TEMPLATE="$PWD/../Info-template.plist"

if [ "$DLNAME" == "" ]; then DLNAME="${URL##*/}"; fi
if [ "$DIRNAME" == "" ]; then DIRNAME="$PROJ-$VERSION"; fi
if [ "$FWKS" == "" ]; then FWKS=("lib$PROJ"); fi


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
mkdir -p "$COMPILEDIR"
cp -a "$SRCDIR" "$CDIR"
cd "$CDIR"

export PATH="$STOCKPATH"
export ENVP="MACOSX_DEPLOYMENT_TARGET=10.9"
FLAGS="-arch x86_64 -mmacosx-version-min=10.9"

env \
  CC="$DEV/usr/bin/gcc" \
  CPP="$DEV/usr/bin/gcc -E" \
  LD="$DEV/usr/bin/g++" \
  CFLAGS="$FLAGS" \
  LDFLAGS="$FLAGS" \
  ./bootstrap.sh --prefix="$IDIR" --with-libraries=filesystem,system

./b2 install

# Done with compiling
cd "$FWKDIR"
rm -r "$COMPILEDIR"
rm -r "$SRCDIR"

# Update shared-library paths
for arch in x86_64; do
  LIBDIR="$INSTALLDIR/$arch/lib"
  for lib in "${FWKS[@]}"; do
    if [ -f "$LIBDIR/$lib.dylib" ]; then
      lname=${lib#lib}
      install_name_tool -id "@executable_path/../Frameworks/$lname.framework/Versions/A/$lname" "$LIBDIR/$lib.dylib"

      # fix links to sibling libraries
      for elib in "${FWKS[@]}"; do
        ename=${elib#lib}
        install_name_tool -change "$elib.dylib" "@executable_path/../Frameworks/$ename.framework/Versions/A/$ename" "$LIBDIR/$lib.dylib"
      done
    fi
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

  # create binary
  if [ -f "$INSTALLDIR/x86_64/lib/$lib.dylib" ]; then
    cp "$INSTALLDIR/x86_64/lib/$lib.dylib" "$FDIR/Versions/A/$lname"
  fi

  cd "$FDIR/Versions"
  ln -s A Current

  cd "$FDIR"
  ln -s Versions/Current/Headers
  ln -s Versions/Current/Resources
  if [ -f "Versions/Current/$lname" ]; then
    ln -s Versions/Current/$lname
  fi

  # create Info.plist
  cp "$PLIST_TEMPLATE" "$FDIR/Resources/Info.plist"
  sed -i '' -e s/\$FRAMEWORK_NAME/$lname/g "$FDIR/Resources/Info.plist"
  sed -i '' -e s/\$FRAMEWORK_VERSION/$FWK_VERSION/g "$FDIR/Resources/Info.plist"

  # create headers
  HNAME="$FDIR/Headers"
  mkdir -p "$HNAME"
  cd "$INSTALLDIR/x86_64/include"
  FINDPATH=${lname/_/\/}
  for hfile in `find $FINDPATH -type f`; do
    mkdir -p "$HNAME"/`dirname $hfile`
    cp $hfile "$HNAME/$hfile"
  done

done


# done with installdir
rm -r "$INSTALLDIR"
