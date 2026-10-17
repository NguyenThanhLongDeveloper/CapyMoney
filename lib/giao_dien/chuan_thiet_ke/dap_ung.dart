import 'package:flutter/material.dart';

/// Quy chuẩn Thiết kế Đáp ứng (Responsive Design) đa nền tảng cho Mobile, iPad, Web và PC
class DapUng {
  DapUng._();

  // Điểm ngắt kích thước màn hình (Breakpoints)
  static const double doRongDiDongTieuChuan = 600;
  static const double doRongMayTinhBangTieuChuan = 1024;

  /// Kiểm tra xem thiết bị có phải Màn hình Di động (Mobile) hay không
  static bool laDiDong(BuildContext context) =>
      MediaQuery.of(context).size.width < doRongDiDongTieuChuan;

  /// Kiểm tra xem thiết bị có phải Màn hình Máy tính bảng / iPad (Tablet) hay không
  static bool laMayTinhBang(BuildContext context) =>
      MediaQuery.of(context).size.width >= doRongDiDongTieuChuan &&
      MediaQuery.of(context).size.width < doRongMayTinhBangTieuChuan;

  /// Kiểm tra xem thiết bị có phải Màn hình Máy tính rộng / Web / PC (Desktop) hay không
  static bool laMayTinhRong(BuildContext context) =>
      MediaQuery.of(context).size.width >= doRongMayTinhBangTieuChuan;

  /// Khung bọc giới hạn chiều rộng tối đa cho màn hình Form/Xác thực (Tối đa 520px)
  static Widget bocKhungForm({required Widget child}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: child,
      ),
    );
  }

  /// Khung bọc giới hạn chiều rộng tối đa cho Dashboard và Màn hình chính (Tối đa 1100px)
  static Widget bocKhungNoiDung({required Widget child}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: child,
      ),
    );
  }
}
