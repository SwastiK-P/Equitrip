#!/usr/bin/env bash
#
# Copies the phone's avatar artwork into the watch's asset catalogue at wrist
# size. The phone's set is 512px (~300 KB each, 4.3 MB together); the watch
# never draws a face wider than ~40pt, so 120px is sharp at 2x and the whole
# set costs the watch bundle a few dozen KB instead.
#
# Rerun after adding or changing anything in Equitrip/Assets.xcassets/Avatars.
#
#   scripts/watch-avatars.sh

set -euo pipefail
cd "$(dirname "$0")/.."

src="Equitrip/Assets.xcassets/Avatars"
dst="EquitripWatch Watch App/Assets.xcassets/Avatars"

rm -rf "$dst"
mkdir -p "$dst"
cp "$src/Contents.json" "$dst/Contents.json"

for set in "$src"/*.imageset; do
  name=$(basename "$set" .imageset)
  mkdir -p "$dst/$name.imageset"
  cp "$set/Contents.json" "$dst/$name.imageset/Contents.json"
  sips -Z 120 "$set/$name.png" --out "$dst/$name.imageset/$name.png" >/dev/null
done

echo "$(ls -d "$dst"/*.imageset | wc -l | tr -d ' ') avatars → $dst ($(du -sh "$dst" | cut -f1))"
