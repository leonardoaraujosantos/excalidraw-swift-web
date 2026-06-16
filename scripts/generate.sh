#!/usr/bin/env bash
#
# (Re)generate the Xcode project from project.yml. The .xcodeproj is gitignored
# and derived from the SwiftPM package, so it must be regenerated after any
# change to Package.swift (new targets/products) or project.yml. Run this if
# Xcode reports "Missing package product".
set -euo pipefail
cd "$(dirname "$0")/.."

command -v xcodegen >/dev/null || { echo "Install XcodeGen: brew install xcodegen"; exit 1; }

xcodegen generate
xcodebuild -resolvePackageDependencies -project ExcalidrawSwift.xcodeproj -scheme ExcalidrawApp >/dev/null
echo "Generated ExcalidrawSwift.xcodeproj. If Xcode is open, close and reopen it"
echo "(or File ▸ Packages ▸ Reset Package Caches)."
