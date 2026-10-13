import 'package:flutter/material.dart';

/// Tiêu chuẩn khoảng cách (Padding / Margin) dùng chung trong CapyMoney
class KhoangCach {
  KhoangCach._();

  static const double sieuNho = 4.0;
  static const double nho = 8.0;
  static const double vua = 12.0;
  static const double phatChuan = 16.0;
  static const double lon = 24.0;
  static const double sieuLon = 32.0;

  // EdgeInsets hay dùng
  static const EdgeInsets lToanBoNho = EdgeInsets.all(nho);
  static const EdgeInsets lToanBoChuan = EdgeInsets.all(phatChuan);
  static const EdgeInsets lToanBoLon = EdgeInsets.all(lon);

  static const EdgeInsets lNgangChuan = EdgeInsets.symmetric(horizontal: phatChuan);
  static const EdgeInsets lNgangLon = EdgeInsets.symmetric(horizontal: lon);

  static const EdgeInsets lDocChuan = EdgeInsets.symmetric(vertical: phatChuan);
  static const EdgeInsets lDocNho = EdgeInsets.symmetric(vertical: nho);
}
