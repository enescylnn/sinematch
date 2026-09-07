#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
API_URL="${1:-}"
./scripts/bootstrap_platforms.sh
flutter clean
flutter pub get
ARGS=(ios --release --no-codesign)
if [ -n "$API_URL" ]; then ARGS+=(--dart-define="SINEMATCH_API_URL=$API_URL"); fi
flutter build "${ARGS[@]}"
echo "Unsigned iOS build created under build/ios/iphoneos/Runner.app"
