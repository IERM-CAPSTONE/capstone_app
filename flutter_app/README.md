

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


