import 'package:flutter/material.dart';
import '../giao_dien/chuan_thiet_ke/bieu_tuong.dart';

/// Mô hình dữ liệu Danh Mục Ngân Sách & Tiết Kiệm (Savings Category Model)
/// 
/// Quản lý phân loại mục tiêu tích lũy (Xe mới, Du lịch, Mua nhà...) trong bảng `danh_muc_ngan_sach`.
class DanhMucNganSachModel {
  /// Mã định danh danh mục (UUID)
  final String id;

  /// Mã người dùng sở hữu (Null nếu là danh mục hệ thống)
  final String? nguoiDungId;

  /// Tên danh mục hiển thị
  final String tenDanhMuc;

  /// Key biểu tượng đại diện
  final String bieuTuong;

  /// Mã màu Hex dạng `#RRGGBB`
  final String mauSac;

  DanhMucNganSachModel({
    required this.id,
    this.nguoiDungId,
    required this.tenDanhMuc,
    required this.bieuTuong,
    this.mauSac = '#00F59B',
  });

  /// Khởi tạo đối tượng DanhMucNganSachModel từ bản ghi JSON của Supabase
  factory DanhMucNganSachModel.fromJson(Map<String, dynamic> json) {
    return DanhMucNganSachModel(
      id: json['id'] as String,
      nguoiDungId: json['nguoi_dung_id'] as String?,
      tenDanhMuc: json['ten_danh_muc'] as String,
      bieuTuong: json['bieu_tuong'] as String? ?? 'nganSach',
      mauSac: json['mau_sac'] as String? ?? '#00F59B',
    );
  }

  /// Chuyển đổi đối tượng sang định dạng JSON để ghi vào Supabase
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'ten_danh_muc': tenDanhMuc,
      'bieu_tuong': bieuTuong,
      'mau_sac': mauSac,
    };

    if (nguoiDungId != null && nguoiDungId!.trim().isNotEmpty) {
      data['nguoi_dung_id'] = nguoiDungId;
    }

    if (id.trim().isNotEmpty) {
      data['id'] = id;
    }

    return data;
  }

  /// Getter OOP: Tự chuyển đổi thuộc tính `bieuTuong` hoặc `tenDanhMuc` ra `IconData`
  IconData get iconData {
    final key = bieuTuong.toLowerCase().trim();
    final name = tenDanhMuc.toLowerCase().trim();

    // 1. Ánh xạ trực tiếp trong CSDL Supabase
    if (key == 'xeMay' || key.contains('xe') || name.contains('xe')) {
      return BieuTuong.xeMay;
    }
    if (key == 'mayBay' || key.contains('bay') || key.contains('flight') || name.contains('du lịch')) {
      return BieuTuong.mayBay;
    }
    if (key == 'lapTop' || key.contains('cong_nghe') || name.contains('công nghệ') || name.contains('máy tính')) {
      return BieuTuong.lapTop;
    }
    if (key == 'hocTap' || key.contains('school') || name.contains('học')) {
      return BieuTuong.hocTap;
    }
    if (key == 'giaTri' || key.contains('dautu') || name.contains('đầu tư')) {
      return BieuTuong.giaTri;
    }

    return BieuTuong.nganSach;
  }

  /// Getter OOP: Chuyển đổi mã màu Hex (`#00F59B`) ra Flutter `Color`
  Color get mauSacColor {
    try {
      final hex = mauSac.replaceAll('#', '').trim();
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF00F59B);
  }
}

/// Extension OOP hỗ trợ danh sách `List<DanhMucNganSachModel>` tra cứu tên, icon & màu nhanh
extension DanhMucNganSachListX on List<DanhMucNganSachModel> {
  /// Tìm đối tượng danh mục theo `id`
  DanhMucNganSachModel? timTheoId(String? danhMucId) {
    if (danhMucId == null || danhMucId.isEmpty) return null;
    final list = where((d) => d.id == danhMucId).toList();
    return list.isNotEmpty ? list.first : null;
  }

  /// Lấy IconData của danh mục theo `danhMucId` (Tự động fallback)
  IconData layIcon(String? danhMucId) {
    final dm = timTheoId(danhMucId);
    if (dm != null) return dm.iconData;
    return BieuTuong.nganSach;
  }

  /// Lấy Tên danh mục theo `danhMucId` (Tự động fallback)
  String layTen(String? danhMucId) {
    final dm = timTheoId(danhMucId);
    if (dm != null) return dm.tenDanhMuc;
    return 'Mục tiêu tiết kiệm';
  }

  /// Lấy Color của danh mục theo `danhMucId` (Tự động fallback)
  Color layMauSac(String? danhMucId) {
    final dm = timTheoId(danhMucId);
    if (dm != null) return dm.mauSacColor;
    return const Color(0xFF00F59B);
  }
}
