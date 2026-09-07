#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v flutter >/dev/null 2>&1 || { echo "Flutter SDK bulunamadı."; exit 1; }

# If this archive was unpacked before Flutter generated complete platform folders,
# recreate them from the SDK's current official templates.
if [ ! -f android/gradlew ]; then rm -rf android; fi
if [ ! -f ios/Runner.xcodeproj/project.pbxproj ]; then rm -rf ios; fi

flutter create --platforms=android,ios --org com.sinematch --project-name sinematch .
python3 scripts/configure_platforms.py
flutter pub get
dart run flutter_launcher_icons
printf '\nSineMatch Android/iOS platform files ready.\n'
