import 'package:flutter/material.dart';
import 'mau_sac.dart';

/// Quy chuẩn Kiểu Chữ và Font Chữ (Typography Token)
/// 
/// Tích hợp font Plus Jakarta Sans và tính năng số gióng hàng thẳng (Tabular Numerals) cho số tiền.
class KieuChu {
  KieuChu._();

  /// Tên phông chữ mặc định của hệ thống
  static const String fontMacDinh = 'PlusJakartaSans';

  // ==========================================
  // TIÊU ĐỀ (HEADINGS)
  // ==========================================

  /// Tiêu đề lớn (28px - Bold)
  static const TextStyle tieuDeLon = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: MauSac.chuChinh,
    letterSpacing: -0.5,
  );

  /// Tiêu đề vừa (20px - SemiBold)
  static const TextStyle tieuDeVua = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: MauSac.chuChinh,
  );

  /// Tiêu đề nhỏ (16px - SemiBold)
  static const TextStyle tieuDeNho = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: MauSac.chuChinh,
  );

  // ==========================================
  // NỘI DUNG VĂN BẢN (BODY TEXT)
  // ==========================================

  /// Nội dung chính (14px - Regular)
  static const TextStyle noiDungChinh = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: MauSac.chuChinh,
  );

  /// Nội dung phụ / Chú thích (12px - Regular)
  static const TextStyle noiDungPhu = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: MauSac.chuPhu,
  );

  // ==========================================
  // HIỂN THỊ SỐ TIỀN & CHỈ SỐ (CURRENCY NUMERALS)
  // ==========================================

  /// Hiển thị Số tiền lớn (32px - Neon Mint Bold)
  static const TextStyle soTienLon = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: MauSac.chuDao,
    letterSpacing: -0.8,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Hiển thị Số tiền vừa (22px - Bold)
  static const TextStyle soTienVua = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: MauSac.chuChinh,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Hiển thị Số tiền chi tiêu / trừ (-16px - Red Coral Bold)
  static const TextStyle soTienChiTieu = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: MauSac.chiTieu,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Hiển thị Số tiền thu nhập / cộng (+16px - Mint Bold)
  static const TextStyle soTienThuNhap = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: MauSac.thuNhap,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
