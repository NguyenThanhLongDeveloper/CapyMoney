/// Mô hình dữ liệu Tài khoản Ngân hàng & Ví Điện tử (Bank Account & Wallet Model)
/// 
/// Đại diện cho các nguồn tiền/phương thức nhận tiền liên kết trong bảng `tai_khoan_ngan_hang`.
class TaiKhoanNganHangModel {
  /// Mã định danh nguồn tiền (UUID)
  final String id;

  /// Mã người dụng sở hữu
  final String nguoiDungId;

  /// Tên ngân hàng hoặc ví (Ví dụ: MB Bank, Vietcombank, MoMo)
  final String tenNganHang;

  /// Số tài khoản hoặc số điện thoại ví
  final String soTaiKhoan;

  /// Tên chủ tài khoản (in hoa không dấu)
  final String tenChuTaiKhoan;

  /// Phân loại nguồn tiền: `ngan_hang`, `vi_dien_tu`, `tien_mat`
  final String loaiTaiKhoan;

  /// Số dư khả dụng hiện tại
  final double soDu;

  /// Đánh dấu đây là nguồn nhận tiền mặc định chính
  final bool laNhanChinh;

  /// Thời điểm liên kết tài khoản
  final DateTime? taoLuc;

  TaiKhoanNganHangModel({
    required this.id,
    required this.nguoiDungId,
    required this.tenNganHang,
    required this.soTaiKhoan,
    required this.tenChuTaiKhoan,
    this.loaiTaiKhoan = 'ngan_hang',
    this.soDu = 0.0,
    this.laNhanChinh = false,
    this.taoLuc,
  });

  /// Khởi tạo đối tượng TaiKhoanNganHangModel từ bản ghi JSON của Supabase
  factory TaiKhoanNganHangModel.fromJson(Map<String, dynamic> json) {
    return TaiKhoanNganHangModel(
      id: json['id'] as String,
      nguoiDungId: json['nguoi_dung_id'] as String,
      tenNganHang: json['ten_ngan_hang'] as String,
      soTaiKhoan: json['so_tai_khoan'] as String,
      tenChuTaiKhoan: json['ten_chu_tai_khoan'] as String,
      loaiTaiKhoan: json['loai_tai_khoan'] as String? ?? 'ngan_hang',
      soDu: (json['so_du'] as num?)?.toDouble() ?? 0.0,
      laNhanChinh: json['la_nhan_chinh'] as bool? ?? false,
      taoLuc: json['tao_luc'] != null ? DateTime.tryParse(json['tao_luc']) : null,
    );
  }

  /// Chuyển đổi đối tượng sang định dạng JSON để lưu vào Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nguoi_dung_id': nguoiDungId,
      'ten_ngan_hang': tenNganHang,
      'so_tai_khoan': soTaiKhoan,
      'ten_chu_tai_khoan': tenChuTaiKhoan,
      'loai_tai_khoan': loaiTaiKhoan,
      'so_du': soDu,
      'la_nhan_chinh': laNhanChinh,
    };
  }
}
