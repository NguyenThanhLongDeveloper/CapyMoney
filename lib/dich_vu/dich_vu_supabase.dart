import 'package:supabase_flutter/supabase_flutter.dart';
import '../cau_hinh/cau_hinh_supabase.dart';
import '../mo_hinh/tai_khoan_ngan_hang_model.dart';
import '../mo_hinh/danh_muc_model.dart';
import '../mo_hinh/giao_dich_model.dart';
import '../mo_hinh/quy_tiet_kiem_model.dart';
import '../mo_hinh/lich_su_quy_model.dart';

/// Dịch vụ kết nối và thao tác với CSDL Supabase
class DichVuSupabase {
  DichVuSupabase._();

  static SupabaseClient get client => CauHinhSupabase.client;

  // ==========================================
  // XÁC THỰC NGƯỜI DÙNG (AUTH)
  // ==========================================

  /// Đăng nhập bằng Email & Mật khẩu
  static Future<AuthResponse> dangNhap(String email, String matKhau) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: matKhau,
    );
  }

  /// Đăng ký tài khoản mới
  static Future<AuthResponse> dangKy({
    required String hoTen,
    required String email,
    required String matKhau,
    String? soDienThoai,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: matKhau,
      data: {
        'ho_ten': hoTen,
        'so_dien_thoai': soDienThoai,
      },
    );
  }

  /// Quên mật khẩu - Gửi mã OTP khôi phục về Gmail
  static Future<void> guiMaKhoiPhuc(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  /// Xác thực mã OTP và đặt mật khẩu mới
  static Future<UserResponse> capNhatMatKhauMoi({
    required String email,
    required String maOtp,
    required String matKhauMoi,
  }) async {
    await client.auth.verifyOTP(
      email: email,
      token: maOtp,
      type: OtpType.recovery,
    );
    return await client.auth.updateUser(
      UserAttributes(password: matKhauMoi),
    );
  }

  /// Đăng xuất
  static Future<void> dangXuat() async {
    await client.auth.signOut();
  }

  // ==========================================
  // TÀI KHOẢN & VÍ NGÂN HÀNG
  // ==========================================

  /// Lấy danh sách ví & tài khoản ngân hàng của người dùng
  static Future<List<TaiKhoanNganHangModel>> layDanhSachTaiKhoan() async {
    final nguoiDung = client.auth.currentUser;
    if (nguoiDung == null) return [];

    final response = await client
        .from('tai_khoan_ngan_hang')
        .select()
        .eq('nguoi_dung_id', nguoiDung.id)
        .order('tao_luc', ascending: false);

    return (response as List)
        .map((e) => TaiKhoanNganHangModel.fromJson(e))
        .toList();
  }

  /// Thêm tài khoản ngân hàng mới
  static Future<TaiKhoanNganHangModel> themTaiKhoan(TaiKhoanNganHangModel model) async {
    final response = await client
        .from('tai_khoan_ngan_hang')
        .insert(model.toJson())
        .select()
        .single();

    return TaiKhoanNganHangModel.fromJson(response);
  }

  // ==========================================
  // DANH MỤC THU CHI
  // ==========================================

  /// Lấy danh sách danh mục (hệ thống + cá nhân)
  static Future<List<DanhMucModel>> layDanhSachDanhMuc() async {
    final nguoiDung = client.auth.currentUser;
    final response = await client
        .from('danh_muc')
        .select()
        .or('nguoi_dung_id.is.null,nguoi_dung_id.eq.${nguoiDung?.id ?? ""}');

    return (response as List).map((e) => DanhMucModel.fromJson(e)).toList();
  }

  // ==========================================
  // GIAO DỊCH THU CHI
  // ==========================================

  /// Lấy danh sách tất cả giao dịch
  static Future<List<GiaoDichModel>> layDanhSachGiaoDich() async {
    final nguoiDung = client.auth.currentUser;
    if (nguoiDung == null) return [];

    final response = await client
        .from('giao_dich')
        .select()
        .eq('nguoi_dung_id', nguoiDung.id)
        .order('ngay_giao_dich', ascending: false);

    return (response as List).map((e) => GiaoDichModel.fromJson(e)).toList();
  }

  /// Thêm giao dịch mới (chi tiêu hoặc thu nhập)
  static Future<GiaoDichModel> themGiaoDich(GiaoDichModel model) async {
    final response = await client
        .from('giao_dich')
        .insert(model.toJson())
        .select()
        .single();

    return GiaoDichModel.fromJson(response);
  }

  // ==========================================
  // QUỸ TIẾT KIỆM & MỤC TIÊU
  // ==========================================

  /// Lấy danh sách quỹ tiết kiệm
  static Future<List<QuyTietKiemModel>> layDanhSachQuy() async {
    final nguoiDung = client.auth.currentUser;
    if (nguoiDung == null) return [];

    final response = await client
        .from('quy_tiet_kiem')
        .select()
        .eq('nguoi_dung_id', nguoiDung.id)
        .order('tao_luc', ascending: false);

    return (response as List).map((e) => QuyTietKiemModel.fromJson(e)).toList();
  }

  /// Tạo khoản tiết kiệm / mục tiêu mới
  static Future<QuyTietKiemModel> taoQuyMoi(QuyTietKiemModel model) async {
    final response = await client
        .from('quy_tiet_kiem')
        .insert(model.toJson())
        .select()
        .single();

    return QuyTietKiemModel.fromJson(response);
  }

  /// Nạp tiền hoặc Rút tiền khỏi quỹ
  static Future<bool> capNhatSoDuQuy({
    required String quyId,
    required double soTienThayDoi, // Dương nếu nạp, Âm nếu rút
    required String loaiThaoTac, // 'nap_tien' hoac 'rut_tien'
    String? lyDo,
    String? taiKhoanId,
  }) async {
    final nguoiDung = client.auth.currentUser;
    if (nguoiDung == null) return false;

    // 1. Lấy thông tin quỹ hiện tại
    final quyData = await client
        .from('quy_tiet_kiem')
        .select()
        .eq('id', quyId)
        .single();

    final quy = QuyTietKiemModel.fromJson(quyData);
    final soDuMoi = quy.soTienHienCo + soTienThayDoi;

    // 2. Cập nhật số dư quỹ
    await client
        .from('quy_tiet_kiem')
        .update({'so_tien_hien_co': soDuMoi})
        .eq('id', quyId);

    // 3. Ghĩ nhật ký lịch sử quỹ
    final lichSu = LichSuQuyModel(
      id: '',
      quyId: quyId,
      nguoiDungId: nguoiDung.id,
      taiKhoanId: taiKhoanId,
      loaiThaoTac: loaiThaoTac,
      soTien: soTienThayDoi.abs(),
      lyDo: lyDo,
      maThamChieu: 'CAPY-${DateTime.now().millisecondsSinceEpoch}',
    );

    await client.from('lich_su_quy').insert({
      'quy_id': lichSu.quyId,
      'nguoi_dung_id': lichSu.nguoiDungId,
      'tai_khoan_id': lichSu.taiKhoanId,
      'loai_thao_tac': lichSu.loaiThaoTac,
      'so_tien': lichSu.soTien,
      'ly_do': lichSu.lyDo,
      'ma_tham_chieu': lichSu.maThamChieu,
    });

    return true;
  }
}
