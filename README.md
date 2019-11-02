![Icon](https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/Pisth/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60%402x.png)

# Pisth

[![Download on the App Store](https://pisth.github.io/appstorebadge.svg)](https://itunes.apple.com/us/app/pisth/id1331070425?ls=1&mt=8)


```
Pisth is an SSH and SFTP client.
Use Pisth to upload, view and edit files in your SSH server.

Features:

• Manage files in your SSH server and use the Shell in the same app.
• Edit text files and code with colored syntax.
• The terminal is like xterm, so you can use text editors such as nano, vim, etc. 
• SSH Keys
• Drag and drop.
• Send special keys.
• Open multiple panels in iPad.
• Find your connections with Spotlight.
• Share shell session between other devices using Pisth or your Mac.
• Transfer files between servers.
• Find servers with Bonjour.
```

![status](https://img.shields.io/badge/status-stable-green.svg)
![iOS](https://img.shields.io/badge/iOS-10.0%2B-green.svg)

## Screenshots
![Screenshots](https://pisth.github.io/ios/screenshots.png)

# API

[![Documentation](https://pisth.github.io/docs/badge.svg)](https://pisth.github.io/docs)

Pisth has an API that allows iOS apps to import files from Pisth.

More information at https://pisth.github.io/docs/getting-started.html.

# Project hierarchy

- [Pisth Shared/](Pisth%20Shared/): Shared sources between targets.
- [Pisth Terminal/](Pisth%20Terminal/): HTML page for displaying the terminal.
- [Pisth/](Pisth): iOS Application.
- [Pisth Viewer/](Pisth%20Viewer/): Pisth Viewer macOS Application.
- [Pisth API/](Pisth%20API/): API for iOS.
- [Pisth APT/](Pisth%20APT/): iOS Aptitude package manager.

# Building project

`$ ./setup.sh`
Then build any scheme you want from `Pisth.xcworkspace`.

# Projects

- [Pisth/docs](https://github.com/Pisth/docs): Documentation for the API.
- [Pisth/Licenses](https://github.com/Pisth/Licenses): Open source licenses used in the project.
