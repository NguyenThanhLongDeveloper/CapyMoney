import 'package:flutter/material.dart';

/// Quy chuẩn Bán Kính Bo Góc (Border Radius Token)
/// 
/// Giúp tạo sự đồng nhất giao diện mượt mà và tròn trịa theo phong cách Neo-Fintech.
class BoGoc {
  BoGoc._();

  // Giá trị bán kính bo góc (pixels)
  static const double nho = 8.0;
  static const double vua = 16.0;
  static const double lon = 24.0;
  static const double sieuLon = 32.0;

  /// Bo góc nhỏ (8px) cho Button nhỏ, Chip, Input
  static const BorderRadius borderNho = BorderRadius.all(Radius.circular(nho));

  /// Bo góc vừa (16px) cho Thẻ Card, Item Danh sách
  static const BorderRadius borderVua = BorderRadius.all(Radius.circular(vua));

  /// Bo góc lớn (24px) cho Container chính, Khung Profile
  static const BorderRadius borderLon = BorderRadius.all(Radius.circular(lon));

  /// Bo góc siêu lớn (32px) cho Thẻ Tài sản
  static const BorderRadius borderSieuLon = BorderRadius.all(Radius.circular(sieuLon));

  /// Bo tròn hoàn toàn (Pill Shape) cho Button CTA
  static const BorderRadius borderTron = BorderRadius.all(Radius.circular(999.0));

  /// Bo góc đỉnh trên cho Bảng trượt (Bottom Sheet - 24px)
  static const BorderRadius borderBottomSheet = BorderRadius.vertical(
    top: Radius.circular(lon),
  );
}
