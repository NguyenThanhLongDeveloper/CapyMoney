/// Mô hình dữ liệu Nhật ký Giao dịch Thu Chi (Transaction Model)
/// 
/// Lưu trữ lịch sử biến động số dư trong bảng `giao_dich`.
class GiaoDichModel {
  /// Mã định danh giao dịch (UUID)
  final String id;

  /// Mã người dùng thực hiện
  final String nguoiDungId;

  /// Mã tài khoản ngân hàng / ví liên kết
  final String? taiKhoanId;

  /// Mã danh mục thu chi
  final String? danhMucId;

  /// Phân loại giao dịch: `chi_tieu` hoặc `thu_nhap`
  final String loaiGiaoDich;

  /// Số tiền giao dịch (luôn là số dương)
  final double soTien;

  /// Ghi chú / nội dung diễn giải
  final String? ghiChu;

  /// Đường dẫn URL ảnh hóa đơn chụp kèm
  final String? anhHoaDon;

  /// Ngày giờ thực hiện phát sinh giao dịch
  final DateTime ngayGiaoDich;

  /// Trạng thái giao dịch: `da_tru`, `da_nhan`, `cho_duyet`
  final String trangThai;

  /// Thời điểm ghi nhận vào hệ thống
  final DateTime? taoLuc;

  GiaoDichModel({
    required this.id,
    required this.nguoiDungId,
    this.taiKhoanId,
    this.danhMucId,
    required this.loaiGiaoDich,
    required this.soTien,
    this.ghiChu,
    this.anhHoaDon,
    required this.ngayGiaoDich,
    this.trangThai = 'da_tru',
    this.taoLuc,
  });

  /// Khởi tạo đối tượng GiaoDichModel từ bản ghi JSON của Supabase
  factory GiaoDichModel.fromJson(Map<String, dynamic> json) {
    return GiaoDichModel(
      id: json['id'] as String,
      nguoiDungId: json['nguoi_dung_id'] as String,
      taiKhoanId: json['tai_khoan_id'] as String?,
      danhMucId: json['danh_muc_id'] as String?,
      loaiGiaoDich: json['loai_giao_dich'] as String,
      soTien: (json['so_tien'] as num).toDouble(),
      ghiChu: json['ghi_chu'] as String?,
      anhHoaDon: json['anh_hoa_don'] as String?,
      ngayGiaoDich: json['ngay_giao_dich'] != null
          ? DateTime.parse(json['ngay_giao_dich'])
          : DateTime.now(),
      trangThai: json['trang_thai'] as String? ?? 'da_tru',
      taoLuc: json['tao_luc'] != null ? DateTime.tryParse(json['tao_luc']) : null,
    );
  }

  /// Chuyển đổi đối tượng sang định dạng JSON để ghi vào Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nguoi_dung_id': nguoiDungId,
      'tai_khoan_id': taiKhoanId,
      'danh_muc_id': danhMucId,
      'loai_giao_dich': loaiGiaoDich,
      'so_tien': soTien,
      'ghi_chu': ghiChu,
      'anh_hoa_don': anhHoaDon,
      'ngay_giao_dich': ngayGiaoDich.toIso8601String(),
      'trang_thai': trangThai,
    };
  }
}
