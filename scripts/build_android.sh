#!/usr/bin/env bash
set -euo pipefail

API_URL="${1:-}"
if [[ -z "$API_URL" ]]; then
  echo "Kullanım: ./build_android.sh https://site-demo.com.tr"
  exit 1
fi

cd "$(dirname "$0")/../app"
flutter create . --platforms=android,ios --org com.sinematch --project-name sinematch
flutter pub get
dart run flutter_launcher_icons
flutter build apk --release --dart-define=SINEMATCH_API_URL="$API_URL"
flutter build appbundle --release --dart-define=SINEMATCH_API_URL="$API_URL"

echo "APK: app/build/app/outputs/flutter-apk/app-release.apk"
echo "AAB: app/build/app/outputs/bundle/release/app-release.aab"
