import 'dart:convert';

class TicketIssuePreset {
  final String code;
  final String issueType;
  final String _viLabel;
  final String enLabel;

  String get viLabel => _decodeLegacyVietnamese(_viLabel);

  const TicketIssuePreset({
    required this.code,
    required this.issueType,
    required String viLabel,
    required this.enLabel,
  }) : _viLabel = viLabel;
}

class TicketResolutionPreset {
  final String code;
  final List<String> issueCodes;
  final String _viLabel;
  final String enLabel;
  final String _viText;
  final String enText;

  String get viLabel => _decodeLegacyVietnamese(_viLabel);
  String get viText => _decodeLegacyVietnamese(_viText);

  const TicketResolutionPreset({
    required this.code,
    required this.issueCodes,
    required String viLabel,
    required this.enLabel,
    required String viText,
    required this.enText,
  })  : _viLabel = viLabel,
        _viText = viText;
}

String _decodeLegacyVietnamese(String value) {
  try {
    return utf8.decode(latin1.encode(value));
  } catch (_) {
    return value;
  }
}

const List<TicketIssuePreset> kTicketIssuePresets = [
  TicketIssuePreset(
    code: 'OTHER',
    issueType: 'Technical Issue',
    viLabel: 'Khác / Tùy chỉnh',
    enLabel: 'Other / Custom',
  ),
  TicketIssuePreset(
    code: 'cannotLogin',
    issueType: 'Technical Issue',
    viLabel: 'Không đăng nhập được',
    enLabel: 'Cannot log in',
  ),
  TicketIssuePreset(
    code: 'eosClientError',
    issueType: 'Technical Issue',
    viLabel: 'EOSClient / Phần mềm thi bị lỗi',
    enLabel: 'Exam client error',
  ),
  TicketIssuePreset(
    code: 'spinningScreen',
    issueType: 'Technical Issue',
    viLabel: 'Màn hình xoay liên tục',
    enLabel: 'Screen keeps spinning',
  ),
  TicketIssuePreset(
    code: 'needReassign',
    issueType: 'Technical Issue',
    viLabel: 'Cần reassign do đã đăng nhập rồi',
    enLabel: 'Need reassign',
  ),
  TicketIssuePreset(
    code: 'lostServerConn',
    issueType: 'Technical Issue',
    viLabel: 'Mất kết nối server thi',
    enLabel: 'Lost server connection',
  ),
  TicketIssuePreset(
    code: 'wrongExamCode',
    issueType: 'Technical Issue',
    viLabel: 'Sai mã thi',
    enLabel: 'Wrong exam code',
  ),
  TicketIssuePreset(
    code: 'notInExamList',
    issueType: 'Room Management',
    viLabel: 'Không có trong danh sách thi',
    enLabel: 'Not in exam list',
  ),
  TicketIssuePreset(
    code: 'deviceViolation',
    issueType: 'Academic Violation',
    viLabel: 'Sử dụng thiết bị trái phép',
    enLabel: 'Device violation',
  ),
  TicketIssuePreset(
    code: 'cheatingBehavior',
    issueType: 'Academic Violation',
    viLabel: 'Hành vi gian lận',
    enLabel: 'Cheating behavior',
  ),
  TicketIssuePreset(
    code: 'focusLostRepeat',
    issueType: 'Academic Violation',
    viLabel: 'Out màn hình nhiều lần',
    enLabel: 'Repeated focus lost',
  ),
  TicketIssuePreset(
    code: 'cccdMismatch',
    issueType: 'Face Mismatch',
    viLabel: 'Sai thông tin CCCD',
    enLabel: 'ID mismatch',
  ),
  TicketIssuePreset(
    code: 'submissionFailed',
    issueType: 'Technical Issue',
    viLabel: 'Nộp bài thất bại',
    enLabel: 'Submission failed',
  ),
  TicketIssuePreset(
    code: 'hardwareFailure',
    issueType: 'Technical Issue',
    viLabel: 'Máy tính hỏng, mất nguồn',
    enLabel: 'Hardware failure',
  ),
  TicketIssuePreset(
    code: 'wrongFileFormat',
    issueType: 'Technical Issue',
    viLabel: 'Sai định dạng file nộp bài',
    enLabel: 'Wrong file format',
  ),
  TicketIssuePreset(
    code: 'roomIssue',
    issueType: 'Room Management',
    viLabel: 'Sự cố phòng thi khác',
    enLabel: 'Room issue',
  ),
];

