#!/bin/bash

# https://github.com/create-dmg/create-dmg
if ! [ "$(which create-dmg)" ]; then
    echo "Please install: brew install create-dmg"
    exit 1
fi

if [ "$#" -ne 1 ]; then
    echo "Usage:   $0 version"
    echo "Example: $0 1.2.3"
    exit 2
fi

create-dmg \
  --volname "Tommy Player Installer" \
  --volicon "appicon.png" \
  --background "background.jpg" \
  --window-size 600 425 \
  --text-size 16 \
  --icon-size 100 \
  --icon "Tommy Player.app" 185 165 \
  --app-drop-link 405 165 \
  "tommyplayer-macos-$1.dmg" \
  "App/"
