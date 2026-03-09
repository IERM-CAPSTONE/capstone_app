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

  @override
  String get studentHomepage => 'Trang chủ Sinh viên';

  @override
  String get fptExamManagement => 'Quản lý Phòng thi FPT';

  @override
  String get secureExamSystem => 'Hệ thống Quản lý Thi Bảo mật';

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
  String get useFptEmail =>
      'Vui lòng sử dụng email của Đại học FPT (@fpt.edu.vn)';

  @override
  String get examSchedule => 'Lịch thi';

  @override
  String get upcoming => 'Sắp tới';

  @override
  String get allExams => 'Tất cả';

  @override
  String get noExamsFound => 'Không tìm thấy lịch thi';

  @override
  String pageOf(int currentPage, int totalPages) {
    return 'Trang $currentPage / $totalPages';
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
      'Đảm bảo khuôn mặt của bạn hiển thị rõ ràng.\n(Không đeo kính, mũ hoặc khẩu trang)';

  @override
  String get step2Title => 'Chụp ảnh CMND/CCCD 2 mặt';

  @override
  String get step2Desc => 'Chụp ảnh mặt trước và mặt sau thẻ ID của bạn.';

  @override
  String get continueText => 'Tiếp tục';

  @override
  String get home => 'Trang chủ';

  @override
  String get schedule => 'Lịch thi';

  @override
  String get notification => 'Thông báo';

  @override
  String get allDates => 'Tất cả ngày';

  @override
  String proctorLabel(String name) {
    return 'Giám thị: $name';
  }

  @override
  String roomLabel(String name) {
    return 'Phòng: $name';
  }

  @override
  String get myExams => 'Bài thi của tôi';

  @override
  String get studentAccessDenied =>
      'Sinh viên không thể xem chi tiết phòng thi. Chỉ giám thị mới có quyền truy cập.';

  @override
  String get tba => 'Chưa xác định';

  @override
  String get filterExams => 'Lọc lịch thi';

  @override
  String get subject => 'Môn học';

  @override
  String get selectSubject => 'Chọn môn học';

  @override
  String get loadingSubjects => 'Đang tải môn học...';

  @override
  String get noSubjectsAvailable => 'Không có môn học';

  @override
  String get examRoom => 'Phòng thi';

  @override
  String get loadingRooms => 'Đang tải phòng thi...';

  @override
  String get noRoomsAvailable => 'Không có phòng thi';

  @override
  String get assigneeProctor => 'Giám thị';

  @override
  String get assignee => 'Giám thị';

  @override
  String get loadingProctors => 'Đang tải giám thị...';

  @override
  String get noProctorsAvailable => 'Không có giám thị';

  @override
  String get examDate => 'Ngày thi';

  @override
  String get selectDate => 'Chọn ngày';

  @override
  String get clearAll => 'Xóa tất cả';

  @override
  String get applyResults => 'Áp dụng';

  @override
  String searchPlaceholder(String title) {
    return 'Tìm kiếm $title...';
  }

  @override
  String get noDataAvailable => 'Không có dữ liệu';

  @override
  String get clearSelection => 'Xóa chọn lựa';

  @override
  String get proctorExamDetail => 'Giám thị - Chi tiết phòng thi';

  @override
  String get examDetail => 'Chi tiết phòng thi';

  @override
  String get sessionNotFound => 'Không tìm thấy phòng thi';

  @override
  String get sessionDetails => 'Thông tin phòng thi';

  @override
  String get semester => 'Học kỳ';

  @override
  String get total => 'Tổng số';

  @override
  String get present => 'Có mặt';

  @override
  String get absent => 'Vắng mặt';

  @override
  String get seatingPlanNotAvailable => 'Sơ đồ chỗ ngồi chưa sẵn sàng';

  @override
  String get teacherDesk => 'BÀN GIÁM THỊ / CỬA RA VÀO';

  @override
  String seatLabel(String number) {
    return 'Chỗ $number';
  }

  @override
  String get studentId => 'Mã sinh viên';

  @override
  String get status => 'Trạng thái';

  @override
  String get checkinTime => 'Giờ điểm danh';

  @override
  String get faCheckin => 'Điểm danh FA';

  @override
  String get createTicket => 'Tạo Ticket';

  @override
  String get available => 'Trống';

  @override
  String get occupied => 'Đã xếp chỗ';

  @override
  String durationMins(int minutes) {
    return 'Thời lượng: $minutes phút';
  }

  @override
  String get campusExamination => 'Thi tại trường';

  @override
  String get examInProgress => 'Phòng thi đang diễn ra';

  @override
  String get checkinNote => 'Điểm danh 15 phút trước khi bắt đầu';

  @override
  String get ongoing => 'Đang diễn ra';

  @override
  String get completed => 'Hoàn thành';

  @override
  String get unknown => 'Chưa rõ';

  @override
  String get lookStraight => 'Nhìn thẳng vào camera';

  @override
  String get putFaceInFrame => 'Vui lòng đưa khuôn mặt vào khung hình';

  @override
  String get blinkToAuthenticate => '👁️ Vui lòng nháy mắt để xác thực';

  @override
  String holdStill(int count, int total) {
    return '✓ Giữ nguyên... $count/$total';
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
  String get complete => 'Hoàn tất';

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
      'Không nhận diện được khuôn mặt. Vui lòng thử lại.';
}
