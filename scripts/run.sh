#!/usr/bin/env bash
#
# Build, install and launch the iOS app on a simulator.
#
#   scripts/run.sh                    # "iPhone 17 Pro"
#   scripts/run.sh "iPhone Air"       # any name from `xcrun simctl list devices available`

set -euo pipefail
cd "$(dirname "$0")/.."

device="${1:-iPhone 17 Pro}"
bundle_id="com.swastik.Equitrip"
app="build/dd/Build/Products/Debug-iphonesimulator/Equitrip.app"

scripts/build.sh Equitrip

xcrun simctl boot "$device" 2>/dev/null || true
open -a Simulator
xcrun simctl install "$device" "$app"
xcrun simctl launch "$device" "$bundle_id" >/dev/null
echo "LAUNCHED $bundle_id on $device"
