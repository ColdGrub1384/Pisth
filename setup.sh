#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $DIR

# Get ios_system release URL

ios_system="$(curl -s 'https://api.github.com/repos/holzschu/ios_system/releases/latest' \
| grep browser_download_url | cut -d '"' -f 4)"
ios_system=' ' read -r -a array <<< "$ios_system"

for url in $ios_system
do
if [[ "$url" == *release.tar.gz ]]
then
ios_system=$url
fi
done

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

# Download and setup ios_system

curl -L $ios_system -o ios_system.tar.gz
tar -xzf ios_system.tar.gz -Cios_system_builds/
mv ios_system_builds/release/* ios_system_builds/
rm -rf ios_system_builds/release
rm ios_system.tar.gz

# Download and setup xterm.js

curl -L $xtermjs -o xtermjs.zip
unzip xtermjs.zip -d "Pisth Terminal/Pisth Terminal/"
rm xtermjs.zip

# Download Pisth Viewer for embedding it into Pisth Mac

curl -L "https://pisth.github.io/PisthViewer/Pisth%20Viewer.zip" -o viewer.zip
rm -rf "Pisth Mac/Pisth Viewer.app"
unzip viewer.zip -d "Pisth Mac/"

# Update submodules

git submodule update --init --recursive

# Install pods

pod install
