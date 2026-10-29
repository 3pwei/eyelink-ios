#!/bin/bash
set -euo pipefail
[[ "$(uname -s)" == Darwin ]] || { echo 'XcodeGen requires macOS'; exit 1; }
root="$(cd "$(dirname "$0")/.." && pwd)"
destination="$root/build/tools"
mkdir -p "$destination"
archive="$destination/xcodegen-2.44.1.zip"
curl --fail --location --retry 2 --connect-timeout 15 --max-time 120 \
  https://github.com/yonaskolb/XcodeGen/releases/download/2.44.1/xcodegen.zip \
  --output "$archive"
# Digest from the upstream release asset API; do not substitute an unpinned brew install.
printf '%s  %s\n' a2e905fb68446e9bb4008cdfe2e13e3f176d0cbcca828b71770f8e53fca91b73 "$archive" | shasum -a 256 -c -
unzip -q -o "$archive" -d "$destination"
"$destination/xcodegen/bin/xcodegen" --version
