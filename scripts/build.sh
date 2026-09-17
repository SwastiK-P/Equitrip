#!/usr/bin/env bash
#
# Quiet xcodebuild wrapper. A raw build prints ~5,000 lines (~1 MB); this prints
# errors, warnings in files you've changed, and a one-line result.
#
#   scripts/build.sh                 # scheme Equitrip (also builds widgets + watch app)
#   scripts/build.sh --all-warnings  # list every warning, not just ones in changed files
#   scripts/build.sh EquitripWidgets # any scheme from `xcodebuild -list`
#
# Full log: build/last-build.log. Exit code is xcodebuild's.

set -uo pipefail
cd "$(dirname "$0")/.."

scheme="Equitrip"
all_warnings=0
for arg in "$@"; do
  case "$arg" in
    --all-warnings) all_warnings=1 ;;
    -*) echo "unknown flag: $arg" >&2; exit 2 ;;
    *) scheme="$arg" ;;
  esac
done

case "$scheme" in
  *Watch*) destination="generic/platform=watchOS Simulator" ;;
  *) destination="generic/platform=iOS Simulator" ;;
esac

log="build/last-build.log"
mkdir -p build
started=$(date +%s)

xcodebuild -project Equitrip.xcodeproj -scheme "$scheme" \
  -destination "$destination" -derivedDataPath build/dd build >"$log" 2>&1
status=$?

root="$PWD/"
diagnostics=$(grep -E "(^|: )(error|warning): |^ld: |^Undefined symbols" "$log" \
  | sed "s#$root##g" | sort -u)
errors=$(grep -E "error: |^ld: |^Undefined symbols" <<<"$diagnostics" || true)
warnings=$(grep -E ": warning: " <<<"$diagnostics" | grep -v "^warning: " || true)

if [[ -n "$errors" ]]; then
  echo "$errors"
fi

warning_count=0
[[ -n "$warnings" ]] && warning_count=$(wc -l <<<"$warnings" | tr -d ' ')

if (( all_warnings )); then
  [[ -n "$warnings" ]] && echo "$warnings"
elif [[ -n "$warnings" ]]; then
  changed=$(git status --porcelain --untracked-files=all | sed -E 's/^.. //; s/.* -> //' | grep '\.swift$' || true)
  if [[ -n "$changed" ]]; then
    grep -F -f <(sed 's/$/:/' <<<"$changed") <<<"$warnings" || true
  fi
fi

elapsed=$(( $(date +%s) - started ))
if (( status == 0 )); then
  # Only files the compiler touched this run report warnings, so a cached build shows fewer.
  echo "BUILD SUCCEEDED ($scheme, ${elapsed}s, $warning_count warnings in recompiled files — --all-warnings to list)"
else
  if [[ -z "$errors" ]]; then
    grep -A20 "The following build commands failed" "$log" | head -25
  fi
  echo "BUILD FAILED ($scheme, ${elapsed}s) — full log: $log"
fi
exit $status
