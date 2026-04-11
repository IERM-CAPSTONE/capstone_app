import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @faceRecognition.
  ///
  /// In en, this message translates to:
  /// **'Face Recognition'**
  String get faceRecognition;

  /// No description provided for @faceRegistration.
  ///
  /// In en, this message translates to:
  /// **'Face Registration'**
  String get faceRegistration;

  /// No description provided for @registered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get registered;

  /// No description provided for @notRegistered.
  ///
  /// In en, this message translates to:
  /// **'Not Registered'**
  String get notRegistered;

  /// No description provided for @faceRegisteredDesc.
  ///
  /// In en, this message translates to:
  /// **'Your face data is registered. You can check-in to exams using facial recognition.'**
  String get faceRegisteredDesc;

  /// No description provided for @faceNotRegisteredDesc.
  ///
  /// In en, this message translates to:
  /// **'Please register your face data to enable fast check-in for exams.'**
  String get faceNotRegisteredDesc;

  /// No description provided for @updateFaceData.
  ///
  /// In en, this message translates to:
  /// **'Update Face Data'**
  String get updateFaceData;

  /// No description provided for @enrollFaceIdentity.
  ///
  /// In en, this message translates to:
  /// **'Enroll Face Identity'**
  String get enrollFaceIdentity;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @vietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get vietnamese;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @studentHomepage.
  ///
  /// In en, this message translates to:
  /// **'Student Homepage'**
  String get studentHomepage;

  /// No description provided for @fptExamManagement.
  ///
  /// In en, this message translates to:
  /// **'FPT Exam Management'**
  String get fptExamManagement;

  /// No description provided for @secureExamSystem.
  ///
  /// In en, this message translates to:
  /// **'Secure Examination Management System'**
  String get secureExamSystem;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 FPT University. All rights reserved.'**
  String get copyright;

  /// No description provided for @loggingIn.
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loggingIn;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your Google account to continue'**
  String get signInGoogle;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Login with Google'**
  String get loginWithGoogle;

  /// No description provided for @useFptEmail.
  ///
  /// In en, this message translates to:
  /// **'Please use your FPT University email (@fpt.edu.vn)'**
  String get useFptEmail;

  /// No description provided for @examSchedule.
  ///
  /// In en, this message translates to:
  /// **'Exam Schedule'**
  String get examSchedule;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @allExams.
  ///
  /// In en, this message translates to:
  /// **'All Exams'**
  String get allExams;

  /// No description provided for @noExamsFound.
  ///
  /// In en, this message translates to:
  /// **'No exams found'**
  String get noExamsFound;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {currentPage} of {totalPages}'**
  String pageOf(int currentPage, int totalPages);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @verifyIdentity.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity (2 steps)'**
  String get verifyIdentity;

  /// No description provided for @readyToVerify.
  ///
  /// In en, this message translates to:
  /// **'Ready to verify your identity?'**
  String get readyToVerify;

  /// No description provided for @step1Title.
  ///
  /// In en, this message translates to:
  /// **'Scan your face'**
  String get step1Title;

  /// No description provided for @step1Desc.
  ///
  /// In en, this message translates to:
  /// **'Make sure your face is clearly visible.\n(No glasses, hat, or mask)'**
  String get step1Desc;

  /// No description provided for @step2Title.
  ///
  /// In en, this message translates to:
  /// **'Capture both sides of your ID'**
  String get step2Title;

  /// No description provided for @step2Desc.
  ///
  /// In en, this message translates to:
  /// **'Take photos of the front and back of your ID card.'**
  String get step2Desc;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @allDates.
  ///
  /// In en, this message translates to:
  /// **'All Dates'**
  String get allDates;

  /// No description provided for @proctorLabel.
  ///
  /// In en, this message translates to:
  /// **'Proctor: {name}'**
  String proctorLabel(String name);

  /// No description provided for @roomLabel.
  ///
  /// In en, this message translates to:
  /// **'Room: {name}'**
  String roomLabel(String name);

  /// No description provided for @myExams.
  ///
  /// In en, this message translates to:
  /// **'My Exams'**
  String get myExams;

  /// No description provided for @studentAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Students cannot view exam session details. Only proctors have access.'**
  String get studentAccessDenied;

  /// No description provided for @tba.
  ///
  /// In en, this message translates to:
  /// **'TBA'**
  String get tba;

  /// No description provided for @filterExams.
  ///
  /// In en, this message translates to:
  /// **'Filter Exams'**
  String get filterExams;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @selectSubject.
  ///
  /// In en, this message translates to:
  /// **'Select Subject'**
  String get selectSubject;

  /// No description provided for @loadingSubjects.
  ///
  /// In en, this message translates to:
  /// **'Loading subjects...'**
  String get loadingSubjects;

  /// No description provided for @noSubjectsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No subjects available'**
  String get noSubjectsAvailable;

  /// No description provided for @examRoom.
  ///
  /// In en, this message translates to:
  /// **'Exam Room'**
  String get examRoom;

  /// No description provided for @loadingRooms.
  ///
  /// In en, this message translates to:
  /// **'Loading rooms...'**
  String get loadingRooms;

  /// No description provided for @noRoomsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No rooms available'**
  String get noRoomsAvailable;

  /// No description provided for @assigneeProctor.
  ///
  /// In en, this message translates to:
  /// **'Assignee (Proctor)'**
  String get assigneeProctor;

  /// No description provided for @assignee.
  ///
  /// In en, this message translates to:
  /// **'Assignee'**
  String get assignee;

  /// No description provided for @loadingProctors.
  ///
  /// In en, this message translates to:
  /// **'Loading proctors...'**
  String get loadingProctors;

  /// No description provided for @noProctorsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No proctors available'**
  String get noProctorsAvailable;

  /// No description provided for @examDate.
  ///
  /// In en, this message translates to:
  /// **'Exam Date'**
  String get examDate;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @applyResults.
  ///
  /// In en, this message translates to:
  /// **'Apply Results'**
  String get applyResults;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search {title}...'**
  String searchPlaceholder(String title);

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear Selection'**
  String get clearSelection;

  /// No description provided for @proctorExamDetail.
  ///
  /// In en, this message translates to:
  /// **'Proctor - Exam Session Detail'**
  String get proctorExamDetail;

  /// No description provided for @examDetail.
  ///
  /// In en, this message translates to:
  /// **'Exam Session Detail'**
  String get examDetail;

  /// No description provided for @sessionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Exam session not found'**
  String get sessionNotFound;

  /// No description provided for @sessionDetails.
  ///
  /// In en, this message translates to:
  /// **'Session Details'**
  String get sessionDetails;

  /// No description provided for @semester.
  ///
  /// In en, this message translates to:
  /// **'Semester'**
  String get semester;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @seatingPlanNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Seating plan not available'**
  String get seatingPlanNotAvailable;

  /// No description provided for @teacherDesk.
  ///
  /// In en, this message translates to:
  /// **'TEACHER DESK / ENTRANCE'**
  String get teacherDesk;

  /// No description provided for @seatLabel.
  ///
  /// In en, this message translates to:
  /// **'Seat {number}'**
  String seatLabel(String number);

  /// No description provided for @studentId.
  ///
  /// In en, this message translates to:
  /// **'Student ID'**
  String get studentId;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @checkinTime.
  ///
  /// In en, this message translates to:
  /// **'Check-in Time'**
  String get checkinTime;

  /// No description provided for @faCheckin.
  ///
  /// In en, this message translates to:
  /// **'FA Checkin'**
  String get faCheckin;

  /// No description provided for @createTicket.
  ///
  /// In en, this message translates to:
  /// **'Create Ticket'**
  String get createTicket;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @occupied.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get occupied;

  /// No description provided for @durationMins.
  ///
  /// In en, this message translates to:
  /// **'Duration: {minutes} mins'**
  String durationMins(int minutes);

  /// No description provided for @campusExamination.
  ///
  /// In en, this message translates to:
  /// **'Campus examination'**
  String get campusExamination;

  /// No description provided for @examInProgress.
  ///
  /// In en, this message translates to:
  /// **'Exam is currently in progress'**
  String get examInProgress;

  /// No description provided for @checkinNote.
  ///
  /// In en, this message translates to:
  /// **'Check-in 15 minutes before exam starts'**
  String get checkinNote;

  /// No description provided for @ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoing;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @lookStraight.
  ///
  /// In en, this message translates to:
  /// **'Look straight into the camera'**
  String get lookStraight;

  /// No description provided for @putFaceInFrame.
  ///
  /// In en, this message translates to:
  /// **'Please put your face in the frame'**
  String get putFaceInFrame;

  /// No description provided for @blinkToAuthenticate.
  ///
  /// In en, this message translates to:
  /// **'👁️ Please blink to authenticate'**
  String get blinkToAuthenticate;

  /// No description provided for @holdStill.
  ///
  /// In en, this message translates to:
  /// **'✓ Hold still... {count}/{total}'**
  String holdStill(int count, int total);

  /// No description provided for @authenticatingFace.
  ///
  /// In en, this message translates to:
  /// **'Authenticating face...'**
  String get authenticatingFace;

  /// No description provided for @authSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Authentication successful!'**
  String get authSuccessful;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authFailed;

  /// No description provided for @authFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed!'**
  String get authFailedTitle;

  /// No description provided for @timeoutTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Timeout (30 seconds). Please try again.'**
  String get timeoutTryAgain;

  /// No description provided for @confidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Confidence: {confidence}%'**
  String confidenceLabel(String confidence);

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @backToMenu.
  ///
  /// In en, this message translates to:
  /// **'Back to menu'**
  String get backToMenu;

  /// No description provided for @blinkToContinue.
  ///
  /// In en, this message translates to:
  /// **'BLINK TO CONTINUE'**
  String get blinkToContinue;

  /// No description provided for @notInExamRoom.
  ///
  /// In en, this message translates to:
  /// **'Student does not belong to this exam room!'**
  String get notInExamRoom;

  /// No description provided for @faceNotRecognized.
  ///
  /// In en, this message translates to:
  /// **'Face not recognized. Please try again.'**
  String get faceNotRecognized;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @notAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not Assigned'**
  String get notAssigned;

  /// No description provided for @proctorOfficer.
  ///
  /// In en, this message translates to:
  /// **'Exam Officer'**
  String get proctorOfficer;

  /// No description provided for @generalSchedule.
  ///
  /// In en, this message translates to:
  /// **'Exam Schedule'**
  String get generalSchedule;

  /// No description provided for @proctorProfile.
  ///
  /// In en, this message translates to:
  /// **'Proctor Profile'**
  String get proctorProfile;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @campus.
  ///
  /// In en, this message translates to:
  /// **'Campus'**
  String get campus;

  /// No description provided for @deviceRegistration.
  ///
  /// In en, this message translates to:
  /// **'Device Registration'**
  String get deviceRegistration;

  /// No description provided for @deviceRegistrationDesc.
  ///
  /// In en, this message translates to:
  /// **'Register your device to enable secure proctoring and monitoring.'**
  String get deviceRegistrationDesc;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @examinationDepartment.
  ///
  /// In en, this message translates to:
  /// **'Examination Department'**
  String get examinationDepartment;

  /// No description provided for @hoChiMinhCampus.
  ///
  /// In en, this message translates to:
  /// **'FPT University - Ho Chi Minh Campus'**
  String get hoChiMinhCampus;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @deviceActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Device is registered and active.'**
  String get deviceActiveDesc;

  /// No description provided for @devicePendingDesc.
  ///
  /// In en, this message translates to:
  /// **'Device is registered and pending approval.'**
  String get devicePendingDesc;

  /// No description provided for @myDeviceList.
  ///
  /// In en, this message translates to:
  /// **'My Device List'**
  String get myDeviceList;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @registerDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Register Device'**
  String get registerDeviceTitle;

  /// No description provided for @registerDeviceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to register this device?'**
  String get registerDeviceConfirm;

  /// No description provided for @deviceRegisteredSuccess.
  ///
  /// In en, this message translates to:
  /// **'Device registration submitted.'**
  String get deviceRegisteredSuccess;

  /// No description provided for @registerDeviceFailed.
  ///
  /// In en, this message translates to:
  /// **'Register device failed: {error}'**
  String registerDeviceFailed(String error);

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get changePasswordDesc;

  /// No description provided for @twoFactorAuth.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuth;

  /// No description provided for @twoFactorAuthDesc.
  ///
  /// In en, this message translates to:
  /// **'Add an extra layer of security'**
  String get twoFactorAuthDesc;

  /// No description provided for @deviceManagement.
  ///
  /// In en, this message translates to:
  /// **'Device Management'**
  String get deviceManagement;

  /// No description provided for @deviceManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage trusted devices'**
  String get deviceManagementDesc;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @helpCenterDesc.
  ///
  /// In en, this message translates to:
  /// **'Get help with using the app'**
  String get helpCenterDesc;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyDesc.
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get privacyPolicyDesc;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @contactUsDesc.
  ///
  /// In en, this message translates to:
  /// **'Contact our support team'**
  String get contactUsDesc;

  /// No description provided for @technicalSupport.
  ///
  /// In en, this message translates to:
  /// **'Technical Support'**
  String get technicalSupport;

  /// No description provided for @technicalSupportDesc.
  ///
  /// In en, this message translates to:
  /// **'Get help with system issues'**
  String get technicalSupportDesc;

  /// No description provided for @proctorGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Proctor Guidelines'**
  String get proctorGuidelines;

  /// No description provided for @proctorGuidelinesDesc.
  ///
  /// In en, this message translates to:
  /// **'Review examination procedures'**
  String get proctorGuidelinesDesc;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssue;

  /// No description provided for @reportIssueDesc.
  ///
  /// In en, this message translates to:
  /// **'Report technical or procedural issues'**
  String get reportIssueDesc;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'{roleDisplayName} Profile'**
  String profileTitle(String roleDisplayName);

  /// No description provided for @ticketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get ticketsTitle;

  /// No description provided for @allTickets.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allTickets;

  /// No description provided for @openTickets.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openTickets;

  /// No description provided for @inProgressTickets.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgressTickets;

  /// No description provided for @solvedTickets.
  ///
  /// In en, this message translates to:
  /// **'Solved'**
  String get solvedTickets;

  /// No description provided for @noTickets.
  ///
  /// In en, this message translates to:
  /// **'No tickets found.'**
  String get noTickets;

  /// No description provided for @failedLoadTickets.
  ///
  /// In en, this message translates to:
  /// **'Failed to load tickets: {error}'**
  String failedLoadTickets(String error);

  /// No description provided for @onlyAssignedProctorAction.
  ///
  /// In en, this message translates to:
  /// **'Only the assigned Proctor can perform actions in this exam session.'**
  String get onlyAssignedProctorAction;

  /// No description provided for @deviceNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'Device is not registered. Please register before FA Checkin.'**
  String get deviceNotRegistered;

  /// No description provided for @devicePending.
  ///
  /// In en, this message translates to:
  /// **'Device is pending approval. Please wait for confirmation.'**
  String get devicePending;

  /// No description provided for @ticketDetail.
  ///
  /// In en, this message translates to:
  /// **'Ticket Detail'**
  String get ticketDetail;

  /// No description provided for @issue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get issue;

  /// No description provided for @issueType.
  ///
  /// In en, this message translates to:
  /// **'Issue Type'**
  String get issueType;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @resolveNote.
  ///
  /// In en, this message translates to:
  /// **'Resolve Note'**
  String get resolveNote;

  /// No description provided for @techNote.
  ///
  /// In en, this message translates to:
  /// **'Tech Note'**
  String get techNote;

  /// No description provided for @studentCode.
  ///
  /// In en, this message translates to:
  /// **'Student Code'**
  String get studentCode;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated At'**
  String get updatedAt;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @tapToViewDetail.
  ///
  /// In en, this message translates to:
  /// **'Tap to view detail →'**
  String get tapToViewDetail;

  /// No description provided for @createOneTicket.
  ///
  /// In en, this message translates to:
  /// **'Create 1 ticket'**
  String get createOneTicket;

  /// No description provided for @issueName.
  ///
  /// In en, this message translates to:
  /// **'Issue Name'**
  String get issueName;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @attachmentOptional.
  ///
  /// In en, this message translates to:
  /// **'Attachment (optional)'**
  String get attachmentOptional;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications.'**
  String get noNotifications;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
