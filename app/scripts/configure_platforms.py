from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]

# Android application/bundle identity and label.
build = root / 'android/app/build.gradle.kts'
if build.exists():
    s = build.read_text()
    s = re.sub(r'namespace\s*=\s*"[^"]+"', 'namespace = "com.sinematch.app"', s)
    s = re.sub(r'applicationId\s*=\s*"[^"]+"', 'applicationId = "com.sinematch.app"', s)
    s = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 24', s)
    build.write_text(s)

manifest = root / 'android/app/src/main/AndroidManifest.xml'
if manifest.exists():
    s = manifest.read_text()
    if 'android.permission.INTERNET' not in s:
        s = s.replace('<manifest xmlns:android="http://schemas.android.com/apk/res/android">',
                      '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n    <uses-permission android:name="android.permission.INTERNET" />')
    s = re.sub(r'android:label="[^"]*"', 'android:label="SineMatch"', s)
    if 'android:allowBackup=' not in s:
        s = s.replace('<application\n', '<application\n        android:allowBackup="false"\n')
    manifest.write_text(s)

# MainActivity package may be generated as com.sinematch.sinematch.
kotlin_root = root / 'android/app/src/main/kotlin'
if kotlin_root.exists():
    for f in kotlin_root.rglob('MainActivity.kt'):
        s = f.read_text()
        s = re.sub(r'^package\s+[^\n]+', 'package com.sinematch.app', s, flags=re.M)
        target = kotlin_root / 'com/sinematch/app/MainActivity.kt'
        target.parent.mkdir(parents=True, exist_ok=True)
        if f.resolve() != target.resolve():
            target.write_text(s)
            f.unlink()
        else:
            f.write_text(s)

# iOS bundle identity and visible name.
pbx = root / 'ios/Runner.xcodeproj/project.pbxproj'
if pbx.exists():
    s = pbx.read_text().replace('com.sinematch.sinematch', 'com.sinematch.app')
    pbx.write_text(s)

plist = root / 'ios/Runner/Info.plist'
if plist.exists():
    s = plist.read_text()
    s = s.replace('<string>sinematch</string>', '<string>SineMatch</string>')
    plist.write_text(s)

print('SineMatch platform configuration applied.')
