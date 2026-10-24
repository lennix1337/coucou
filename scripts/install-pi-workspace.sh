#!/usr/bin/env bash
# Personal macOS build: Pi workspace + Ghostty, no Apple distribution identity required.
# Uses the project's supported Debug configuration (no CloudKit/iPhone link).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
xcodebuild -checkFirstLaunchStatus
command -v xcodegen >/dev/null
mkdir -p scratchpad
(cd NotchBuddy && xcodegen generate)
xcodebuild -project NotchBuddy/NotchBuddy.xcodeproj -scheme NotchBuddy \
  -configuration Debug -derivedDataPath scratchpad/build \
  -clonedSourcePackagesDirPath scratchpad/packages build > scratchpad/pi-default-build.log 2>&1
BUILT="$ROOT/scratchpad/build/Build/Products/Debug/Coucou.app"
TARGET="/Applications/Coucou.app"
BUNDLE="fr.louisraille.NotchBuddy"
if [ -d "$TARGET" ]; then
  existing=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$TARGET/Contents/Info.plist")
  if [ "$existing" != "$BUNDLE" ]; then
    echo "Refusing to replace a different application: $existing" >&2
    exit 1
  fi
  if [ ! -d scratchpad/Coucou.previous.app ]; then
    ditto "$TARGET" scratchpad/Coucou.previous.app
  fi
fi
if pgrep -x Coucou >/dev/null; then
  osascript -e 'tell application id "fr.louisraille.NotchBuddy" to quit'
fi
if pgrep -x Coucou >/dev/null; then
  echo 'Coucou is still running; quit it before installing.' >&2
  exit 1
fi
# Copy over the existing bundle only after a successful build, preserving a rollback copy.
if [ -e scratchpad/Coucou.replaced.app ]; then
  echo 'A prior replacement needs reconciliation: scratchpad/Coucou.replaced.app' >&2
  exit 1
fi
if [ -d "$TARGET" ]; then
  mv "$TARGET" "$ROOT/scratchpad/Coucou.replaced.app"
fi
if ! ditto "$BUILT" "$TARGET"; then
  rm -rf "$TARGET"
  if [ -d scratchpad/Coucou.replaced.app ]; then
    mv scratchpad/Coucou.replaced.app "$TARGET"
  fi
  exit 1
fi
rm -rf scratchpad/Coucou.replaced.app
defaults write "$BUNDLE" mainPill -string agent_pi
open "$TARGET"
echo "Installed Pi-default Coucou. Previous app: scratchpad/Coucou.previous.app"
