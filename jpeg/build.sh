#!/bin/bash

DEV="/Developer-3.2.6"
# Note: yasm must be installed; add its directory to STOCKPATH if needed
STOCKPATH="$DEV/usr/bin:/usr/bin:/bin"
SRCDIR="$PWD/src"
COMPILEDIR="$PWD/objs"
INSTALLDIR="$PWD/installs"
FWKDIR="$PWD"
PLIST_TEMPLATE="$PWD/../Info-template.plist"
CONFIGOPTS="--disable-static"
FWKS=(libjpeg)
FWK_VERSION="9"


# unpack source
if [ -d "$SRCDIR" ]; then rm -r "$SRCDIR"; fi
tar xzf jpegsrc.v9.tar.gz
mv "jpeg-9" "$SRCDIR"

if [ -d "$COMPILEDIR" ]; then rm -r "$COMPILEDIR"; fi
if [ -d "$INSTALLDIR" ]; then rm -r "$INSTALLDIR"; fi

# ppc build
IDIR="$INSTALLDIR/ppc"
mkdir -p "$IDIR"
CDIR="$COMPILEDIR/ppc"
mkdir -p "$CDIR"
cd "$CDIR"

SDK="$DEV/SDKs/MacOSX10.4u.sdk"
export PATH="$SDK/usr/bin:$STOCKPATH"
FLAGS="-arch ppc -mmacosx-version-min=10.4 -isysroot $SDK"

env \
  CC="$DEV/usr/bin/gcc-4.0" \
  CPP="$DEV/usr/bin/gcc-4.0 -E" \
  LD="$DEV/usr/bin/g++-4.0" \
  CFLAGS="$FLAGS" \
  LDFLAGS="$FLAGS" \
  "$SRCDIR/configure" --prefix="$IDIR" $CONFIGOPTS \
  --host="powerpc-apple-darwin8"
make
make install

# i386 build
IDIR="$INSTALLDIR/i386"
mkdir -p "$IDIR"
CDIR="$COMPILEDIR/i386"
mkdir -p "$CDIR"
cd "$CDIR"

SDK="$DEV/SDKs/MacOSX10.4u.sdk"
export PATH="$SDK/usr/bin:$STOCKPATH"
FLAGS="-arch i386 -mmacosx-version-min=10.4 -isysroot $SDK"

env \
  CC="$DEV/usr/bin/gcc-4.0" \
  CPP="$DEV/usr/bin/gcc-4.0 -E" \
  LD="$DEV/usr/bin/g++-4.0" \
  CFLAGS="$FLAGS" \
  LDFLAGS="$FLAGS" \
  "$SRCDIR/configure" --prefix="$IDIR" $CONFIGOPTS \
  --host="i386-apple-darwin8"
make
make install

# x86_64 build
IDIR="$INSTALLDIR/x86_64"
mkdir -p "$IDIR"
CDIR="$COMPILEDIR/x86_64"
mkdir -p "$CDIR"
cd "$CDIR"

SDK="$DEV/SDKs/MacOSX10.6.sdk"
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
rm -r "$COMPILEDIR"
rm -r "$SRCDIR"

# Update shared-library paths 
for arch in ppc i386 x86_64; do
  LIBDIR="$INSTALLDIR/$arch/lib"
  for lib in "${FWKS[@]}"; do
    lname=${lib#lib}
    install_name_tool -id "@executable_path/../Frameworks/$lname.framework/Versions/A/$lname" "$LIBDIR/$lib.dylib"
    
    # fix links to sibling libraries
    for elib in "${FWKS[@]}"; do
      ename=${elib#lib}
      install_name_tool -change "$LIBDIR/$elib.dylib" "@executable_path/../Frameworks/$ename.framework/Versions/A/$ename" "$LIBDIR/$lib.dylib"
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
  
  # create universal binary
  lipo \
    "$INSTALLDIR/ppc/lib/$lib.dylib" \
    "$INSTALLDIR/i386/lib/$lib.dylib" \
    "$INSTALLDIR/x86_64/lib/$lib.dylib" \
    -create -o "$FDIR/Versions/A/$lname"
  
  # create Info.plist
  cp "$PLIST_TEMPLATE" "$FDIR/Resources/Info.plist"
  sed -i '' -e s/\$FRAMEWORK_NAME/$lname/g "$FDIR/Resources/Info.plist"
  sed -i '' -e s/\$FRAMEWORK_VERSION/$FWK_VERSION/g "$FDIR/Resources/Info.plist"
  
  # merge headers
  HNAME="$FDIR/Headers"
  mkdir -p "$HNAME"
  cd "$INSTALLDIR/i386/include"
  for hfile in `find . -type f`; do
    mkdir -p "$HNAME"/`dirname $hfile`
    
    diff -q $hfile "$INSTALLDIR/ppc/include/$hfile" > /dev/null
    pdif=$?
    diff -q $hfile "$INSTALLDIR/x86_64/include/$hfile" > /dev/null
    xdif=$?
    if [ "$pdif" -ne "0" -o "$xdif" -ne "0" ]; then
      echo "#ifdef __ppc__" > "$HNAME/$hfile"
      cat "$INSTALLDIR/ppc/include/$hfile" >> "$HNAME/$hfile"
      echo "#endif" >> "$HNAME/$hfile"
      echo "#ifdef __i386__" >> "$HNAME/$hfile"
      cat "$INSTALLDIR/i386/include/$hfile" >> "$HNAME/$hfile"
      echo "#endif" >> "$HNAME/$hfile"
      echo "#ifdef __x86_64__" >> "$HNAME/$hfile"
      cat "$INSTALLDIR/x86_64/include/$hfile" >> "$HNAME/$hfile"
      echo "#endif" >> "$HNAME/$hfile"
    else
      cp $hfile "$HNAME/$hfile"
    fi      
  done
    
done


# done with installdir
rm -r "$INSTALLDIR"
