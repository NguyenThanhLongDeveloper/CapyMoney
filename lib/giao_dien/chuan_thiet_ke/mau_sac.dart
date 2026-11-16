import 'package:flutter/material.dart';

/// Quy chuẩn Mã Màu Thiết kế CapyMoney Figma Theme
/// 
/// 3 Tông màu thương hiệu chủ đạo từ Figma:
/// - Xanh Dương Thương Hiệu (`#0297DE`)
/// - Trắng Nền Sáng (`#FFFFFF`)
/// - Hồng Magenta Điểm Nhấn (`#D83995`)
class MauSac {
  MauSac._();

  // ==========================================
  // MÀU NỀN ỨNG DỤNG (BACKGROUND & SURFACE)
  // ==========================================
  
  /// Màu nền chính toàn ứng dụng (`#FFFFFF` / `#F8FAFC`)
  static const Color nenChinh = Color(0xFFF8FAFC);

  /// Màu nền thẻ, card và container nổi (`#FFFFFF`)
  static const Color nenThe = Color(0xFFFFFFFF);

  /// Màu nền khối nổi cao, chip, input (`#F0F4FA`)
  static const Color nenNoi = Color(0xFFF0F4FA);

  // ==========================================
  // MÀU THƯƠNG HIỆU & ĐIỂM NHẤN (ACCENT COLORS)
  // ==========================================

  /// Màu thương hiệu chủ đạo - Xanh Dương Figma (`#0297DE`)
  static const Color chuDao = Color(0xFF0297DE);

  /// Màu điểm nhấn phụ - Hồng Magenta Figma (`#D83995`)
  static const Color phu = Color(0xFFD83995);

  // ==========================================
  // MÀU TRẠNG THÁI TÀI CHÍNH (FINANCIAL STATUS)
  // ==========================================

  /// Màu dòng tiền thu nhập / số dương (`#059669` Emerald Green)
  static const Color thuNhap = Color(0xFF059669);

  /// Màu khoản chi tiêu / số âm / cảnh báo (`#E11D48` Rose Red)
  static const Color chiTieu = Color(0xFFE11D48);

  /// Màu lưu ý / chờ xử lý - Vàng Amber (`#D97706`)
  static const Color canhBao = Color(0xFFD97706);

  /// Màu giao dịch chuyển khoản - Xanh Dương (`#0297DE`)
  static const Color chuyenTien = Color(0xFF0297DE);

  // ==========================================
  // MÀU CHỮ & TYPOGRAPHY (TEXT COLORS)
  // ==========================================

  /// Màu chữ tiêu đề chính - Đen Xám Đậm (`#0F172A`)
  static const Color chuChinh = Color(0xFF0F172A);

  /// Màu chữ nội dung phụ - Xám Vừa (`#475569`)
  static const Color chuPhu = Color(0xFF475569);

  /// Màu chữ mờ / chú thích nhỏ (`#94A3B8`)
  static const Color chuMo = Color(0xFF94A3B8);

  // ==========================================
  // MÀU ĐƯỜNG VIỀN & PHÂN CÁCH (BORDERS)
  // ==========================================

  /// Đường viền chuẩn card (`#CBD5E1`)
  static const Color duongVien = Color(0xFFCBD5E1);

  /// Đường viền mờ nhẹ (`#E2E8F0`)
  static const Color duongVienNhat = Color(0xFFE2E8F0);
}
