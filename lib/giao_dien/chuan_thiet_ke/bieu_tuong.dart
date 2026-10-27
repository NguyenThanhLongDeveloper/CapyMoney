import 'package:flutter/material.dart';

/// Quản lý Bảng Biểu Tượng Tập Trung (Central Icon Token System)
/// 
/// Tập trung hóa 100% bộ icon bo tròn dùng cho thanh điều hướng, danh mục, xác thực, giao dịch và hệ thống.
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
  // THAO TÁC GIAO DỊCH TÀI CHÍNH (FINANCIAL TRANSACTIONS)
  // ==========================================

  /// Nút Thêm giao dịch (+)
  static const IconData themGiaoDich = Icons.add_rounded;

  /// Thêm tròn viền
  static const IconData themTronVien = Icons.add_circle_outline_rounded;

  /// Thu nhập (Mũi tên xuống / Nạp vào)
  static const IconData thuNhap = Icons.arrow_downward_rounded;

  /// Chi tiêu (Mũi tên lên / Rút ra)
  static const IconData chiTieu = Icons.arrow_upward_rounded;

  /// Chuyển khoản nội bộ / Đổi tài khoản
  static const IconData chuyenTien = Icons.swap_horiz_rounded;

  /// Rút tiền khỏi quỹ
  static const IconData rutTien = Icons.upload_rounded;

  /// Nạp tiền vào quỹ
  static const IconData napTien = Icons.download_rounded;

  /// Xe máy / Mục tiêu mua sắm
  static const IconData xeMay = Icons.two_wheeler_rounded;

  /// Giỏ hàng siêu thị
  static const IconData gioHang = Icons.shopping_cart_rounded;

  /// Cà phê / Giải khát
  static const IconData caPhe = Icons.local_cafe_rounded;

  /// Ô tô / Grab Car
  static const IconData oTo = Icons.directions_car_rounded;

  /// Sao kê / Chứng từ
  static const IconData saoKe = Icons.receipt_long_rounded;

  /// Thẻ ngân hàng / Visa
  static const IconData theNganHang = Icons.credit_card_rounded;

  /// Thêm ví / Thêm thẻ
  static const IconData themVi = Icons.add_card_rounded;

  /// Ví rỗng / Chưa liên kết
  static const IconData viRong = Icons.account_balance_wallet_outlined;

  /// Biểu đồ tròn phân bổ
  static const IconData bieuDoTron = Icons.pie_chart_outline_rounded;

  /// Tự động / Lấp lánh
  static const IconData lapLanh = Icons.auto_awesome_rounded;

  /// Xu hướng giảm
  static const IconData xuHuongGiam = Icons.trending_down_rounded;

  /// Xu hướng tăng
  static const IconData xuHuongTang = Icons.trending_up_rounded;

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

  /// thưởng, thu nhập phụ
  static const IconData thuong = Icons.category_rounded;

  // ==========================================
  // XÁC THỰC & BẢO MẬT (AUTH & SECURITY)
  // ==========================================

  /// Biểu tượng Sét phát sáng
  static const IconData setPhatSang = Icons.bolt_rounded;

  /// Biểu tượng Khiên bảo mật
  static const IconData khienBaoMat = Icons.shield_outlined;

  /// Biểu tượng Khiên bảo mật đầy
  static const IconData khienBaoMatDay = Icons.shield_rounded;

  /// Biểu tượng Khóa mật khẩu
  static const IconData khoaMatKhau = Icons.lock_outline_rounded;

  /// Biểu tượng Khóa mật khẩu đầy
  static const IconData khoaMatKhauDay = Icons.lock_rounded;

  /// Mắt xem mật khẩu
  static const IconData matXem = Icons.visibility_outlined;

  /// Mắt ẩn mật khẩu
  static const IconData matAn = Icons.visibility_off_outlined;

  /// Quét vân tay / Sinh trắc học
  static const IconData vanTay = Icons.fingerprint_rounded;

  /// Người dùng đã xác thực
  static const IconData xacThucNguoiDung = Icons.verified_user_rounded;

  /// Người dùng viền
  static const IconData xacThucNguoiDungVien = Icons.verified_user_outlined;

  /// Mũi tên quay lại trái
  static const IconData muiTenTrai = Icons.chevron_left_rounded;

  /// Mũi tên sang phải
  static const IconData muiTenPhai = Icons.chevron_right_rounded;

  /// Mũi tên tiến tới
  static const IconData muiTenTien = Icons.arrow_forward_rounded;

  /// Mũi tên lùi
  static const IconData muiTenLui = Icons.arrow_back_rounded;

  /// Mũi tên chỉ xuống dropdown
  static const IconData muiTenXuong = Icons.keyboard_arrow_down_rounded;

  /// Mũi tên chỉ lên
  static const IconData muiTenLen = Icons.keyboard_arrow_up_rounded;

  /// Dấu chấm tròn nhỏ
  static const IconData chamTron = Icons.circle;

  /// Dấu chấm tròn viền
  static const IconData chamTronVien = Icons.circle_outlined;

  /// Dấu tích chọn thành công
  static const IconData dauTich = Icons.check_rounded;

  /// Dấu tích tròn
  static const IconData dauTichTron = Icons.check_circle_rounded;

  /// Dấu tích tròn viền
  static const IconData dauTichTronVien = Icons.check_circle_outline_rounded;

  /// Dấu X đóng
  static const IconData dongX = Icons.close_rounded;

  /// Dấu X tròn xóa
  static const IconData xoaTron = Icons.cancel_rounded;

  /// Phím Xóa Lùi Numpad
  static const IconData xoaLui = Icons.backspace_outlined;

  /// Xóa viền
  static const IconData xoaVien = Icons.delete_outline_rounded;

  /// Cảnh báo / Chú ý
  static const IconData canhBao = Icons.warning_amber_rounded;

  /// Lỗi tròn
  static const IconData loiTron = Icons.error_rounded;

  /// Tìm kiếm
  static const IconData timKiem = Icons.search_rounded;

  /// Làm mới / Đồng bộ
  static const IconData lamMoi = Icons.refresh_rounded;

  /// Xoay đồng bộ
  static const IconData dongBo = Icons.sync_rounded;

  /// Email / Thư
  static const IconData email = Icons.email_outlined;

  /// Email A còng
  static const IconData emailA = Icons.alternate_email_rounded;

  /// Email đã đọc / Khôi phục
  static const IconData emailKhoiPhuc = Icons.mark_email_read_rounded;

  /// Email chưa đọc
  static const IconData emailChuaDoc = Icons.mark_email_unread_rounded;

  /// Chuông thông báo
  static const IconData thongBaoChuong = Icons.notifications_active_rounded;

  /// Đồng hồ thời gian
  static const IconData dongHo = Icons.access_time_rounded;

  /// Đồng hồ thời gian đầy
  static const IconData dongHoDay = Icons.access_time_filled_rounded;

  /// Số điện thoại
  static const IconData dienThoai = Icons.phone_outlined;

  /// Điện thoại di động
  static const IconData dienThoaiDiDong = Icons.phone_android_rounded;

  /// Số tài khoản / Số đếm
  static const IconData soTaiKhoan = Icons.numbers_rounded;

  /// Máy ảnh Camera
  static const IconData mayAnh = Icons.camera_alt_rounded;

  /// Máy ảnh Chụp
  static const IconData mayAnhChup = Icons.photo_camera_rounded;

  /// Thư viện ảnh Gallery
  static const IconData thuVienAnh = Icons.photo_library_rounded;

  /// Chỉnh sửa / Viết
  static const IconData chinhSua = Icons.edit_rounded;

  /// Chỉnh sửa viền
  static const IconData chinhSuaVien = Icons.edit_outlined;

  /// Chỉnh sửa Ghi chú
  static const IconData ghiChuSua = Icons.edit_note_rounded;

  /// Chỉnh sửa Lịch
  static const IconData lichSua = Icons.edit_calendar_rounded;

  /// Lịch ngày tổng quát
  static const IconData lichNgay = Icons.calendar_today_rounded;

  /// Lịch tháng
  static const IconData lichThang = Icons.calendar_month_rounded;

  /// Lịch dải ngày
  static const IconData lichDaiNgay = Icons.date_range_rounded;

  /// Lịch sử thao tác
  static const IconData lichSu = Icons.history_rounded;

  /// Lịch sử toggled
  static const IconData lichSuToggle = Icons.history_toggle_off_rounded;

  /// Gửi thư
  static const IconData guiThu = Icons.near_me_rounded;

  /// Đăng xuất
  static const IconData dangXuat = Icons.logout_rounded;

  /// Tài khoản Ngân hàng
  static const IconData nganHang = Icons.account_balance_rounded;

  /// Cài đặt hệ thống
  static const IconData caiDat = Icons.settings_rounded;

  /// Biểu tượng linh vật Capybara Thần tài
  static const IconData capybaraThantai = Icons.pets_rounded;
}
