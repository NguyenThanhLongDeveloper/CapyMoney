import 'package:flutter/material.dart';

/// Quy chuẩn Mã Màu Thiết kế Kinetic Neo-Fintech Dark Mode
/// 
/// Lớp định nghĩa tập hợp các bảng màu thương hiệu chuẩn tài chính của CapyMoney.
class MauSac {
  MauSac._();

  // ==========================================
  // MÀU NỀN ỨNG DỤNG (BACKGROUND & SURFACE)
  // ==========================================
  
  /// Màu nền chính toàn ứng dụng (Dark Obsidian Blue `#0E131F`)
  static const Color nenChinh = Color(0xFF0E131F);

  /// Màu nền thẻ, card và container nổi (`#161D2E`)
  static const Color nenThe = Color(0xFF161D2E);

  /// Màu nền khối nổi cao, chip, input (`#25304B`)
  static const Color nenNoi = Color(0xFF25304B);

  // ==========================================
  // MÀU THƯƠNG HIỆU & ĐIỂM NHẤN (ACCENT COLORS)
  // ==========================================

  /// Màu thương hiệu chủ đạo - Xanh Neon Mint (`#00F59B`)
  static const Color chuDao = Color(0xFF00F59B);

  /// Màu điểm nhấn phụ - Tím Lavender (`#D2BBFF`)
  static const Color phu = Color(0xFFD2BBFF);

  // ==========================================
  // MÀU TRẠNG THÁI TÀI CHÍNH (FINANCIAL STATUS)
  // ==========================================

  /// Màu dòng tiền thu nhập / số dương (`#00F59B`)
  static const Color thuNhap = Color(0xFF00F59B);

  /// Màu khoản chi tiêu / số âm / cảnh báo (`#FB7185`)
  static const Color chiTieu = Color(0xFFFB7185);

  /// Màu lưu ý / chờ xử lý - Vàng Amber (`#FBBF24`)
  static const Color canhBao = Color(0xFFFBBF24);

  /// Màu giao dịch chuyển khoản - Xanh Dương (`#60A5FA`)
  static const Color chuyenTien = Color(0xFF60A5FA);

  // ==========================================
  // MÀU CHỮ & TYPOGRAPHY (TEXT COLORS)
  // ==========================================

  /// Màu chữ tiêu đề chính - Trắng Sáng (`#F8FAFC`)
  static const Color chuChinh = Color(0xFFF8FAFC);

  /// Màu chữ nội dung phụ - Xám Bạc (`#94A3B8`)
  static const Color chuPhu = Color(0xFF94A3B8);

  /// Màu chữ mờ / chú thích nhỏ (`#64748B`)
  static const Color chuMo = Color(0xFF64748B);

  // ==========================================
  // MÀU ĐƯỜNG VIỀN & PHÂN CÁCH (BORDERS)
  // ==========================================

  /// Đường viền chuẩn card (`#2E3A52`)
  static const Color duongVien = Color(0xFF2E3A52);

  /// Đường viền mờ nhẹ (`#1E293B`)
  static const Color duongVienNhat = Color(0xFF1E293B);
}
