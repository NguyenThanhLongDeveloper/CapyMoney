import 'package:flutter/material.dart';
import '../giao_dien/chuan_thiet_ke/bieu_tuong.dart';

/// Lựa chọn Biểu tượng gợi ý cho Quỹ tiết kiệm
class BieuTuongQuyOption {
  final String key;
  final String label;
  final IconData icon;

  const BieuTuongQuyOption({
    required this.key,
    required this.label,
    required this.icon,
  });
}

/// Mô hình dữ liệu Quỹ Tiết Kiệm & Mục Tiêu Tài Chính (Savings Goal Model)
/// 
/// Quản lý thông tin mục tiêu tích lũy tài sản trong bảng `quy_tiet_kiem`.
class QuyTietKiemModel {
  /// Mã định danh quỹ (UUID)
  final String id;

  /// Mã người dùng sở hữu
  final String nguoiDungId;

  /// Tên quỹ / mục tiêu tích lũy (Ví dụ: Đổi xe máy, Quỹ khẩn cấp)
  final String tenQuy;

  /// Key biểu tượng đại diện
  final String bieuTuong;

  /// Số tiền mục tiêu cần đạt
  final double soTienMucTieu;

  /// Số tiền hiện có đã nạp
  final double soTienHienCo;

  /// Nguồn tiền tự động trích hàng tháng (ID tài khoản/ví)
  final String? nguonTrichId;

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
    this.bieuTuong = 'xe_may',
    required this.soTienMucTieu,
    this.soTienHienCo = 0.0,
    this.nguonTrichId,
    this.kyHanThang = 12,
    this.ngayVeDich,
    this.nhacNhoDinhKy = true,
    this.taoLuc,
  });

  /// Danh sách Biểu tượng gợi ý mặc định lấy từ Model
  static List<BieuTuongQuyOption> get danhSachBieuTuongGoiY => [
        BieuTuongQuyOption(key: 'xeMay', label: 'Xe mới', icon: BieuTuong.xeMay),
        BieuTuongQuyOption(key: 'mayBay', label: 'Du lịch', icon: Icons.flight_takeoff_rounded),
        BieuTuongQuyOption(key: 'hoaDon', label: 'Mua nhà', icon: BieuTuong.hoaDon),
        BieuTuongQuyOption(key: 'lapTop', label: 'Công nghệ', icon: Icons.laptop_chromebook_rounded),
        BieuTuongQuyOption(key: 'khienBaoMat', label: 'Dự phòng', icon: BieuTuong.khienBaoMatDay),
        BieuTuongQuyOption(key: 'hocTap', label: 'Học tập', icon: BieuTuong.hocTap),
      ];

  /// Tính phần trăm tiến độ hoàn thành mục tiêu (%)
  double get phanTramHoanThanh =>
      soTienMucTieu > 0 ? (soTienHienCo / soTienMucTieu) * 100 : 0;

  /// Tính số tiền còn thiếu để về đích
  double get soTienConLai =>
      soTienMucTieu > soTienHienCo ? soTienMucTieu - soTienHienCo : 0;

  /// Getter OOP: Tự chuyển đổi thuộc tính `bieuTuong` hoặc `tenQuy` ra `IconData`
  IconData get iconData {
    final key = bieuTuong.toLowerCase().trim();
    final name = tenQuy.toLowerCase().trim();

    if (key.contains('khieu') || key.contains('shield') || key.contains('khien') || name.contains('khẩn cấp') || name.contains('dự phòng')) {
      return BieuTuong.khienBaoMatDay;
    }
    if (key.contains('maybay') || key.contains('plane') || key.contains('flight') || name.contains('du lịch') || name.contains('bay')) {
      return Icons.flight_takeoff_rounded;
    }
    if (key.contains('xemay') || key.contains('motorcycle') || name.contains('xe')) {
      return BieuTuong.xeMay;
    }
    if (key.contains('nha') || key.contains('house') || name.contains('nhà') || name.contains('căn hộ')) {
      return BieuTuong.hoaDon;
    }
    return BieuTuong.nganSach;
  }

  /// Khởi tạo đối tượng QuyTietKiemModel từ bản ghi JSON của Supabase
  factory QuyTietKiemModel.fromJson(Map<String, dynamic> json) {
    return QuyTietKiemModel(
      id: json['id'] as String,
      nguoiDungId: json['nguoi_dung_id'] as String,
      tenQuy: json['ten_quy'] as String,
      bieuTuong: json['bieu_tuong'] as String? ?? 'xe_may',
      soTienMucTieu: (json['so_tien_muc_tieu'] as num).toDouble(),
      soTienHienCo: (json['so_tien_hien_co'] as num?)?.toDouble() ?? 0.0,
      nguonTrichId: json['nguon_trich_id'] as String?,
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
      'bieu_tuong': bieuTuong,
      'so_tien_muc_tieu': soTienMucTieu,
      'so_tien_hien_co': soTienHienCo,
      'nguon_trich_id': (nguonTrichId != null && nguonTrichId!.trim().isNotEmpty) ? nguonTrichId : null,
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

/// Extension OOP hỗ trợ danh sách `List<QuyTietKiemModel>` tra cứu tên & icon nhanh
extension QuyTietKiemListX on List<QuyTietKiemModel> {
  /// Tìm đối tượng quỹ theo `quyId`
  QuyTietKiemModel? timTheoId(String? quyId) {
    if (quyId == null || quyId.isEmpty) return null;
    final list = where((q) => q.id == quyId).toList();
    return list.isNotEmpty ? list.first : null;
  }

  /// Lấy IconData của quỹ theo `quyId` (Tự động fallback)
  IconData layIcon(String? quyId) {
    final q = timTheoId(quyId);
    if (q != null) return q.iconData;
    return BieuTuong.nganSach;
  }
}
