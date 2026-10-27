import 'package:flutter/material.dart';
import '../giao_dien/chuan_thiet_ke/bieu_tuong.dart';

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

  /// Tên icon đại diện (Icon key trong Supabase)
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

  /// Getter OOP: Tự chuyển đổi thuộc tính `bieuTuong` hoặc `tenDanhMuc` ra `IconData`
  IconData get iconData {
    final key = bieuTuong.trim();
    final keyLower = key.toLowerCase();
    final name = tenDanhMuc.toLowerCase().trim();

    // 1. Ánh xạ trực tiếp chuẩn 100% tên cột `bieu_tuong` trong CSDL Supabase
    if (key == 'giaTri' || keyLower == 'giatri' || keyLower.contains('luong')) {
      return BieuTuong.giaTri; // ⭐ Stars / Thưởng KPI & Lương
    }
    if (key == 'thuong' || keyLower == 'thuong') {
      return BieuTuong.thuong; // 💵 Thưởng & Thu nhập phụ
    }
    if (key == 'sucKhoe' || keyLower == 'suckhoe' || keyLower == 'medical_services') {
      return BieuTuong.sucKhoe; // 💊 Sức khỏe & Y tế
    }
    if (key == 'antUong' || keyLower == 'antuong' || keyLower == 'restaurant' || keyLower == 'food' || keyLower.contains('an_uong')) {
      return BieuTuong.antUong; // 🍴 Ăn uống & Nhà hàng
    }
    if (key == 'diLai' || keyLower == 'dilai' || keyLower == 'directions_car' || keyLower == 'car' || keyLower.contains('di_lai') || keyLower.contains('xang_xe')) {
      return BieuTuong.diLai; // 🚗 Di chuyển & Xăng xe
    }
    if (key == 'muaSam' || keyLower == 'muasam' || keyLower == 'shopping_bag' || keyLower.contains('mua_sam')) {
      return BieuTuong.muaSam; // 🛍 Mua sắm & Siêu thị
    }
    if (key == 'giaiTri' || keyLower == 'giaitri' || keyLower == 'sports_esports' || keyLower.contains('giai_tri')) {
      return BieuTuong.giaiTri; // 🎮 Giải trí & Thể thao
    }
    if (key == 'hoaDon' || keyLower == 'hoadon' || keyLower == 'receipt_long' || keyLower.contains('hoa_don')) {
      return BieuTuong.hoaDon; // 📄 Hóa đơn & Tiện ích
    }
    if (key == 'caPhe' || keyLower == 'caphe' || keyLower == 'local_cafe' || keyLower.contains('cafe')) {
      return BieuTuong.caPhe; // ☕ Cà phê / Giải khát
    }
    if (key == 'xeMay' || keyLower == 'xemay' || keyLower == 'two_wheeler') {
      return BieuTuong.xeMay; // 🛵 Xe máy
    }



    return loai == 'thu_nhap' ? BieuTuong.nganHang : BieuTuong.gioHang;
  }
}

/// Extension OOP hỗ trợ danh sách `List<DanhMucModel>` tra cứu tên & icon nhanh gọn
extension DanhMucListX on List<DanhMucModel> {
  /// Tìm đối tượng danh mục theo `danhMucId`
  DanhMucModel? timTheoId(String? danhMucId) {
    if (danhMucId == null || danhMucId.isEmpty) return null;
    final list = where((d) => d.id == danhMucId).toList();
    return list.isNotEmpty ? list.first : null;
  }

  /// Lấy IconData của danh mục theo `danhMucId` (Tự động fallback)
  IconData layIcon(String? danhMucId, {bool isThu = false}) {
    final dm = timTheoId(danhMucId);
    if (dm != null) return dm.iconData;
    return isThu ? BieuTuong.nganHang : BieuTuong.gioHang;
  }

  /// Lấy Tên danh mục theo `danhMucId` (Tự động fallback)
  String layTen(String? danhMucId, {bool isThu = false}) {
    final dm = timTheoId(danhMucId);
    if (dm != null) return dm.tenDanhMuc;
    return isThu ? 'Khoản thu nhập' : 'Khoản chi tiêu';
  }
}
