#!/bin/bash

# Change this to the directory where x264.framework lives
X264DIR="/Library/Frameworks"
DEV="/Developer-3.2.6"
# Note: yasm must be installed; add its directory to STOCKPATH if needed
STOCKPATH="$DEV/usr/bin:/usr/bin:/bin"
SRCDIR="$PWD/src"
COMPILEDIR="$PWD/objs"
INSTALLDIR="$PWD/installs"
FWKDIR="$PWD"
CONFIGOPTS="--disable-static --enable-shared --enable-gpl --disable-doc --disable-ffmpeg --disable-ffplay --disable-ffprobe --disable-ffserver --disable-avdevice --disable-swresample --disable-postproc --disable-avfilter --enable-libx264"
FWKS=(libavcodec libavformat libavutil libswscale)


# if [ -d "$COMPILEDIR" ]; then rm -r "$COMPILEDIR"; fi
# if [ -d "$INSTALLDIR" ]; then rm -r "$INSTALLDIR"; fi

# jump through hoops to make x264 dependency work
DEPDIR="$COMPILEDIR/deps"
mkdir -p "$DEPDIR/lib"
cp "$X264DIR/x264.framework/x264" "$DEPDIR/lib/libx264.dylib"
ln -s "$X264DIR/x264.framework/Headers" "$DEPDIR/include"

# ppc build
IDIR="$INSTALLDIR/ppc"
mkdir -p "$IDIR"
CDIR="$COMPILEDIR/ppc"
mkdir -p "$CDIR"
cd "$CDIR"

SDK="$DEV/SDKs/MacOSX10.4u.sdk"
export PATH="$SDK/usr/bin:$STOCKPATH"
FLAGS="-arch ppc -mmacosx-version-min=10.4 -isysroot $SDK"

"$SRCDIR/configure" --prefix="$IDIR" $CONFIGOPTS \
  --enable-cross-compile --arch="ppc" --cpu="ppc" --target-os="darwin" \
  --cc="$DEV/usr/bin/gcc-4.0" \
  --cxx="$DEV/usr/bin/g++-4.0" \
  --ld="$DEV/usr/bin/g++-4.0" \
  --extra-cflags="$FLAGS -I\"$DEPDIR/include\"" \
  --extra-cxxflags="$FLAGS -I\"$DEPDIR/include\"" \
  --extra-ldflags="$FLAGS -L\"$DEPDIR/lib\""
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

"$SRCDIR/configure" --prefix="$IDIR" $CONFIGOPTS \
  --enable-cross-compile --arch="i386" --cpu="i686" --target-os="darwin" \
  --cc="$DEV/usr/bin/gcc-4.0" \
  --cxx="$DEV/usr/bin/g++-4.0" \
  --ld="$DEV/usr/bin/g++-4.0" \
  --extra-cflags="$FLAGS -I\"$DEPDIR/include\"" \
  --extra-cxxflags="$FLAGS -I\"$DEPDIR/include\"" \
  --extra-ldflags="$FLAGS -L\"$DEPDIR/lib\""
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

"$SRCDIR/configure" --prefix="$IDIR" $CONFIGOPTS \
  --enable-cross-compile --arch="x86_64" --cpu="x86_64" --target-os="darwin" \
  --cc="$DEV/usr/bin/gcc-4.2" \
  --cxx="$DEV/usr/bin/g++-4.2" \
  --ld="$DEV/usr/bin/g++-4.2" \
  --extra-cflags="$FLAGS -I\"$DEPDIR/include\"" \
  --extra-cxxflags="$FLAGS -I\"$DEPDIR/include\"" \
  --extra-ldflags="$FLAGS -L\"$DEPDIR/lib\""
make
make install

# Done with compiling
rm -r "$COMPILEDIR"

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
  
  # merge headers
  HNAME="$FDIR/Headers"
  mkdir -p "$HNAME"
  cd "$INSTALLDIR/i386/include"
  for hfile in `find $lib -type f`; do
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
