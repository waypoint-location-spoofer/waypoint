#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Build this project on a Mac with Xcode installed."
  exit 1
fi
if ! xcrun --find xcodebuild >/dev/null 2>&1; then
  echo "Install full Xcode, open it once, and select it under Xcode > Settings > Locations."
  exit 1
fi

mkdir -p build
build_dir="$(mktemp -d "$PWD/build/waypoint.XXXXXX")"
echo "Building an unsigned IPA in $build_dir"
xcodebuild archive \
  -project StikDebug.xcodeproj \
  -scheme StikDebug \
  -configuration Debug \
  -archivePath "$build_dir/Waypoint.xcarchive" \
  -destination 'generic/platform=iOS' \
  -sdk iphoneos \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  ONLY_ACTIVE_ARCH=NO \
  SWIFT_OPTIMIZATION_LEVEL=-Onone
mkdir -p "$build_dir/Payload"
ditto "$build_dir/Waypoint.xcarchive/Products/Applications/StikDebug.app" "$build_dir/Payload/StikDebug.app"
(cd "$build_dir" && /usr/bin/zip -qr Waypoint-unsigned.ipa Payload)
echo "Created $build_dir/Waypoint-unsigned.ipa"
echo "This IPA still needs signing with your Apple ID before installation."
open -R "$build_dir/Waypoint-unsigned.ipa"
