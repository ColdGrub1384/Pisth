#!/bin/bash

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

# Download and setup ios_system

curl $ios_system -o ios_system.tar.gz
tar xf ios_system.tar.gz ios_system_builds/
