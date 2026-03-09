// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get profile => 'Profile';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get email => 'Email';

  @override
  String get faceRecognition => 'Face Recognition';

  @override
  String get faceRegistration => 'Face Registration';

  @override
  String get registered => 'Registered';

  @override
  String get notRegistered => 'Not Registered';

  @override
  String get faceRegisteredDesc =>
      'Your face data is registered. You can check-in to exams using facial recognition.';

  @override
  String get faceNotRegisteredDesc =>
      'Please register your face data to enable fast check-in for exams.';

  @override
  String get updateFaceData => 'Update Face Data';

  @override
  String get enrollFaceIdentity => 'Enroll Face Identity';

  @override
  String get logout => 'Log out';

  @override
  String get logoutConfirm => 'Are you sure you want to log out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get vietnamese => 'Vietnamese';

  @override
  String get english => 'English';
}
