import 'package:flutter/material.dart';

/// Tiêu chuẩn bo góc dùng chung trong ứng dụng CapyMoney
class BoGoc {
  BoGoc._();

  // Bán kính bo góc (Border Radius values)
  static const double nho = 8.0;
  static const double vua = 16.0;
  static const double lon = 24.0;
  static const double sieuLon = 32.0;

  // BorderRadius sẵn sàng sử dụng
  static const BorderRadius borderNho = BorderRadius.all(Radius.circular(nho));
  static const BorderRadius borderVua = BorderRadius.all(Radius.circular(vua));
  static const BorderRadius borderLon = BorderRadius.all(Radius.circular(lon));
  static const BorderRadius borderSieuLon = BorderRadius.all(Radius.circular(sieuLon));
  static const BorderRadius borderTron = BorderRadius.all(Radius.circular(999.0));

  // Bo góc dành riêng cho Bottom Sheet (chỉ bo góc trên)
  static const BorderRadius borderBottomSheet = BorderRadius.vertical(
    top: Radius.circular(lon),
  );
}
