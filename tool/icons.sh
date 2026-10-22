#!/bin/sh
# Resizes build/icons/*.png into the iOS and Android launcher icon slots.
set -e
ios=ios/Runner/Assets.xcassets/AppIcon.appiconset
for f in "$ios"/Icon-App-*.png; do
  px=$(sips -g pixelWidth "$f" | awk '/pixelWidth/ {print $2}')
  sips -s format png -z "$px" "$px" build/icons/ios_1024.png --out "$f" >/dev/null
  # App Store rejects icons with an alpha channel; flatten via JPEG round-trip.
  sips -s format jpeg "$f" --out /tmp/vitalog_icon.jpg >/dev/null
  sips -s format png /tmp/vitalog_icon.jpg --out "$f" >/dev/null
done
for d in android/app/src/main/res/mipmap-*; do
  f="$d/ic_launcher.png"
  px=$(sips -g pixelWidth "$f" | awk '/pixelWidth/ {print $2}')
  sips -s format png -z "$px" "$px" build/icons/android_1024.png --out "$f" >/dev/null
done
for f in web/icons/*.png web/favicon.png; do
  [ -f "$f" ] || continue
  px=$(sips -g pixelWidth "$f" | awk '/pixelWidth/ {print $2}')
  sips -s format png -z "$px" "$px" build/icons/android_1024.png --out "$f" >/dev/null
done
echo "icons updated"
