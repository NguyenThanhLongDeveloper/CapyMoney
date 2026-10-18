/// Quản lý tập trung toàn bộ Hằng Số Tên Bảng, Tháp Lưu Trữ và Endpoints trong dự án
/// 
/// Giúp tập trung hóa cấu hình (Centralized Endpoints). Khi Backend Supabase thay đổi tên bảng 
/// hoặc tên Storage Bucket, chỉ cần chỉnh sửa duy nhất 1 dòng tại file này.
class DuongDanApi {
  DuongDanApi._();

  // ==========================================
  // TÊN BẢNG CSDL (DATABASE TABLES)
  // ==========================================

  /// Bảng lưu trữ thông tin cá nhân và cấu hình người dùng
  static const String bangNguoiDung = 'nguoi_dung';

  /// Bảng lưu trữ tài khoản ngân hàng và ví điện tử liên kết
  static const String bangTaiKhoanNganHang = 'tai_khoan_ngan_hang';

  /// Bảng lưu trữ phân loại danh mục thu chi
  static const String bangDanhMuc = 'danh_muc';

  /// Bảng lưu trữ nhật ký giao dịch thu chi
  static const String bangGiaoDich = 'giao_dich';

  /// Bảng lưu trữ quỹ tiết kiệm và mục tiêu tích lũy
  static const String bangQuyTietKiem = 'quy_tiet_kiem';

  /// Bảng lưu trữ nhật ký nạp / rút tiền khỏi quỹ
  static const String bangLichSuQuy = 'lich_su_quy';

  // ==========================================
  // THÁP LƯU TRỮ TỆP (STORAGE BUCKETS)
  // ==========================================

  /// Tháp lưu trữ ảnh đại diện người dùng
  static const String thapAvatars = 'avatars';

  /// Tháp lưu trữ ảnh hóa đơn chứng từ chụp kèm
  static const String thapHoaDon = 'hoa_don';

  // ==========================================
  // DEEP LINK SCHEMES & REDIRECT ENDPOINTS
  // ==========================================

  /// Scheme điều hướng khi đăng nhập Google OAuth trên thiết bị Di động
  static const String redirectLoginCallback = 'capymoney://login-callback';
}
