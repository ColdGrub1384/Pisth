Follow [@pisthapp](https://twitter.com/pisthapp) on Twitter for news about this project and commits.

![mockup](https://pisth.github.io/mockup.png)


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
  • The terminal supports Bluetooth keyboard including arrows and ctrl keys but excluding function keys.
  • Open multiple panels in iPad.
  • Find your connections with Spotlight.
  • Share shell session between other devices using Pisth or your Mac.
  • Transfer files between servers.
  • Find servers with Bonjour.
```

![status](https://img.shields.io/badge/status-stable-green.svg)
![iOS](https://img.shields.io/badge/iOS-10.0%2B-green.svg)
[![Build status](https://build.appcenter.ms/v0.1/apps/3ba4cc7e-7510-4345-b79e-e09b8b046f38/branches/master/badge)](https://appcenter.ms)

## Screenshots
![Screenshots](https://pisth.github.io/ios/screenshots.png)

![Icon](https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/Pisth%20Mac/Assets.xcassets/AppIcon.appiconset/Pisth-128%401x.png)

# Pisth Mac

![status](https://img.shields.io/badge/status-In%20development-red.svg)
![macOS](https://img.shields.io/badge/macOS-10.14%2B-green.svg)

## Screenshots
![Screenshots](https://pisth.github.io/mac/screenshot.png)

![Icon](https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/Pisth%20APT/Pisth%20APT/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60%402x.png)

# Pisth APT

[![Download on the App Store](https://pisth.github.io/appstorebadge.svg)](https://itunes.apple.com/us/app/pisth-apt/id1369552277?ls=1&mt=8)


```
From the developer of Pisth! Pisth APT allows you to manage your packages on Debian based Linux distro from your iPhone or iPad using SSH.

Why use Pisth APT:

• Pisth APT is free (but there are ads).
• You can easily browse, install, uninstall and update pakages.
```

![status](https://img.shields.io/badge/status-stable-green.svg)
![iOS](https://img.shields.io/badge/iOS-11.0%2B-green.svg)

## Screenshots
![Screenshots](https://pisth.github.io/apt/screenshots.png)

# Pisth Viewer

![screenshot](https://github.com/Pisth/pisth.github.io/raw/master/PisthViewer/screenshot.png)

Pisth Viewer allows you to share a terminal opened with Pisth in iOS from your Mac.

## How does it work?

Just open a terminal in [Pisth](https://pisth.github.io), and your iOS device will appear in Pisth Viewer if both Mac and iOS device are connected to the same network. You can also write from the macOS app.

# API

[![Documentation](https://pisth.github.io/docs/badge.svg)](https://pisth.github.io/docs)

Pisth has an API that allows iOS apps to import files from Pisth.

More information at https://pisth.github.io/docs/getting-started.html.

# Project hierarchy

- [Pisth Shared/](Pisth%20Shared/): Shared sources between targets.
- [Pisth Terminal/](Pisth%20Terminal/): HTML page for displaying the terminal.
- [Pisth/](Pisth): iOS Application.
- [Pisth Mac/](Pisth%20Mac/): macOS Applications.
- [Pisth Viewer/](Pisth%20Viewer/): Pisth Viewer macOS Application.
- [Pisth API/](Pisth%20API/): API for iOS.
- [Pisth APT/](Pisth%20APT/): iOS Aptitude package manager.

## Building project

1. Download release.tar.gz from [ios_system latest release](https://github.com/$
2. Unarchive the file.
3. Move ios_system to the repo.
4. Just build any target you want from `Pisth.xcworkspace`.

# Projects

- [Pisth/pisth.github.io](https://github.com/Pisth/pisth.github.io): Page for this project.
- [Pisth/docs](https://github.com/Pisth/docs): Documentation for the API.
- [Pisth/meta](https://github.com/Pisth/meta): Metadata for App Store Connect.
- [Pisth/Licenses](https://github.com/Pisth/Licenses): Open source licenses used in the project.
