#!/bin/bash

SIGNATURE="$1"

RELDIR=`pwd`
PKGDIR="$RELDIR/objs"
if [ -d "$PKGDIR" ]; then rm -r "$PKGDIR"; fi
mkdir "$PKGDIR"
LICDIR="$PKGDIR/Licenses"
mkdir "$LICDIR"
ln -s /Library/Frameworks "$PKGDIR/Install to Frameworks"

# Static libraries
for DIR in ogg vorbis vpx; do
  cd ../$DIR
  ./build.sh
  if [ -f "License.txt" ]; then
    cp "License.txt" "$LICDIR/$DIR License.txt"
  fi
  cd "$RELDIR"
done

# Frameworks (binary and source)
for DIR in sdl2 sdl2_image sdl2_net sdl2_ttf \
           boost ffmpeg jpeg png speex speexdsp webp zziplib; do
  cd ../$DIR
  ./build.sh
  for FWK in *.framework; do
    rsync -rlt "$FWK" "$PKGDIR/"
    if [ -f "License.txt" ]; then
      cp "License.txt" "$LICDIR/${FWK%.framework} License.txt"
    fi
  done
  cd "$RELDIR"
done

# create dmg
VERSION=`date +'%Y%m%d'`
DMGPATH="aleph-mac-frameworks-$VERSION.dmg"
if [ -f "$DMGPATH" ]; then rm "$DMGPATH"; fi
hdiutil create -ov -fs HFS+ -format ULFO -layout GPTSPUD -srcfolder "$PKGDIR" -volname "Aleph One Frameworks $VERSION" "$DMGPATH"
if [ "$SIGNATURE" == "" ]; then
  echo "No signature provided. Disk image is unsigned."
else
  codesign -s "$SIGNATURE" "$DMGPATH"
  spctl -a -t open --context context:primary-signature -v "$DMGPATH"
fi

rm -r "$PKGDIR"
