#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
API_URL="${1:-}"
./scripts/bootstrap_platforms.sh
flutter clean
flutter pub get
if [ -n "$API_URL" ]; then
  flutter build apk --release --dart-define="SINEMATCH_API_URL=$API_URL"
else
  flutter build apk --release
fi
mkdir -p dist
cp build/app/outputs/flutter-apk/app-release.apk dist/SineMatch-v1.0.0.apk
sha256sum dist/SineMatch-v1.0.0.apk > dist/SineMatch-v1.0.0.apk.sha256
printf '\nAPK: %s\n' "$(pwd)/dist/SineMatch-v1.0.0.apk"
