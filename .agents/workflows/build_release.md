---
description: Build Khozna release APK with full security (obfuscation + minification)
---

// turbo-all

## Steps

1. Clean the build
```
flutter clean
```

2. Get packages
```
flutter pub get
```

3. Build release APK with code obfuscation (scrambles code so hackers can't read it)
```
flutter build apk --release --obfuscate --split-debug-info=build/debug-symbols
```

The output APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

> Note: The `--obfuscate` flag scrambles all class/method names in the compiled code,
> making it extremely difficult to reverse-engineer. Always use this for production builds.
> The `--split-debug-info` saves symbols separately (keep them private, needed for crash logs).
