#!/usr/bin/env bash
#
# Build, install and launch the iOS app on a simulator.
#
#   scripts/run.sh                    # the booted simulator, else "iPhone 17 Pro"
#   scripts/run.sh "iPhone Air"       # any name from `xcrun simctl list devices available`

set -euo pipefail
cd "$(dirname "$0")/.."

booted=$(xcrun simctl list devices booted | sed -nE 's/^ +(.+) \([0-9A-F-]{36}\) \(Booted\).*/\1/p' | head -1)
device="${1:-${booted:-iPhone 17 Pro}}"
bundle_id="com.swastik.Equitrip"
app="build/dd/Build/Products/Debug-iphonesimulator/Equitrip.app"

scripts/build.sh Equitrip

xcrun simctl boot "$device" 2>/dev/null || true
# Newer Xcodes ship no Simulator.app; the device runs headless without it.
open -a Simulator 2>/dev/null || true
xcrun simctl install "$device" "$app"
xcrun simctl launch "$device" "$bundle_id" >/dev/null
echo "LAUNCHED $bundle_id on $device"
