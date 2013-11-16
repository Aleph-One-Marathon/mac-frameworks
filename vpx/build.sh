#!/bin/bash

DEV="/Developer-3.2.6"
# Note: GNU grep must be installed; add its directory to STOCKPATH if needed
STOCKPATH="/usr/local2/bin:$DEV/usr/bin:/usr/bin:/bin"
SRCDIR="$PWD/src"
COMPILEDIR="$PWD/objs"
INSTALLDIR="$PWD/installs"
FWKDIR="$PWD"
CONFIGOPTS="--disable-examples --disable-unit-tests"
FWKS=(vpx)

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

env \
  CC="$DEV/usr/bin/gcc-4.0" \
  CXX="$DEV/usr/bin/g++-4.0" \
  LD="$DEV/usr/bin/g++-4.0" \
  CFLAGS="-isysroot $SDK" \
  CXXFLAGS="-isysroot $SDK" \
  LDFLAGS="-isysroot $SDK" \
  "$SRCDIR/configure" --prefix="$IDIR" $CONFIGOPTS \
    --target="ppc32-darwin8-gcc"
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

env \
  CC="$DEV/usr/bin/gcc-4.0" \
  CXX="$DEV/usr/bin/g++-4.0" \
  LD="$DEV/usr/bin/g++-4.0" \
  CFLAGS="-isysroot $SDK" \
  CXXFLAGS="-isysroot $SDK" \
  LDFLAGS="-isysroot $SDK" \
  "$SRCDIR/configure" --prefix="$IDIR" $CONFIGOPTS \
    --target="x86-darwin8-gcc"
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

env \
  CC="$DEV/usr/bin/gcc-4.2" \
  CXX="$DEV/usr/bin/g++-4.2" \
  LD="$DEV/usr/bin/g++-4.2" \
  "$SRCDIR/configure" --prefix="$IDIR" $CONFIGOPTS \
    --target="x86_64-darwin10-gcc"
make
make install

# Done with compiling
rm -r "$COMPILEDIR"

# Set up static "framework", because vpx is awful :C
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
  ln -s Versions/Current/lib$lname.a $lname.a
  
  # create universal binary
  lipo \
    "$INSTALLDIR/ppc/lib/lib$lib.a" \
    "$INSTALLDIR/i386/lib/lib$lib.a" \
    "$INSTALLDIR/x86_64/lib/lib$lib.a" \
    -create -o "$FDIR/Versions/A/lib$lname.a"
  
  # merge headers
  HNAME="$FDIR/Versions/A/Headers"
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
