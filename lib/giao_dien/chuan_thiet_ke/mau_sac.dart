import 'package:flutter/material.dart';

/// Quy chuẩn mã màu Kinetic Neo-Fintech Dark Mode cho ứng dụng CapyMoney
class MauSac {
  MauSac._();

  // Nền ứng dụng (Background & Surface)
  static const Color nenChinh = Color(0xFF0E131F); // Dark Obsidian Blue
  static const Color nenThe = Color(0xFF161D2E);    // Surface Card
  static const Color nenNoi = Color(0xFF25304B);   // Surface Elevated (badge, chip, input phụ)

  // Màu điểm nhấn (Accents)
  static const Color chuDao = Color(0xFF00F59B);  // Neon Mint Green (tăng trưởng, thu nhập)
  static const Color phu = Color(0xFFD2BBFF);     // Lavender Purple (thưởng KPI, đặc biệt)

  // Trạng thái tài chính (Financial Status)
  static const Color thuNhap = Color(0xFF00F59B); // Neon Mint Green
  static const Color chiTieu = Color(0xFFFB7185);  // Coral Red (cảnh báo chi tiêu, tiền trừ)
  static const Color canhBao = Color(0xFFFBBF24);  // Amber Gold (chờ duyệt / lưu ý)
  static const Color chuyenTien = Color(0xFF60A5FA); // Blue accent

  // Màu chữ (Typography Colors)
  static const Color chuChinh = Color(0xFFF8FAFC); // Text Primary
  static const Color chuPhu = Color(0xFF94A3B8);   // Text Secondary
  static const Color chuMo = Color(0xFF64748B);    // Text Muted

  // Viền & Phân cách (Borders & Dividers)
  static const Color duongVien = Color(0xFF2E3A52);
  static const Color duongVienNhat = Color(0xFF1E293B);
}
