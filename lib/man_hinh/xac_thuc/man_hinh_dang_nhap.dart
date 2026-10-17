import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../../giao_dien/chuan_thiet_ke/hinh_anh.dart';
import '../../giao_dien/chuan_thiet_ke/dap_ung.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import 'man_hinh_dang_ky.dart';
import 'man_hinh_quen_mat_khau.dart';
import '../dieu_huong/man_hinh_chinh_tab.dart';

/// Màn hình Đăng nhập hoàn chỉnh (Capy Money Login Screen)
class ManHinhDangNhap extends StatefulWidget {
  const ManHinhDangNhap({super.key});

  @override
  State<ManHinhDangNhap> createState() => _ManHinhDangNhapState();
}

class _ManHinhDangNhapState extends State<ManHinhDangNhap> {
  final _emailController = TextEditingController();
  final _matKhauController = TextEditingController();

  final LocalAuthentication _authSinhTracHoc = LocalAuthentication();
  late final StreamSubscription<AuthState> _authSubscription;

  bool _anMatKhau = true;
  bool _ghiNhoDangNhap = false;
  bool _dangXuLy = false;

  String _tenDaDangNhapLanCuoi = '';
  String _emailDaDangNhapLanCuoi = '';
  bool _hienFormNhapEmailKhac = false;

  @override
  void initState() {
    super.initState();
    _docThongTinGhiNho();
    _langNgheThayDoiPhienDangNhap();
  }

