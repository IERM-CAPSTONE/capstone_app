

## Cấu trúc dự án

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── routes/
├── data/
│   ├── models/
│   ├── services/
│   └── repositories/
├── features/
│   ├── auth/
│   ├── home/
│   └── attendance/
├── shared/
│   ├── widgets/
│   └── dialogs/
└── config/
```

## Cài đặt

1. Cài đặt dependencies:
```bash
flutter pub get
```

2. Generate code (cho các file có annotation):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. Chạy ứng dụng:
```bash
flutter run
```

## Firebase Auth setup (Google Sign-In)

Use one Firebase project only for the mobile app. Mixing multiple projects causes login to fail.

1. Firebase Console
- Open your Firebase project.
- Enable Authentication -> Sign-in method -> Google.

2. Android app registration
- Android package name must match exactly: `com.example.flutter_app`.
- Add SHA-1 and SHA-256 for both debug and release keystores.
- Download `google-services.json` and place it at:
	`android/app/google-services.json`

3. FlutterFire config
- Run:
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=capstone-89804 --platforms=android,ios,web
```
- This regenerates `lib/firebase_options.dart` to match your Firebase project.

4. iOS (required if you run on iPhone)
- Add `GoogleService-Info.plist` to `ios/Runner/`.
- Ensure Bundle ID in Xcode matches Firebase iOS app Bundle ID.

5. Verify
- Clean and run:
```bash
flutter clean
flutter pub get
flutter run
```

If Google Sign-In still fails on Android, it is usually due to missing SHA keys or a package name mismatch in Firebase Console.


