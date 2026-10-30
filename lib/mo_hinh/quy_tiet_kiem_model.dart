/// Mô hình dữ liệu Quỹ Tiết Kiệm & Mục Tiêu Tài Chính (Savings Goal Model)
/// 
/// Quản lý thông tin mục tiêu tích lũy tài sản trong bảng `quy_tiet_kiem`.
class QuyTietKiemModel {
  /// Mã định danh quỹ (UUID)
  final String id;

  /// Mã người dùng sở hữu
  final String nguoiDungId;

  /// Tên quỹ / mục tiêu tích lũy (Ví dụ: Mua xe máy mới, Quỹ khẩn cấp)
  final String tenQuy;

  /// Mã khóa ngoại danh mục ngân sách & tiết kiệm liên kết (danh_muc_ngan_sach_id)
  final String? danhMucNganSachId;

  /// Số tiền mục tiêu cần đạt
  final double soTienMucTieu;

  /// Số tiền hiện có đã nạp
  final double soTienHienCo;

  /// Kỳ hạn tích lũy theo tháng
  final int kyHanThang;

  /// Ngày dự kiến hoàn thành mục tiêu
  final DateTime? ngayVeDich;

  /// Bật/Tắt nhắc nhở nạp tiền định kỳ
  final bool nhacNhoDinhKy;

  /// Thời điểm tạo quỹ
  final DateTime? taoLuc;

  QuyTietKiemModel({
    required this.id,
    required this.nguoiDungId,
    required this.tenQuy,
    this.danhMucNganSachId,
    required this.soTienMucTieu,
    this.soTienHienCo = 0.0,
    this.kyHanThang = 12,
    this.ngayVeDich,
    this.nhacNhoDinhKy = true,
    this.taoLuc,
  });

  /// Tính phần trăm tiến độ hoàn thành mục tiêu (%)
  double get phanTramHoanThanh =>
      soTienMucTieu > 0 ? (soTienHienCo / soTienMucTieu) * 100 : 0;

  /// Tính số tiền còn thiếu để về đích
  double get soTienConLai =>
      soTienMucTieu > soTienHienCo ? soTienMucTieu - soTienHienCo : 0;

  /// Tính số tiền cần đóng góp / gửi hàng tháng
  double get soTienCanNopHangThang {
    if (soTienConLai <= 0) return 0.0;
    final int months = kyHanThang > 0 ? kyHanThang : 12;
    return soTienConLai / months;
  }

  /// Khởi tạo đối tượng QuyTietKiemModel từ bản ghi JSON của Supabase
  factory QuyTietKiemModel.fromJson(Map<String, dynamic> json) {
    return QuyTietKiemModel(
      id: json['id'] as String,
      nguoiDungId: json['nguoi_dung_id'] as String,
      tenQuy: json['ten_quy'] as String,
      danhMucNganSachId: json['danh_muc_ngan_sach_id'] as String?,
      soTienMucTieu: (json['so_tien_muc_tieu'] as num).toDouble(),
      soTienHienCo: (json['so_tien_hien_co'] as num?)?.toDouble() ?? 0.0,
      kyHanThang: json['ky_han_thang'] as int? ?? 12,
      ngayVeDich: json['ngay_ve_dich'] != null ? DateTime.tryParse(json['ngay_ve_dich']) : null,
      nhacNhoDinhKy: json['nhac_nho_dinh_ky'] as bool? ?? true,
      taoLuc: json['tao_luc'] != null ? DateTime.tryParse(json['tao_luc']) : null,
    );
  }

  /// Chuyển đổi đối tượng sang định dạng JSON để ghi vào Supabase
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nguoi_dung_id': nguoiDungId,
      'ten_quy': tenQuy,
      'danh_muc_ngan_sach_id': (danhMucNganSachId != null && danhMucNganSachId!.trim().isNotEmpty) ? danhMucNganSachId : null,
      'so_tien_muc_tieu': soTienMucTieu,
      'so_tien_hien_co': soTienHienCo,
      'ky_han_thang': kyHanThang,
      'ngay_ve_dich': ngayVeDich?.toIso8601String(),
      'nhac_nho_dinh_ky': nhacNhoDinhKy,
    };

    if (id.trim().isNotEmpty) {
      data['id'] = id;
    }

    return data;
  }
}

/// Extension OOP hỗ trợ danh sách `List<QuyTietKiemModel>` tra cứu tên nhanh
extension QuyTietKiemListX on List<QuyTietKiemModel> {
  /// Tìm đối tượng quỹ theo `quyId`
  QuyTietKiemModel? timTheoId(String? quyId) {
    if (quyId == null || quyId.isEmpty) return null;
    final list = where((q) => q.id == quyId).toList();
    return list.isNotEmpty ? list.first : null;
  }
}
