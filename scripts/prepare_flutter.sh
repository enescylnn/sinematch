#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../app"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter bulunamadı. Flutter 3.47+ kurun."
  exit 1
fi

flutter create . --platforms=android,ios --org com.sinematch --project-name sinematch
flutter pub get
dart run flutter_launcher_icons

echo
echo "Hazır. Çalıştırma örneği:"
echo "flutter run --dart-define=SINEMATCH_API_URL=https://site-demo.com.tr"