const List<TicketResolutionPreset> kTicketResolutionPresets = [
  TicketResolutionPreset(
    code: 'CUSTOM',
    issueCodes: [],
    viLabel: 'Khác / Tùy chỉnh',
    enLabel: 'Other / Custom',
    viText: '',
    enText: '',
  ),
  TicketResolutionPreset(
    code: 'REFRESH_AND_RELOGIN',
    issueCodes: ['cannotLogin', 'spinningScreen'],
    viLabel: 'Refresh và đăng nhập lại',
    enLabel: 'Refresh and relogin',
    viText: 'Đã hướng dẫn đăng nhập lại và làm mới ứng dụng, hệ thống hoạt động bình thường.',
    enText: 'Guided the user to sign in again and refresh the exam client. The system is now working normally.',
  ),
  TicketResolutionPreset(
    code: 'RESET_PASSWORD_GUIDE',
    issueCodes: ['cannotLogin'],
    viLabel: 'Hướng dẫn reset mật khẩu',
    enLabel: 'Guide password reset',
    viText: 'Đã hướng dẫn reset thông tin đăng nhập và xác nhận truy cập được hệ thống thi.',
    enText: 'Guided the user through credential reset and confirmed access to the exam system.',
  ),
  TicketResolutionPreset(
    code: 'REASSIGN_ACCOUNT',
    issueCodes: ['needReassign'],
    viLabel: 'Cấp lại phiên đăng nhập',
    enLabel: 'Reassign account',
    viText: 'Đã xác nhận tài khoản cần re-assign và chuyển xử lý theo đúng quy trình.',
    enText: 'Confirmed the account needed reassignment and processed it according to the standard flow.',
  ),
  TicketResolutionPreset(
    code: 'CHECK_NETWORK_AND_RECONNECT',
    issueCodes: ['lostServerConn'],
    viLabel: 'Kiểm tra mạng và kết nối lại',
    enLabel: 'Check network and reconnect',
    viText: 'Đã kiểm tra kết nối mạng, thực hiện kết nối lại và xác nhận phiên thi tiếp tục ổn định.',
    enText: 'Checked the network connection, reconnected the session, and confirmed the exam could continue normally.',
  ),
  TicketResolutionPreset(
    code: 'RESTART_CLIENT',
    issueCodes: ['eosClientError', 'spinningScreen', 'hardwareFailure'],
    viLabel: 'Khởi động lại phần mềm thi',
    enLabel: 'Restart exam client',
    viText: 'Đã khởi động lại phần mềm thi và xác nhận màn hình thi hiển thị đúng.',
    enText: 'Restarted the exam client and confirmed the exam screen displayed correctly.',
  ),
  TicketResolutionPreset(
    code: 'CORRECT_EXAM_CODE',
    issueCodes: ['wrongExamCode'],
    viLabel: 'Đính chính mã thi',
    enLabel: 'Correct exam code',
    viText: 'Đã đối chiếu và đính chính lại ExamCode, sau đó xác nhận truy cập đúng đề thi.',
    enText: 'Verified and corrected the exam code, then confirmed access to the correct exam.',
  ),
  TicketResolutionPreset(
    code: 'VERIFY_LIST_AND_ESCALATE',
    issueCodes: ['notInExamList', 'roomIssue'],
    viLabel: 'Kiểm tra danh sách và chuyển bộ phận liên quan',
    enLabel: 'Verify list and escalate',
    viText: 'Đã kiểm tra danh sách thi và chuyển xử lý cho bộ phận liên quan theo quy trình.',
    enText: 'Verified the exam list and escalated the case to the responsible team according to the process.',
  ),
  TicketResolutionPreset(
    code: 'VERIFY_AND_WARN',
    issueCodes: ['deviceViolation', 'cheatingBehavior', 'focusLostRepeat'],
    viLabel: 'Xác minh và nhắc nhở',
    enLabel: 'Verify and warn',
    viText: 'Đã xác minh tình huống, nhắc nhở thí sinh và ghi nhận xử lý theo quy định phòng thi.',
    enText: 'Verified the incident, warned the student, and recorded the handling according to exam room policy.',
  ),
  TicketResolutionPreset(
    code: 'VERIFY_IDENTITY',
    issueCodes: ['cccdMismatch'],
    viLabel: 'Xác minh danh tính',
    enLabel: 'Verify identity',
    viText: 'Đã đối chiếu thông tin danh tính và xác nhận lại dữ liệu nhận diện cho thí sinh.',
    enText: 'Verified the identity information and confirmed the student record was corrected.',
  ),
  TicketResolutionPreset(
    code: 'RESUBMIT_OR_RETRY',
    issueCodes: ['submissionFailed', 'wrongFileFormat'],
    viLabel: 'Hướng dẫn nộp lại',
    enLabel: 'Guide resubmission',
    viText: 'Đã hướng dẫn kiểm tra định dạng và thao tác nộp bài lại, xác nhận kết quả sau xử lý.',
    enText: 'Guided the user to check the format and resubmit, then confirmed the outcome after retry.',
  ),
  TicketResolutionPreset(
    code: 'ESCALATE_EXAM_OFFICER',
    issueCodes: [],
    viLabel: 'Chuyển khảo thí',
    enLabel: 'Escalate to exam officer',
    viText: 'Đã tiếp nhận và chuyển xử lý cho bộ phận khảo thí để tiếp tục theo dõi.',
    enText: 'Accepted the ticket and escalated it to the exam officer team for further handling.',
  ),
];

TicketIssuePreset? findTicketIssuePreset(String? code) {
  if (code == null || code.trim().isEmpty) return null;
  for (final preset in kTicketIssuePresets) {
    if (preset.code == code.trim()) return preset;
  }
  return null;
}

List<TicketResolutionPreset> resolutionPresetsForIssue(String issueCode) {
  final presets = kTicketResolutionPresets
      .where(
        (preset) =>
            preset.code == 'CUSTOM' ||
            preset.issueCodes.isEmpty ||
            preset.issueCodes.contains(issueCode),
      )
      .toList();
  presets.sort((a, b) {
    if (a.code == 'CUSTOM') return 1;
    if (b.code == 'CUSTOM') return -1;
    return 0;
  });
  return presets;
}
