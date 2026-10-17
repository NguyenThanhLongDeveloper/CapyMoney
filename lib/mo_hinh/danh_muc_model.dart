/// Mô hình dữ liệu Danh mục Thu Chi (Category Model)
/// 
/// Phân loại giao dịch (Ăn uống, Di lại, Mua sắm, Lương...) trong bảng `danh_muc`.
class DanhMucModel {
  /// Mã định danh danh mục (UUID)
  final String id;

  /// Mã người dùng tạo danh mục riêng (Null nếu là danh mục hệ thống)
  final String? nguoiDungId;

  /// Tên danh mục hiển thị
  final String tenDanhMuc;

  /// Loại danh mục: `chi_tieu` hoặc `thu_nhap`
  final String loai;

  /// Tên icon đại diện (Icon key)
  final String bieuTuong;

  /// Mã màu HEX định dạng `#RRGGBB`
  final String mauSac;

  DanhMucModel({
    required this.id,
    this.nguoiDungId,
    required this.tenDanhMuc,
    required this.loai,
    required this.bieuTuong,
    this.mauSac = '#00F59B',
  });

  /// Khởi tạo đối tượng DanhMucModel từ bản ghi JSON của Supabase
  factory DanhMucModel.fromJson(Map<String, dynamic> json) {
    return DanhMucModel(
      id: json['id'] as String,
      nguoiDungId: json['nguoi_dung_id'] as String?,
      tenDanhMuc: json['ten_danh_muc'] as String,
      loai: json['loai'] as String,
      bieuTuong: json['bieu_tuong'] as String,
      mauSac: json['mau_sac'] as String? ?? '#00F59B',
    );
  }

  /// Chuyển đổi đối tượng sang định dạng JSON để ghi vào Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nguoi_dung_id': nguoiDungId,
      'ten_danh_muc': tenDanhMuc,
      'loai': loai,
      'bieu_tuong': bieuTuong,
      'mau_sac': mauSac,
    };
  }
}
