/// Mô hình dữ liệu Tài khoản Người dùng (User Profile Model)
/// 
/// Đại diện cho thông tin định danh cá nhân và cấu hình tùy chỉnh của người dùng trong bảng `nguoi_dung`.
class NguoiDungModel {
  /// Mã định danh duy nhất (UUID từ Supabase Auth)
  final String id;

  /// Họ và tên đầy đủ
  final String hoTen;

  /// Địa chỉ Gmail liên kết
  final String email;

  /// Số điện thoại (10 chữ số)
  final String? soDienThoai;

  /// Đường dẫn URL ảnh đại diện trên Supabase Storage
  final String? anhDaiDien;

  /// Cấu hình bật/tắt nhận báo cáo tài chính tuần qua Gmail
  final bool baoCaoGmail;

  /// Cấu hình bật/tắt nhắc nhở ghi chép giao dịch hàng ngày
  final bool nhacNhoGhiChep;

  /// Thời gian phát thông báo nhắc nhở (Mặc định '21:30')
  final String thoiGianNhacNho;

  /// Thời điểm khởi tạo tài khoản
  final DateTime? taoLuc;

  NguoiDungModel({
    required this.id,
    required this.hoTen,
    required this.email,
    this.soDienThoai,
    this.anhDaiDien,
    this.baoCaoGmail = true,
    this.nhacNhoGhiChep = true,
    this.thoiGianNhacNho = '21:30',
    this.taoLuc,
  });

  /// Khởi tạo đối tượng NguoiDungModel từ bản ghi JSON của Supabase
  factory NguoiDungModel.fromJson(Map<String, dynamic> json) {
    return NguoiDungModel(
      id: json['id'] as String,
      hoTen: json['ho_ten'] as String? ?? 'Người dùng Capy',
      email: json['email'] as String? ?? '',
      soDienThoai: json['so_dien_thoai'] as String?,
      anhDaiDien: json['anh_dai_dien'] as String?,
      baoCaoGmail: json['bao_cao_gmail'] as bool? ?? true,
      nhacNhoGhiChep: json['nhac_nho_ghi_chep'] as bool? ?? true,
      thoiGianNhacNho: json['thoi_gian_nhac_nho'] as String? ?? '21:30',
      taoLuc: json['tao_luc'] != null ? DateTime.tryParse(json['tao_luc']) : null,
    );
  }

  /// Chuyển đổi đối tượng sang định dạng JSON để ghi vào Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ho_ten': hoTen,
      'email': email,
      'so_dien_thoai': soDienThoai,
      'anh_dai_dien': anhDaiDien,
      'bao_cao_gmail': baoCaoGmail,
      'nhac_nho_ghi_chep': nhacNhoGhiChep,
      'thoi_gian_nhac_nho': thoiGianNhacNho,
    };
  }
}
