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
      'Dữ liệu khuôn mặt của bạn đã được đăng ký. Bạn có thể điểm danh vào thi bằng nhận diện khuôn mặt.';

  @override
  String get faceNotRegisteredDesc =>
      'Vui lòng đăng ký dữ liệu khuôn mặt để cho phép điểm danh vào thi nhanh chóng.';

  @override
  String get updateFaceData => 'Cập nhật dữ liệu khuôn mặt';

  @override
  String get enrollFaceIdentity => 'Đăng ký nhận diện khuôn mặt';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get logoutConfirm => 'Bạn có chắc chắn muốn đăng xuất?';

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

  @override
  String get studentHomepage => 'Trang chủ sinh viên';

  @override
  String get fptExamManagement => 'Quản lý thi FPT';

  @override
  String get secureExamSystem => 'Hệ thống Quản lý thi Bảo mật';

  @override
  String get copyright => '© 2026 Đại học FPT. Bảo lưu mọi quyền.';

  @override
  String get loggingIn => 'Đang đăng nhập...';

  @override
  String get welcomeBack => 'Chào mừng trở lại';

  @override
  String get signInGoogle => 'Đăng nhập bằng tài khoản Google để tiếp tục';

  @override
  String get loginWithGoogle => 'Đăng nhập với Google';

  @override
  String get useFptEmail => 'Vui lòng sử dụng email Đại học FPT (@fpt.edu.vn)';

  @override
  String get examSchedule => 'Lịch thi';

  @override
  String get upcoming => 'Sắp tới';

  @override
  String get allExams => 'Tất cả kỳ thi';

  @override
  String get noExamsFound => 'Không tìm thấy kỳ thi nào';

  @override
  String pageOf(int currentPage, int totalPages) {
    return 'Trang $currentPage trên $totalPages';
  }

  @override
  String get today => 'Hôm nay';

  @override
  String get verifyIdentity => 'Xác minh danh tính (2 bước)';

  @override
  String get readyToVerify => 'Sẵn sàng xác minh danh tính?';

  @override
  String get step1Title => 'Quét khuôn mặt';

  @override
  String get step1Desc =>
      'Đảm bảo khuôn mặt của bạn hiển thị rõ ràng.\n(Không đeo kính, mũ, hoặc khẩu trang)';

  @override
  String get step2Title => 'Chụp hai mặt của ID';

  @override
  String get step2Desc => 'Chụp hình mặt trước và mặt sau thẻ ID của bạn.';

  @override
  String get continueText => 'Tiếp tục';

  @override
  String get home => 'Trang chủ';

  @override
  String get schedule => 'Lịch thi';

  @override
  String get notification => 'Thông báo';

  @override
  String get allDates => 'Tất cả các ngày';

  @override
  String proctorLabel(String name) {
    return 'Giám thị: $name';
  }

  @override
  String roomLabel(String name) {
    return 'Phòng: $name';
  }

  @override
  String get myExams => 'Lịch thi của tôi';

  @override
  String get studentAccessDenied =>
      'Học sinh không được xem chi tiết ca thi. Chỉ giám thị mới có quyền truy cập.';

  @override
  String get tba => 'Chưa có';

  @override
  String get filterExams => 'Lọc kỳ thi';

  @override
  String get subject => 'Môn học';

  @override
  String get selectSubject => 'Chọn môn học';

  @override
  String get loadingSubjects => 'Đang tải môn học...';

  @override
  String get noSubjectsAvailable => 'Không có môn học khả dụng';

  @override
  String get examRoom => 'Phòng thi';

  @override
  String get loadingRooms => 'Đang tải phòng thi...';

  @override
  String get noRoomsAvailable => 'Không có phòng thi khả dụng';

  @override
  String get assigneeProctor => 'Người phân công (Giám thị)';

  @override
  String get assignee => 'Người phân công';

  @override
  String get loadingProctors => 'Đang tải giám thị...';

  @override
  String get noProctorsAvailable => 'Không có giám thị khả dụng';

  @override
  String get examDate => 'Ngày thi';

  @override
  String get selectDate => 'Chọn ngày';

  @override
  String get clearAll => 'Xóa tất cả';

  @override
  String get applyResults => 'Áp dụng kết quả';

  @override
  String searchPlaceholder(String title) {
    return 'Tìm kiếm $title...';
  }

  @override
  String get noDataAvailable => 'Không có dữ liệu';

  @override
  String get clearSelection => 'Xóa lựa chọn';

  @override
  String get proctorExamDetail => 'Giám thị - Chi tiết ca thi';

  @override
  String get examDetail => 'Chi tiết ca thi';

  @override
  String get sessionNotFound => 'Không tìm thấy ca thi';

  @override
  String get sessionDetails => 'Chi tiết phiên';

  @override
  String get semester => 'Học kỳ';

  @override
  String get total => 'Tổng cộng';

  @override
  String get present => 'Có mặt';

  @override
  String get absent => 'Vắng mặt';

  @override
  String get seatingPlanNotAvailable => 'Sơ đồ chỗ ngồi không khả dụng';

  @override
  String get teacherDesk => 'BÀN GIÁO VIÊN / LỐI VÀO';

  @override
  String seatLabel(String number) {
    return 'Chỗ $number';
  }

  @override
  String get studentId => 'Mã số sinh viên';

  @override
  String get status => 'Trạng thái';

  @override
  String get checkinTime => 'Thời gian check-in';

  @override
  String get faCheckin => 'FA Checkin';

  @override
  String get createTicket => 'Tạo Ticket';

  @override
  String get available => 'Trống';

  @override
  String get occupied => 'Đã ngồi';

  @override
  String durationMins(int minutes) {
    return 'Thời lượng: $minutes phút';
  }

  @override
  String get campusExamination => 'Kỳ thi tại cơ sở';

  @override
  String get examInProgress => 'Kỳ thi đang diễn ra';

  @override
  String get checkinNote => 'Check-in 15 phút trước khi bắt đầu';

  @override
  String get ongoing => 'Đang diễn ra';

  @override
  String get completed => 'Đã hoàn thành';

  @override
  String get unknown => 'Không xác định';

  @override
  String get lookStraight => 'Nhìn thẳng vào camera';

  @override
  String get putFaceInFrame => 'Vui lòng để khuôn mặt vào khung hình';

  @override
  String get blinkToAuthenticate => '👁️ Vui lòng nháy mắt để xác thực';

  @override
  String holdStill(int count, int total) {
    return '✓ Giữ yên... $count/$total';
  }

  @override
  String get authenticatingFace => 'Đang xác thực khuôn mặt...';

  @override
  String get authSuccessful => 'Xác thực thành công!';

  @override
  String get authFailed => 'Xác thực thất bại';

  @override
  String get authFailedTitle => 'Xác thực thất bại!';

  @override
  String get timeoutTryAgain => 'Hết thời gian (30 giây). Vui lòng thử lại.';

  @override
  String confidenceLabel(String confidence) {
    return 'Độ tin cậy: $confidence%';
  }

  @override
  String get complete => 'Hoàn thành';

  @override
  String get retry => 'Thử lại';

  @override
  String get backToMenu => 'Quay lại menu';

  @override
  String get blinkToContinue => 'NHÁY MẮT ĐỂ TIẾP TỤC';

  @override
  String get notInExamRoom => 'Sinh viên không thuộc phòng thi này!';

  @override
  String get faceNotRecognized =>
      'Khuôn mặt không được nhận diện. Vui lòng thử lại.';

  @override
  String get thisWeek => 'Tuần này';

  @override
  String get all => 'Tất cả';

  @override
  String get past => 'Quá khứ';

  @override
  String get notAssigned => 'Chưa được phân công';

  @override
  String get proctorOfficer => 'Cán bộ coi thi';

  @override
  String get generalSchedule => 'Lịch thi chung';

  @override
  String get proctorProfile => 'Hồ sơ Giám thị';

  @override
  String get department => 'Phòng ban';

  @override
  String get campus => 'Cơ sở';

  @override
  String get deviceRegistration => 'Đăng ký thiết bị';

  @override
  String get deviceRegistrationDesc =>
      'Đăng ký thiết bị để kích hoạt giám sát thi an toàn.';

  @override
  String get security => 'Bảo mật';

  @override
  String get helpSupport => 'Trợ giúp & Hỗ trợ';

  @override
  String get examinationDepartment => 'Phòng Khảo thí';

  @override
  String get hoChiMinhCampus => 'ĐH FPT - Cơ sở TP. Hồ Chí Minh';

  @override
  String get active => 'Đang hoạt động';

  @override
  String get pending => 'Chờ duyệt';

  @override
  String get deviceActiveDesc => 'Thiết bị đã được đăng ký và đang hoạt động.';

  @override
  String get devicePendingDesc => 'Thiết bị đã được đăng ký và đang chờ duyệt.';

  @override
  String get myDeviceList => 'Danh sách thiết bị của tôi';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get registerDeviceTitle => 'Đăng ký thiết bị';

  @override
  String get registerDeviceConfirm => 'Bạn muốn đăng ký thiết bị này?';

  @override
  String get deviceRegisteredSuccess => 'Đã gửi đơn đăng ký thiết bị.';

  @override
  String registerDeviceFailed(String error) {
    return 'Đăng ký thiết bị thất bại: $error';
  }

  @override
  String get changePassword => 'Đổi mật khẩu';

  @override
  String get changePasswordDesc => 'Cập nhật mật khẩu tài khoản';

  @override
  String get twoFactorAuth => 'Xác thực hai yếu tố';

  @override
  String get twoFactorAuthDesc => 'Thêm lớp bảo mật bổ sung';

  @override
  String get deviceManagement => 'Quản lý thiết bị';

  @override
  String get deviceManagementDesc => 'Quản lý các thiết bị tin cậy';

  @override
  String get helpCenter => 'Trung tâm hỗ trợ';

  @override
  String get helpCenterDesc => 'Trợ giúp sử dụng ứng dụng';

  @override
  String get privacyPolicy => 'Chính sách bảo mật';

  @override
  String get privacyPolicyDesc => 'Đọc chính sách bảo mật của chúng tôi';

  @override
  String get contactUs => 'Liên hệ chúng tôi';

  @override
  String get contactUsDesc => 'Liên hệ đội ngũ hỗ trợ';

  @override
  String get technicalSupport => 'Hỗ trợ kỹ thuật';

  @override
  String get technicalSupportDesc => 'Nhận hỗ trợ về các vấn đề hệ thống';

  @override
  String get proctorGuidelines => 'Hướng dẫn Giám thị';

  @override
  String get proctorGuidelinesDesc => 'Xem xét quy trình thi';

  @override
  String get reportIssue => 'Báo cáo sự cố';

  @override
  String get reportIssueDesc => 'Báo cáo vấn đề kỹ thuật hoặc quy trình';

  @override
  String profileTitle(String roleDisplayName) {
    return 'Hồ sơ $roleDisplayName';
  }

  @override
  String get ticketsTitle => 'Tickets';

  @override
  String get allTickets => 'Tất cả';

  @override
  String get openTickets => 'Đang mở';

  @override
  String get inProgressTickets => 'Đang xử lý';

  @override
  String get solvedTickets => 'Đã giải quyết';

  @override
  String get noTickets => 'Không có ticket nào.';

  @override
  String failedLoadTickets(String error) {
    return 'Không thể tải danh sách ticket: $error';
  }

  @override
  String get onlyAssignedProctorAction =>
      'Chỉ Giám thị được phân công mới có quyền thực hiện các tác vụ trong ca thi này.';

  @override
  String get deviceNotRegistered =>
      'Thiết bị chưa được đăng ký. Vui lòng đăng ký trước khi FA Checkin.';

  @override
  String get devicePending => 'Thiết bị đang chờ duyệt. Vui lòng đợi xác nhận.';

  @override
  String get ticketDetail => 'Chi tiết Ticket';

  @override
  String get issue => 'Vấn đề';

  @override
  String get issueType => 'Loại vấn đề';

  @override
  String get priority => 'Mức độ ưu tiên';

  @override
  String get description => 'Mô tả';

  @override
  String get resolveNote => 'Ghi chú giải quyết';

  @override
  String get techNote => 'Ghi chú kỹ thuật';

  @override
  String get studentCode => 'Mã sinh viên';

  @override
  String get createdAt => 'Ngày tạo';

  @override
  String get updatedAt => 'Ngày cập nhật';

  @override
  String get notificationsTitle => 'Thông báo';

  @override
  String get tapToViewDetail => 'Nhấn để xem chi tiết →';

  @override
  String get createOneTicket => 'Tạo 1 ticket';

  @override
  String get issueName => 'Tên vấn đề(Issue Name)';

  @override
  String get student => 'Sinh viên';

  @override
  String get attachmentOptional => 'Ảnh đính kèm (tùy chọn)';

  @override
  String get takePhoto => 'Chụp ảnh';

  @override
  String get gallery => 'Thư viện';

  @override
  String get create => 'Tạo';

  @override
  String get noNotifications => 'Chưa có thông báo nào.';
}
