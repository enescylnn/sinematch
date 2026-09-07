#!/usr/bin/env bash
set -euo pipefail

API_URL="${1:-}"
if [[ -z "$API_URL" ]]; then
  echo "Kullanım: ./build_ios.sh https://site-demo.com.tr"
  exit 1
fi

if [[ "$(uname)" != "Darwin" ]]; then
  echo "iOS build macOS + Xcode gerektirir."
  exit 1
fi

cd "$(dirname "$0")/../app"
flutter create . --platforms=android,ios --org com.sinematch --project-name sinematch
flutter pub get
dart run flutter_launcher_icons
flutter build ipa --release --dart-define=SINEMATCH_API_URL="$API_URL"

echo "IPA çıktısı: app/build/ios/ipa/"