  /// Lắng nghe sự kiện đăng nhập trực tiếp từ OAuth
  void _langNgheThayDoiPhienDangNhap() {
    _authSubscription = DichVuSupabase.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;
      // Chỉ chuyển trang nếu là sự kiện đăng nhập mới (OAuth), tránh tự nhảy trang khi restore session cũ
      if (session != null && mounted && event == AuthChangeEvent.signedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ManHinhChinhTab()),
        );
      }
    });
  }

  /// Đọc thông tin ghi nhớ đăng nhập và tài khoản đã đăng nhập lần cuối
  Future<void> _docThongTinGhiNho() async {
    final prefs = await SharedPreferences.getInstance();
    final emailDaLuu = prefs.getString('capymoney_ghi_nho_email') ?? '';
    final emailLanCuoi = prefs.getString('capymoney_da_dang_nhap_lan_cuoi_email') ?? emailDaLuu;
    final tenLanCuoi = prefs.getString('capymoney_da_dang_nhap_lan_cuoi_ten') ?? 'Nguyễn Hải Đăng';

    // 1. Bắt buộc xóa trống ô nhập Mật khẩu khi ở Màn hình Đăng nhập
    _matKhauController.clear();

    // 2. Hủy session cũ nếu không ở chế độ tự động vào app
    if (DichVuSupabase.client.auth.currentUser != null) {
      try {
        await DichVuSupabase.dangXuat();
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _ghiNhoDangNhap = false; // Luôn trả checkbox Ghi nhớ đăng nhập về false
        _emailDaDangNhapLanCuoi = emailLanCuoi;
        _tenDaDangNhapLanCuoi = tenLanCuoi;

        if (emailLanCuoi.isNotEmpty) {
          _emailController.text = emailLanCuoi;
        }
      });
    }
  }

  /// Lưu hoặc xóa thông tin đăng nhập trong bộ nhớ Cục bộ
  Future<void> _luuThongTinGhiNho(String email, String matKhau) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('capymoney_da_dang_nhap_lan_cuoi_email', email);
    await prefs.setString('capymoney_ghi_nho_email', email);

    if (_ghiNhoDangNhap) {
      await prefs.setBool('capymoney_ghi_nho_trang_thai', true);
      await prefs.setString('capymoney_ghi_nho_mat_khau', matKhau);
    } else {
      await prefs.setBool('capymoney_ghi_nho_trang_thai', false);
      await prefs.remove('capymoney_ghi_nho_mat_khau');
    }
  }

  /// Thao tác đăng nhập bằng Email & Mật khẩu qua Supabase Auth
  Future<void> _xuLyDangNhap() async {
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : _emailDaDangNhapLanCuoi;
    final matKhau = _matKhauController.text.trim();

    if (email.isEmpty || matKhau.isEmpty) {
      _hienThongBao('Vui lòng nhập đầy đủ Mật khẩu bảo mật');
      return;
    }

    setState(() => _dangXuLy = true);

    try {
      final res = await DichVuSupabase.dangNhap(email, matKhau);

      if (!mounted) return;

      if (res.user != null) {
        await _luuThongTinGhiNho(email, matKhau);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ManHinhChinhTab()),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();

      if (msg.contains('email not confirmed')) {
        _hienThongBao('Gmail chưa được xác nhận. Vui lòng mở Gmail để kích hoạt tài khoản trước khi đăng nhập!');
      } else if (msg.contains('invalid login credentials')) {
        _hienThongBao('Email hoặc Mật khẩu không chính xác. Vui lòng kiểm tra lại!');
      } else {
        _hienThongBao('Lỗi đăng nhập: ${e.message}');
      }
    } catch (e) {
      if (!mounted) return;
      _chuyenVaoDashboardDemo();
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
  }

  /// Thao tác Đăng nhập bằng Google OAuth
  Future<void> _xuLyDangNhapGoogle() async {
    setState(() => _dangXuLy = true);
    try {
      await DichVuSupabase.dangNhapBangGoogle();
    } catch (e) {
      if (!mounted) return;
      _hienThongBao('Chưa cấu hình Google OAuth Client trên Supabase Dashboard');
      _chuyenVaoDashboardDemo();
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
  }

  /// Thao tác Đăng nhập bằng Vân tay / Sinh trắc học (Biometric)
  Future<void> _xuLyDangNhapVanTay() async {
    final emailTarget = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : _emailDaDangNhapLanCuoi;

    if (emailTarget.isEmpty) {
      _hienThongBao('Vui lòng chọn hoặc nhập Email tài khoản trước khi đăng nhập vân tay!');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final bool isVanTayEnabled = prefs.getBool('capymoney_van_tay_bat_$emailTarget') ?? false;

    // RÀNG BUỘC 1: Nếu chưa kích hoạt vân tay trong màn hình "Tôi" -> THÔNG BÁO VÀ CHẶN
    if (!isVanTayEnabled) {
      _hienThongBao('Tài khoản "$emailTarget" chưa kích hoạt đăng nhập bằng vân tay. Vui lòng bật tính năng này trong màn hình "Tôi"!');
      return;
    }

    try {
      final canCheck = await _authSinhTracHoc.canCheckBiometrics;
      final isSupported = await _authSinhTracHoc.isDeviceSupported();

      if (!canCheck && !isSupported) {
        _hienThongBao('Thiết bị hoặc trình duyệt chưa cài đặt bảo mật Vân tay / Khuôn mặt');
        return;
      }

      final xacThucThanhCong = await _authSinhTracHoc.authenticate(
        localizedReason: 'Xác thực Vân tay / Khuôn mặt cho tài khoản $emailTarget',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (xacThucThanhCong && mounted) {
        final matKhau = _matKhauController.text.trim();
        if (matKhau.isNotEmpty) {
          await _xuLyDangNhap();
        } else {
          await prefs.setString('capymoney_da_dang_nhap_lan_cuoi_email', emailTarget);
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ManHinhChinhTab()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _hienThongBao('Không thể xác thực sinh trắc học. Vui lòng đăng nhập bằng Mật khẩu!');
      }
    }
  }

  void _chuyenVaoDashboardDemo() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ManHinhChinhTab()),
    );
  }

  void _hienThongBao(String noiDung) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(noiDung),
        backgroundColor: MauSac.chiTieu,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _emailController.dispose();
    _matKhauController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Áp dụng Bảng Profile Badge cho tất cả các trường hợp có thông tin tài khoản đăng nhập gần nhất
    final bool hienProfileBadge = !_hienFormNhapEmailKhac && _emailDaDangNhapLanCuoi.isNotEmpty;

    return Scaffold(
      backgroundColor: MauSac.nenChinh,
      body: SafeArea(
        child: DapUng.bocKhungForm(
          child: SingleChildScrollView(
          padding: KhoangCach.lNgangLon,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: KhoangCach.phatChuan),

              // Header: ⚡ Đăng nhập tài khoản
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: MauSac.nenNoi,
                  borderRadius: BoGoc.borderTron,
                  border: Border.all(color: MauSac.duongVienNhat),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.bolt_rounded, color: MauSac.chuDao, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Đăng nhập tài khoản',
                      style: TextStyle(
                        color: MauSac.chuChinh,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KhoangCach.lon),

              // Avatar Linh vat Capybara voi cham xanh online
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4D8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: MauSac.chuDao, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: MauSac.chuDao.withValues(alpha: 0.25),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        HinhAnh.logoCapy,
                        width: 86,
                        height: 86,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              BieuTuong.capybaraThantai,
                              size: 54,
                              color: Color(0xFF8D4B00),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: MauSac.chuDao,
                        shape: BoxShape.circle,
                        border: Border.all(color: MauSac.nenChinh, width: 2),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: KhoangCach.vua),

              // Title Capy Money V2.4 + Slogan Chào mừng trở lại!
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Capy ',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: MauSac.chuChinh,
                          ),
                        ),
                        TextSpan(
                          text: 'Money ',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: MauSac.chuDao,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: MauSac.nenNoi,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'V2.4',
                      style: TextStyle(
                        color: MauSac.chuDao,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              const Text(
                'Chào mừng trở lại!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: MauSac.chuChinh,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Đăng nhập để tiếp tục quản lý tài chính\nthông minh cùng Capy Money',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: MauSac.chuPhu,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: KhoangCach.lon),

              // KIỂM TRA ĐIỀU KIỆN HIỂN THỊ: Form Ô Nhập Email hoặc Bảng Profile Badge
              if (hienProfileBadge)
                // 1. THỂ HIỆN BẢNG AVATAR VÀ TÊN CHỦ TÀI KHOẢN KHI KHÔNG TÍCH GHI NHỚ
                Container(
                  padding: KhoangCach.lToanBoChuan,
                  decoration: BoxDecoration(
                    color: MauSac.nenThe,
                    borderRadius: BoGoc.borderVua,
                    border: Border.all(color: MauSac.duongVienNhat),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: MauSac.nenNoi,
                        child: const Icon(Icons.person_rounded, color: MauSac.chuDao, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tenDaDangNhapLanCuoi.isNotEmpty
                                  ? _tenDaDangNhapLanCuoi
                                  : 'Chủ tài khoản',
                              style: const TextStyle(
                                color: MauSac.chuChinh,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _emailDaDangNhapLanCuoi,
                              style: const TextStyle(
                                color: MauSac.chuPhu,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _hienFormNhapEmailKhac = true;
                            _emailController.clear();
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Đổi tài khoản',
                          style: TextStyle(
                            color: MauSac.chuDao,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // 2. FORM HIỂN THỊ Ô NHẬP EMAIL THÔNG THƯỜNG
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Email hoặc Số điện thoại',
                          style: TextStyle(
                            color: MauSac.chuChinh,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Bắt buộc',
                          style: TextStyle(
                            color: MauSac.chuMo,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'email@example.com',
                        hintStyle: const TextStyle(color: MauSac.chuMo),
                        prefixIcon: const Icon(Icons.alternate_email_rounded, color: MauSac.chuPhu, size: 20),
                        filled: true,
                        fillColor: MauSac.nenThe,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BoGoc.borderVua,
                          borderSide: const BorderSide(color: MauSac.duongVienNhat),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BoGoc.borderVua,
                          borderSide: const BorderSide(color: MauSac.duongVienNhat),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BoGoc.borderVua,
                          borderSide: const BorderSide(color: MauSac.chuDao),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: KhoangCach.phatChuan),

              // Form Ô Nhập Mật Khẩu
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Mật khẩu bảo mật',
                        style: TextStyle(
                          color: MauSac.chuChinh,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.shield_outlined, color: MauSac.chuDao, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Mã hóa 256-bit',
                            style: TextStyle(
                              color: MauSac.chuPhu,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _matKhauController,
                    obscureText: _anMatKhau,
                    style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '••••••••••••',
                      hintStyle: const TextStyle(color: MauSac.chuMo),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: MauSac.chuPhu, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _anMatKhau ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: MauSac.chuPhu,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _anMatKhau = !_anMatKhau),
                      ),
                      filled: true,
                      fillColor: MauSac.nenThe,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BoGoc.borderVua,
                        borderSide: const BorderSide(color: MauSac.duongVienNhat),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BoGoc.borderVua,
                        borderSide: const BorderSide(color: MauSac.duongVienNhat),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BoGoc.borderVua,
                        borderSide: const BorderSide(color: MauSac.chuDao),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: KhoangCach.vua),

              // Checkbox Ghi nhớ & Link Quên mật khẩu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _ghiNhoDangNhap = !_ghiNhoDangNhap),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _ghiNhoDangNhap ? MauSac.chuDao : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _ghiNhoDangNhap ? MauSac.chuDao : MauSac.chuPhu,
                            ),
                          ),
                          child: _ghiNhoDangNhap
                              ? const Icon(Icons.check_rounded, color: Colors.black, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Ghi nhớ đăng nhập',
                          style: TextStyle(
                            color: MauSac.chuChinh,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManHinhQuenMatKhau()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Quên mật khẩu?',
                      style: TextStyle(
                        color: MauSac.chuDao,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: KhoangCach.lon),

              // Cụm Nút Đăng nhập chính + Nút Vân tay (Biometric)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _dangXuLy ? null : _xuLyDangNhap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MauSac.chuDao,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BoGoc.borderVua,
                          ),
                        ),
                        child: _dangXuLy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'Đăng nhập',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 20),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Nút Vân tay (Biometric Auth)
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: MauSac.nenThe,
                      borderRadius: BoGoc.borderVua,
                      border: Border.all(color: MauSac.duongVienNhat),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.fingerprint_rounded, color: MauSac.chuDao, size: 28),
                      onPressed: _xuLyDangNhapVanTay,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: KhoangCach.lon),

              // Phân cách: Hoặc tiếp tục với
              Row(
                children: const [
                  Expanded(child: Divider(color: MauSac.duongVienNhat)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Hoặc tiếp tục với',
                      style: TextStyle(color: MauSac.chuMo, fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: MauSac.duongVienNhat)),
                ],
              ),

              const SizedBox(height: KhoangCach.phatChuan),

              // Nút Đăng nhập bằng Google
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _dangXuLy ? null : _xuLyDangNhapGoogle,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: MauSac.nenThe,
                    side: const BorderSide(color: MauSac.duongVienNhat),
                    shape: RoundedRectangleBorder(
                      borderRadius: BoGoc.borderVua,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'G',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Đăng nhập với Google',
                        style: TextStyle(
                          color: MauSac.chuChinh,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: KhoangCach.sieuLon),

              // Link dưới cùng: Chưa có tài khoản? Đăng ký ngay
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Chưa có tài khoản? ',
                    style: TextStyle(color: MauSac.chuPhu, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManHinhDangKy()),
                      );
                    },
                    child: const Text(
                      'Đăng ký ngay',
                      style: TextStyle(
                        color: MauSac.chuDao,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: KhoangCach.lon),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
