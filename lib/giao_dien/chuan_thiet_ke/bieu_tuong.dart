import 'package:flutter/material.dart';

/// Quản lý Bảng Biểu Tượng (Icon Token System)
/// 
/// Tổng hợp bộ icon bo tròn hiện đại dùng cho thanh điều hướng, danh mục thu chi và chức năng.
class BieuTuong {
  BieuTuong._();

  // ==========================================
  // BIỂU TƯỢNG THANH ĐIỀU HƯỚNG (NAVIGATION ICONS)
  // ==========================================

  /// Tab Tổng quan (Dashboard)
  static const IconData tongQuan = Icons.grid_view_rounded;

  /// Tab Báo cáo & Phân tích
  static const IconData baoCao = Icons.bar_chart_rounded;

  /// Tab Ngân sách & Hạn mức
  static const IconData nganSach = Icons.account_balance_wallet_rounded;

  /// Tab Tài khoản Tôi
  static const IconData taiKhoan = Icons.person_rounded;

  // ==========================================
  // THAO TÁC GIAO DỊCH TÀI CHÍNH
  // ==========================================

  /// Nút Thêm giao dịch (+)
  static const IconData themGiaoDich = Icons.add_rounded;

  /// Thu nhập (Mũi tên xuống / Nạp vào)
  static const IconData thuNhap = Icons.arrow_downward_rounded;

  /// Chi tiêu (Mũi tên lên / Rút ra)
  static const IconData chiTieu = Icons.arrow_upward_rounded;

  /// Chuyển khoản nội bộ
  static const IconData chuyenTien = Icons.swap_horiz_rounded;

  /// Rút tiền khỏi quỹ
  static const IconData rutTien = Icons.upload_rounded;

  /// Nạp tiền vào quỹ
  static const IconData napTien = Icons.download_rounded;

  // ==========================================
  // BIỂU TƯỢNG DANH MỤC THU CHI (CATEGORIES)
  // ==========================================

  /// Ăn uống, nhà hàng
  static const IconData antUong = Icons.restaurant_rounded;

  /// Đi lại, xăng xe, Grab
  static const IconData diLai = Icons.directions_car_rounded;

  /// Mua sắm, siêu thị
  static const IconData muaSam = Icons.shopping_bag_rounded;

  /// Hóa đơn điện nước, Internet
  static const IconData hoaDon = Icons.receipt_long_rounded;

  /// Lương, thưởng KPI
  static const IconData giaTri = Icons.stars_rounded;

  /// Giải trí, game, phim
  static const IconData giaiTri = Icons.sports_esports_rounded;

  /// Sức khỏe, thuốc men
  static const IconData sucKhoe = Icons.medical_services_rounded;

  /// Giáo dục, học tập
  static const IconData hocTap = Icons.school_rounded;

  // ==========================================
  // TIỆN ÍCH & HỆ THỐNG
  // ==========================================

  /// Bộ lọc thời gian/danh mục
  static const IconData loc = Icons.filter_alt_rounded;

  /// Lịch chọn ngày
  static const IconData lich = Icons.calendar_month_rounded;

  /// Tài khoản Ngân hàng
  static const IconData nganHang = Icons.account_balance_rounded;

  /// Chụp/Quét hóa đơn
  static const IconData anhHoaDon = Icons.center_focus_strong_rounded;

  /// Cài đặt hệ thống
  static const IconData caiDat = Icons.settings_rounded;

  /// Biểu tượng linh vật Capybara Thần tài
  static const IconData capybaraThantai = Icons.pets_rounded;
}
