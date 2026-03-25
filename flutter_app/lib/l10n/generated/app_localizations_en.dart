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

  @override
  String get studentHomepage => 'Student Homepage';

  @override
  String get fptExamManagement => 'FPT Exam Management';

  @override
  String get secureExamSystem => 'Secure Examination Management System';

  @override
  String get copyright => '© 2026 FPT University. All rights reserved.';

  @override
  String get loggingIn => 'Logging in...';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInGoogle => 'Sign in with your Google account to continue';

  @override
  String get loginWithGoogle => 'Login with Google';

  @override
  String get useFptEmail =>
      'Please use your FPT University email (@fpt.edu.vn)';

  @override
  String get examSchedule => 'Exam Schedule';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get allExams => 'All Exams';

  @override
  String get noExamsFound => 'No exams found';

  @override
  String pageOf(int currentPage, int totalPages) {
    return 'Page $currentPage of $totalPages';
  }

  @override
  String get today => 'Today';

  @override
  String get verifyIdentity => 'Verify your identity (2 steps)';

  @override
  String get readyToVerify => 'Ready to verify your identity?';

  @override
  String get step1Title => 'Scan your face';

  @override
  String get step1Desc =>
      'Make sure your face is clearly visible.\n(No glasses, hat, or mask)';

  @override
  String get step2Title => 'Capture both sides of your ID';

  @override
  String get step2Desc => 'Take photos of the front and back of your ID card.';

  @override
  String get continueText => 'Continue';

  @override
  String get home => 'Home';

  @override
  String get schedule => 'Schedule';

  @override
  String get notification => 'Notification';

  @override
  String get allDates => 'All Dates';

  @override
  String proctorLabel(String name) {
    return 'Proctor: $name';
  }

  @override
  String roomLabel(String name) {
    return 'Room: $name';
  }

  @override
  String get myExams => 'My Exams';

  @override
  String get studentAccessDenied =>
      'Students cannot view exam session details. Only proctors have access.';

  @override
  String get tba => 'TBA';

  @override
  String get filterExams => 'Filter Exams';

  @override
  String get subject => 'Subject';

  @override
  String get selectSubject => 'Select Subject';

  @override
  String get loadingSubjects => 'Loading subjects...';

  @override
  String get noSubjectsAvailable => 'No subjects available';

  @override
  String get examRoom => 'Exam Room';

  @override
  String get loadingRooms => 'Loading rooms...';

  @override
  String get noRoomsAvailable => 'No rooms available';

  @override
  String get assigneeProctor => 'Assignee (Proctor)';

  @override
  String get assignee => 'Assignee';

  @override
  String get loadingProctors => 'Loading proctors...';

  @override
  String get noProctorsAvailable => 'No proctors available';

  @override
  String get examDate => 'Exam Date';

  @override
  String get selectDate => 'Select Date';

  @override
  String get clearAll => 'Clear All';

  @override
  String get applyResults => 'Apply Results';

  @override
  String searchPlaceholder(String title) {
    return 'Search $title...';
  }

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get clearSelection => 'Clear Selection';

  @override
  String get proctorExamDetail => 'Proctor - Exam Session Detail';

  @override
  String get examDetail => 'Exam Session Detail';

  @override
  String get sessionNotFound => 'Exam session not found';

  @override
  String get sessionDetails => 'Session Details';

  @override
  String get semester => 'Semester';

  @override
  String get total => 'Total';

  @override
  String get present => 'Present';

  @override
  String get absent => 'Absent';

  @override
  String get seatingPlanNotAvailable => 'Seating plan not available';

  @override
  String get teacherDesk => 'TEACHER DESK / ENTRANCE';

  @override
  String seatLabel(String number) {
    return 'Seat $number';
  }

  @override
  String get studentId => 'Student ID';

  @override
  String get status => 'Status';

  @override
  String get checkinTime => 'Check-in Time';

  @override
  String get faCheckin => 'FA Checkin';

  @override
  String get createTicket => 'Create Ticket';

  @override
  String get available => 'Available';

  @override
  String get occupied => 'Occupied';

  @override
  String durationMins(int minutes) {
    return 'Duration: $minutes mins';
  }

  @override
  String get campusExamination => 'Campus examination';

  @override
  String get examInProgress => 'Exam is currently in progress';

  @override
  String get checkinNote => 'Check-in 15 minutes before exam starts';

  @override
  String get ongoing => 'Ongoing';

  @override
  String get completed => 'Completed';

  @override
  String get unknown => 'Unknown';

  @override
  String get lookStraight => 'Look straight into the camera';

  @override
  String get putFaceInFrame => 'Please put your face in the frame';

  @override
  String get blinkToAuthenticate => '👁️ Please blink to authenticate';

  @override
  String holdStill(int count, int total) {
    return '✓ Hold still... $count/$total';
  }

  @override
  String get authenticatingFace => 'Authenticating face...';

  @override
  String get authSuccessful => 'Authentication successful!';

  @override
  String get authFailed => 'Authentication failed';

  @override
  String get authFailedTitle => 'Authentication failed!';

  @override
  String get timeoutTryAgain => 'Timeout (30 seconds). Please try again.';

  @override
  String confidenceLabel(String confidence) {
    return 'Confidence: $confidence%';
  }

  @override
  String get complete => 'Complete';

  @override
  String get retry => 'Retry';

  @override
  String get backToMenu => 'Back to menu';

  @override
  String get blinkToContinue => 'BLINK TO CONTINUE';

  @override
  String get notInExamRoom => 'Student does not belong to this exam room!';

  @override
  String get faceNotRecognized => 'Face not recognized. Please try again.';

  @override
  String get thisWeek => 'This Week';

  @override
  String get all => 'All';

  @override
  String get past => 'Past';

  @override
  String get notAssigned => 'Not Assigned';

  @override
  String get proctorOfficer => 'Exam Officer';

  @override
  String get generalSchedule => 'Exam Schedule';

  @override
  String get proctorProfile => 'Proctor Profile';

  @override
  String get department => 'Department';

  @override
  String get campus => 'Campus';

  @override
  String get deviceRegistration => 'Device Registration';

  @override
  String get deviceRegistrationDesc =>
      'Register your device to enable secure proctoring and monitoring.';

  @override
  String get security => 'Security';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get examinationDepartment => 'Examination Department';

  @override
  String get hoChiMinhCampus => 'FPT University - Ho Chi Minh Campus';

  @override
  String get active => 'Active';

  @override
  String get pending => 'Pending';

  @override
  String get deviceActiveDesc => 'Device is registered and active.';

  @override
  String get devicePendingDesc => 'Device is registered and pending approval.';

  @override
  String get myDeviceList => 'My Device List';

  @override
  String get confirm => 'Confirm';

  @override
  String get registerDeviceTitle => 'Register Device';

  @override
  String get registerDeviceConfirm => 'Do you want to register this device?';

  @override
  String get deviceRegisteredSuccess => 'Device registration submitted.';

  @override
  String registerDeviceFailed(String error) {
    return 'Register device failed: $error';
  }

  @override
  String get changePassword => 'Change Password';

  @override
  String get changePasswordDesc => 'Update your account password';

  @override
  String get twoFactorAuth => 'Two-Factor Authentication';

  @override
  String get twoFactorAuthDesc => 'Add an extra layer of security';

  @override
  String get deviceManagement => 'Device Management';

  @override
  String get deviceManagementDesc => 'Manage trusted devices';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get helpCenterDesc => 'Get help with using the app';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicyDesc => 'Read our privacy policy';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get contactUsDesc => 'Contact our support team';

  @override
  String get technicalSupport => 'Technical Support';

  @override
  String get technicalSupportDesc => 'Get help with system issues';

  @override
  String get proctorGuidelines => 'Proctor Guidelines';

  @override
  String get proctorGuidelinesDesc => 'Review examination procedures';

  @override
  String get reportIssue => 'Report Issue';

  @override
  String get reportIssueDesc => 'Report technical or procedural issues';
}
