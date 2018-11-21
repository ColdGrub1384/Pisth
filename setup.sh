#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $DIR

# Get the built xterm.js URL

xtermjs="$(curl -s 'https://api.github.com/repos/ColdGrub1384/Pisth/releases/latest' \
| grep browser_download_url | cut -d '"' -f 4)"
xtermjs=' ' read -r -a array <<< "$xtermjs"

for url in $xtermjs
do
if [[ "$url" == *xtermjs.zip ]]
then
xtermjs=$url
fi
done

# Download and setup xterm.js

curl -L $xtermjs -o xtermjs.zip
unzip xtermjs.zip -d "Pisth Terminal/Pisth Terminal/"
rm xtermjs.zip

# Download Pisth Viewer for embedding it into Pisth Mac

curl -L "https://pisth.github.io/PisthViewer/Pisth%20Viewer.zip" -o viewer.zip
rm -rf "Pisth Mac/Pisth Viewer.app"
unzip viewer.zip -d "Pisth Mac/"
rm viewer.zip

# Update submodules

git submodule update --init --recursive

# Install pods

pod install
cd "Pisth APT"
pod install
