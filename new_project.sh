#!/bin/bash
set -o errexit

proj="$1"
if [ "X$proj" = "X" ]; then
  echo "Usage: $0 <project-name>"
  exit 1
fi
if [ -e $proj ]; then
  echo "Error: project $proj already exists"
  exit 1
fi

rsync -a --exclude .svn template/ $proj/
mv $proj/template.xcodeproj $proj/$proj.xcodeproj
mv $proj/template_Prefix.pch $proj/${proj}_Prefix.pch
find $proj -type f -exec sed -i "" "s/template/$proj/g" {} \;
