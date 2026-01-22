# Debug Pose Detection

## Các thay đổi đã thực hiện để tối ưu

### 1. Tối ưu hiệu suất (Giảm lag)
- ✅ Camera resolution: `ResolutionPreset.low`
- ✅ Processing interval: `800ms` (1.25 lần/giây)
- ✅ Frame skipping: Chỉ xử lý 1/2 frames
- ✅ Tắt `enableClassification` (không cần eye open probability)
- ✅ Bật `enableLandmarks` (CẦN THIẾT cho head pose chính xác)

### 2. Điều chỉnh ngưỡng pose (Dễ bắt hơn)

**Ngưỡng hiện tại:**
```dart
_hMin = 12.0           // LEFT/RIGHT: cần quay đầu ít nhất 12°
_vUpMin = 8.0          // UP: cần ngửa đầu ít nhất 8°
_vDownMin = 12.0       // DOWN: cần cúi đầu ít nhất 12°
_centerThreshold = 8.0 // CENTER: cho phép lệch ±8°
```

### 3. Cách điều chỉnh nếu vẫn khó bắt pose

#### Nếu khó bắt "Nhìn trái/phải":
Giảm `_hMin` xuống `10.0` hoặc `8.0`:
```dart
static const double _hMin = 10.0; // Giảm xuống để dễ bắt hơn
```

#### Nếu khó bắt "Ngửa đầu":
Giảm `_vUpMin` xuống `6.0`:
```dart
static const double _vUpMin = 6.0;
```

#### Nếu khó bắt "Cúi đầu":
Giảm `_vDownMin` xuống `10.0`:
```dart
static const double _vDownMin = 10.0;
```

#### Nếu khó bắt "Nhìn thẳng":
Tăng `_centerThreshold` lên `10.0`:
```dart
static const double _centerThreshold = 10.0;
```

### 4. Debug thực tế

Thêm dòng này vào hàm `_detectFace()` để xem giá trị góc thực tế:
```dart
final headY = face.headEulerAngleY ?? 0;
final headX = face.headEulerAngleX ?? 0;

// Thêm dòng này để debug
debugPrint('HeadPose: Y=$headY, X=$headX, Required=${state.currentPose}');
```

**Cách đọc:**
- `Y < 0` = Quay TRÁI
- `Y > 0` = Quay PHẢI
- `X > 0` = Ngửa đầu (UP)
- `X < 0` = Cúi đầu (DOWN)
- `Y ≈ 0, X ≈ 0` = Nhìn thẳng (CENTER)

### 5. Nếu vẫn còn lag

**Tăng interval lên 1000ms:**
```dart
_detectionTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
```

**Skip nhiều frames hơn (xử lý 1/3 frames):**
```dart
if (_frameCounter % 3 != 0) return;
```

**Giảm resolution xuống veryLow:**
```dart
ResolutionPreset.veryLow,
```

### 6. So sánh với Backend

Backend Python sử dụng ngưỡng:
- LEFT/RIGHT: ±5°
- UP: 5°
- DOWN: -8°
- CENTER: ±5°

Flutter app đã điều chỉnh cao hơn để dễ bắt hơn trong giao diện người dùng.

## Kiểm tra hiệu suất

Sau khi áp dụng các tối ưu:
- [ ] App không còn giật lag khi scan
- [ ] Có thể bắt được cả 5 pose (center, left, right, up, down)
- [ ] Thời gian phản hồi < 1 giây khi làm đúng pose
- [ ] Camera preview mượt mà

## Ghi chú

- Nếu bạn muốn **độ chính xác cao hơn**: Tăng các ngưỡng lên
- Nếu bạn muốn **dễ sử dụng hơn**: Giảm các ngưỡng xuống
- **Cân bằng tốt nhất**: Giữ nguyên như hiện tại
