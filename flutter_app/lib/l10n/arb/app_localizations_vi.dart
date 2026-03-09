// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get profile => 'Hồ sơ';

  @override
  String get personalInformation => 'Thông tin cá nhân';

  @override
  String get email => 'Email';

  @override
  String get faceRecognition => 'Nhận diện khuôn mặt';

  @override
  String get faceRegistration => 'Đăng ký khuôn mặt';

  @override
  String get registered => 'Đã đăng ký';

  @override
  String get notRegistered => 'Chưa đăng ký';

  @override
  String get faceRegisteredDesc =>
      'Dữ liệu khuôn mặt của bạn đã được đăng ký. Bạn có thể điểm danh phòng thi bằng khuôn mặt.';

  @override
  String get faceNotRegisteredDesc =>
      'Vui lòng đăng ký dữ liệu khuôn mặt để có thể điểm danh nhanh chóng.';

  @override
  String get updateFaceData => 'Cập nhật khuôn mặt';

  @override
  String get enrollFaceIdentity => 'Đăng ký khuôn mặt';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get logoutConfirm => 'Bạn có chắc chắn muốn đăng xuất không?';

  @override
  String get cancel => 'Hủy';

  @override
  String get settings => 'Cài đặt';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get english => 'Tiếng Anh';
}
