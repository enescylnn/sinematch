#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
API_URL="${1:-}"
./scripts/bootstrap_platforms.sh
flutter clean
flutter pub get
if [ -n "$API_URL" ]; then
  flutter build appbundle --release --dart-define="SINEMATCH_API_URL=$API_URL"
else
  flutter build appbundle --release
fi
mkdir -p dist
cp build/app/outputs/bundle/release/app-release.aab dist/SineMatch-v1.0.0.aab
