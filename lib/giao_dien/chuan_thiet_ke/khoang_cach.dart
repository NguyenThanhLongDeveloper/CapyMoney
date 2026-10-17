import 'package:flutter/material.dart';

/// Quy chuẩn Khoảng Cách Lề (Padding & Margin Token)
/// 
/// Định nghĩa các hệ số căn lề chuẩn lưới (Grid System) cho giao diện CapyMoney.
class KhoangCach {
  KhoangCach._();

  // Giá trị khoảng cách tuyệt đối (pixels)
  static const double sieuNho = 4.0;
  static const double nho = 8.0;
  static const double vua = 12.0;
  static const double phatChuan = 16.0;
  static const double lon = 24.0;
  static const double sieuLon = 32.0;

  /// Lề toàn bộ nhỏ (8px)
  static const EdgeInsets lToanBoNho = EdgeInsets.all(nho);

  /// Lề toàn bộ chuẩn (16px)
  static const EdgeInsets lToanBoChuan = EdgeInsets.all(phatChuan);

  /// Lề toàn bộ lớn (24px)
  static const EdgeInsets lToanBoLon = EdgeInsets.all(lon);

  /// Lề ngang chuẩn (16px)
  static const EdgeInsets lNgangChuan = EdgeInsets.symmetric(horizontal: phatChuan);

  /// Lề ngang màn hình lớn (24px)
  static const EdgeInsets lNgangLon = EdgeInsets.symmetric(horizontal: lon);

  /// Lề dọc chuẩn (16px)
  static const EdgeInsets lDocChuan = EdgeInsets.symmetric(vertical: phatChuan);

  /// Lề dọc nhỏ (8px)
  static const EdgeInsets lDocNho = EdgeInsets.symmetric(vertical: nho);
}
