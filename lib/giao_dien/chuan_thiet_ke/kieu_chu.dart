import 'package:flutter/material.dart';
import 'mau_sac.dart';

/// Quy chuẩn kiểu chữ (Typography) cho CapyMoney
class KieuChu {
  KieuChu._();

  static const String fontMacDinh = 'PlusJakartaSans';

  // Tiêu đề lớn
  static const TextStyle tieuDeLon = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: MauSac.chuChinh,
    letterSpacing: -0.5,
  );

  // Tiêu đề vừa
  static const TextStyle tieuDeVua = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: MauSac.chuChinh,
  );

  // Tiêu đề nhỏ
  static const TextStyle tieuDeNho = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: MauSac.chuChinh,
  );

  // Nội dung chính
  static const TextStyle noiDungChinh = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: MauSac.chuChinh,
  );

  // Nội dung phụ
  static const TextStyle noiDungPhu = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: MauSac.chuPhu,
  );

  // Hiển thị số tiền (Tabular Numerals, đậm, tracking-tight)
  static const TextStyle soTienLon = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: MauSac.chuDao,
    letterSpacing: -0.8,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle soTienVua = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: MauSac.chuChinh,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle soTienChiTieu = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: MauSac.chiTieu,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle soTienThuNhap = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: MauSac.thuNhap,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
