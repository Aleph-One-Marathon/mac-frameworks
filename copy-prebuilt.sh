#!/bin/bash

if [ "$DLNAME" == "" ]; then DLNAME="${URL##*/}"; fi

# grab dmg
if [ ! -f "$DLNAME" ]; then
  curl -L -o "$DLNAME" "$URL"
fi

# mount dmg
DMGROOT=`hdiutil attach "$DLNAME" | tail -1 | cut -f 3 -d $'\t'`

# copy files
rsync -rlt "$DMGROOT"/*.framework ./

if [ "$LICENSE" != "" ]; then
  if [ -f "$DMGROOT/$LICENSE" ]; then
    cp "$DMGROOT/$LICENSE" "License.txt"
  fi
fi

# unmount dmg
diskutil unmount "$DMGROOT"
