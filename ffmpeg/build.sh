#!/bin/bash

# Change this to the directory where our dependent frameworks live
DEPFWKDIR="/Library/Frameworks"

DEV="/Developer-3.2.6"
# Note: yasm must be installed; add its directory to STOCKPATH if needed
STOCKPATH="$DEV/usr/bin:/usr/bin:/bin"
SRCDIR="$PWD/src"
COMPILEDIR="$PWD/objs"
INSTALLDIR="$PWD/installs"
FWKDIR="$PWD"
CONFIGOPTS="--disable-static --enable-shared --enable-gpl --enable-libvorbis --enable-libvpx --disable-doc --disable-ffmpeg --disable-ffplay --disable-ffprobe --disable-ffserver --disable-avdevice --disable-swresample --disable-postproc --disable-avfilter --disable-everything"
CONFIGOPTS+=" --enable-muxer=webm --enable-encoder=libvorbis --enable-encoder=libvpx_vp8"
CONFIGOPTS+=" --enable-demuxer=aiff --enable-demuxer=mp3 --enable-demuxer=mpegps --enable-demuxer=mpegts --enable-demuxer=mpegtsraw --enable-demuxer=mpegvideo --enable-demuxer=ogg --enable-demuxer=wav"
CONFIGOPTS+=" --enable-parser=mpegaudio --enable-parser=mpegvideo"
CONFIGOPTS+=" --enable-decoder=adpcm_ima_wav --enable-decoder=adpcm_ms --enable-decoder=gsm --enable-decoder=gsm_ms --enable-decoder=mp1 --enable-decoder=mp1float --enable-decoder=mp2 --enable-decoder=mp2float --enable-decoder=mp3 --enable-decoder=mp3float --enable-decoder=mpeg1video --enable-decoder=pcm_alaw --enable-decoder=pcm_f32be --enable-decoder=pcm_f32le --enable-decoder=pcm_f64be --enable-decoder=pcm_f64le --enable-decoder=pcm_mulaw --enable-decoder=pcm_s8 --enable-decoder=pcm_s8_planar --enable-decoder=pcm_s16be --enable-decoder=pcm_s16le --enable-decoder=pcm_s16le_planar --enable-decoder=pcm_s24be --enable-decoder=pcm_s24le --enable-decoder=pcm_s32be --enable-decoder=pcm_s32le --enable-decoder=pcm_u8 --enable-decoder=theora --enable-decoder=vorbis --enable-decoder=vp8"
CONFIGOPTS+=" --enable-protocol=file"
FWKS=(libavcodec libavformat libavutil libswscale)


# unpack source
tar xjf ffmpeg-1.2.7.tar.bz2
mv "ffmpeg-1.2.7" "$SRCDIR"

if [ -d "$COMPILEDIR" ]; then rm -r "$COMPILEDIR"; fi
if [ -d "$INSTALLDIR" ]; then rm -r "$INSTALLDIR"; fi

# jump through hoops to make framework dependency work
DEPDIR="$COMPILEDIR/deps"
mkdir -p "$DEPDIR/lib"
mkdir -p "$DEPDIR/include"
STATICDEPS=(ogg vorbis vorbisenc vorbisfile vpx)
for lib in "${STATICDEPS[@]}"; do
  cp "$DEPFWKDIR/$lib.framework/$lib.a" "$DEPDIR/lib/lib$lib.a"
  cp -R "$DEPFWKDIR/$lib.framework/Headers/" "$DEPDIR/include"
done

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
    
    # fix links to version-specific libraries
    install_name_tool -change "$LIBDIR/libavcodec.54.dylib" "@executable_path/../Frameworks/avcodec.framework/Versions/A/avcodec" "$LIBDIR/$lib.dylib"
    install_name_tool -change "$LIBDIR/libavutil.52.dylib" "@executable_path/../Frameworks/avutil.framework/Versions/A/avutil" "$LIBDIR/$lib.dylib"
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
