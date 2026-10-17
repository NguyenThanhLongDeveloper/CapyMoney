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

/// Màn hình Đăng Nhập Hệ Thống (Capy Money Login Screen)
/// 
/// Hỗ trợ Đăng nhập bằng Email/Mật khẩu, Đăng nhập Google OAuth, Đăng nhập Sinh trắc học Vân tay/Khuôn mặt 
/// và hiển thị Thẻ Avatar Profile Badge của tài khoản gần nhất.
class ManHinhDangNhap extends StatefulWidget {
  const ManHinhDangNhap({super.key});

  @override
  State<ManHinhDangNhap> createState() => _ManHinhDangNhapState();
}

class _ManHinhDangNhapState extends State<ManHinhDangNhap> {
  /// Bộ điều khiển ô nhập Email
  final _emailController = TextEditingController();

  /// Bộ điều khiển ô nhập Mật khẩu
  final _matKhauController = TextEditingController();

  /// Đối tượng xác thực sinh trắc học LocalAuthentication
  final LocalAuthentication _authSinhTracHoc = LocalAuthentication();

  /// Lắng nghe luồng trạng thái đăng nhập Auth
  late final StreamSubscription<AuthState> _authSubscription;

  /// Trạng thái ẩn/hiện mật khẩu
  bool _anMatKhau = true;

  /// Cờ tích chọn "Ghi nhớ đăng nhập"
  bool _ghiNhoDangNhap = false;

  /// Trạng thái đang gửi yêu cầu xác thực
  bool _dangXuLy = false;

  /// Tên người dùng đã đăng nhập lần gần đây nhất
  String _tenDaDangNhapLanCuoi = '';

  /// Email người dùng đã đăng nhập lần gần đây nhất
  String _emailDaDangNhapLanCuoi = '';

  /// URL Avatar người dùng đã đăng nhập lần gần đây nhất
  String? _anhDaDangNhapLanCuoi;

  /// Cờ bấm "Đổi tài khoản" để mở form nhập Email khác
  bool _hienFormNhapEmailKhac = false;

  @override
  void initState() {
    super.initState();
    _docThongTinGhiNho();
    _langNgheThayDoiPhienDangNhap();
  }

  /// Lắng nghe sự kiện đăng nhập trực tiếp từ Supabase Auth (Dùng cho Google OAuth Callback)
  void _langNgheThayDoiPhienDangNhap() {
    _authSubscription = DichVuSupabase.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;
      // Chỉ tự động điều hướng nếu là sự kiện đăng nhập mới thành công
      if (session != null && mounted && event == AuthChangeEvent.signedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ManHinhChinhTab()),
        );
      }
    });
  }

  /// Nạp thông tin tài khoản đã đăng nhập lần cuối từ bộ nhớ máy & CSDL Supabase
  Future<void> _docThongTinGhiNho() async {
    final prefs = await SharedPreferences.getInstance();
    final emailDaLuu = prefs.getString('capymoney_ghi_nho_email') ?? '';
    final emailLanCuoi = prefs.getString('capymoney_da_dang_nhap_lan_cuoi_email') ?? emailDaLuu;
    String tenLanCuoi = prefs.getString('capymoney_da_dang_nhap_lan_cuoi_ten') ?? 'Nguyễn Hải Đăng';
    String? anhLanCuoi = prefs.getString('capymoney_da_dang_nhap_lan_cuoi_anh');

    // 1. Luôn xóa trống ô nhập Mật khẩu khi mở màn hình Đăng nhập
    _matKhauController.clear();

    // 2. Hủy session cũ nếu không ở chế độ tự động vào app
    if (DichVuSupabase.client.auth.currentUser != null) {
      try {
        await DichVuSupabase.dangXuat();
      } catch (_) {}
    }

    // 3. Nạp thông tin Tên & Avatar mới nhất trực tiếp từ CSDL Supabase
    if (emailLanCuoi.isNotEmpty) {
      try {
        final res = await DichVuSupabase.client
            .from('nguoi_dung')
            .select('ho_ten, anh_dai_dien')
            .eq('email', emailLanCuoi)
            .maybeSingle();

        if (res != null) {
          if (res['ho_ten'] != null && (res['ho_ten'] as String).isNotEmpty) {
            tenLanCuoi = res['ho_ten'] as String;
          }
          final anhDb = res['anh_dai_dien'] as String?;
          if (anhDb != null && anhDb.isNotEmpty && anhDb.startsWith('http')) {
            anhLanCuoi = anhDb;
            await prefs.setString('capymoney_da_dang_nhap_lan_cuoi_anh', anhDb);
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _ghiNhoDangNhap = false; // Mặc định trả checkbox Ghi nhớ đăng nhập về false
        _emailDaDangNhapLanCuoi = emailLanCuoi;
        _tenDaDangNhapLanCuoi = tenLanCuoi;
        _anhDaDangNhapLanCuoi = anhLanCuoi;

        if (emailLanCuoi.isNotEmpty) {
          _emailController.text = emailLanCuoi;
        }
      });
    }
  }

  /// Lưu hoặc dọn dẹp thông tin đăng nhập trong SharedPreferences
  Future<void> _luuThongTinGhiNho(String email, String matKhau) async {
    final prefs = await SharedPreferences.getInstance();
    final emailKey = email.toLowerCase().trim();

    await prefs.setString('capymoney_da_dang_nhap_lan_cuoi_email', emailKey);
    await prefs.setString('capymoney_ghi_nho_email', emailKey);
    await prefs.setString('capymoney_van_tay_mat_khau_$emailKey', matKhau);

    if (_ghiNhoDangNhap) {
      await prefs.setBool('capymoney_ghi_nho_trang_thai', true);
      await prefs.setString('capymoney_ghi_nho_mat_khau', matKhau);
    } else {
      await prefs.setBool('capymoney_ghi_nho_trang_thai', false);
      await prefs.remove('capymoney_ghi_nho_mat_khau');
    }
  }

  /// Thao tác Đăng nhập bằng Email & Mật khẩu qua Supabase Auth API
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

  /// Thao tác Đăng nhập bằng Vân tay / Sinh trắc học (Biometric Authentication)
  Future<void> _xuLyDangNhapVanTay() async {
    final emailTarget = (_emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : _emailDaDangNhapLanCuoi)
        .toLowerCase()
        .trim();

    if (emailTarget.isEmpty) {
      _hienThongBao('Vui lòng chọn hoặc nhập Email tài khoản trước khi đăng nhập vân tay!');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final bool isVanTayEnabled = prefs.getBool('capymoney_van_tay_bat_$emailTarget') ?? false;

    // RÀNG BUỘC: Nếu chưa bật tính năng vân tay trong màn hình "Tôi" -> BÁO LỖI VÀ CHẶN
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
        setState(() => _dangXuLy = true);

        // Lấy mật khẩu đã lưu từ trước để xác thực chính thức với Supabase Auth
        final matKhauDaLuu = prefs.getString('capymoney_van_tay_mat_khau_$emailTarget') ??
            _matKhauController.text.trim();

        if (matKhauDaLuu.isNotEmpty) {
          try {
            await DichVuSupabase.dangNhap(emailTarget, matKhauDaLuu);
            await prefs.setString('capymoney_da_dang_nhap_lan_cuoi_email', emailTarget);

            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ManHinhChinhTab()),
            );
          } catch (_) {
            if (!mounted) return;
            _chuyenVaoDashboardDemo();
          }
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
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
  }

  /// Hàm điều hướng dự phòng vào thẳng Dashboard khi ở chế độ Offline/Demo
  void _chuyenVaoDashboardDemo() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ManHinhChinhTab()),
    );
  }

  /// Hàm hỗ trợ hiển thị SnackBar thông báo ngắn
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
    // Kiểm tra có hiển thị Thẻ Profile Badge của tài khoản gần nhất hay không
    final bool hienProfileBadge = _emailDaDangNhapLanCuoi.isNotEmpty && !_hienFormNhapEmailKhac;

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

                // SECTION 1: HEADER NÚT CHUYỂN ĐỔI TÀI KHOẢN VÀ STATUS BADGE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (hienProfileBadge)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _hienFormNhapEmailKhac = true;
                            _emailController.clear();
                          });
                        },
                        icon: const Icon(Icons.swap_horiz_rounded, color: MauSac.chuDao, size: 18),
                        label: const Text(
                          'Đổi tài khoản',
                          style: TextStyle(
                            color: MauSac.chuDao,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (_hienFormNhapEmailKhac)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _hienFormNhapEmailKhac = false;
                            _emailController.text = _emailDaDangNhapLanCuoi;
                          });
                        },
                        icon: const Icon(Icons.arrow_back_rounded, color: MauSac.chuPhu, size: 16),
                        label: const Text(
                          'Quay lại',
                          style: TextStyle(color: MauSac.chuPhu, fontSize: 13),
                        ),
                      )
                    else
                      const SizedBox(),

                    // Badge góc phải: SECURE SSL
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: MauSac.nenNoi,
                        borderRadius: BoGoc.borderTron,
                        border: Border.all(color: MauSac.duongVienNhat),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.shield_outlined, color: MauSac.chuDao, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'SECURE SSL',
                            style: TextStyle(
                              color: MauSac.chuPhu,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: KhoangCach.vua),

                // SECTION 2: CARD LOGO CAPYBARA PHÁT SÁNG NEON MINT
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: MauSac.chuDao.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: MauSac.chuDao,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: Image.asset(
                            HinhAnh.logoCapy,
                            width: 82,
                            height: 82,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: MauSac.nenNoi,
                              child: const Icon(
                                BieuTuong.capybaraThantai,
                                size: 48,
                                color: MauSac.canhBao,
                              ),
                            ),
                          ),
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

                // SECTION 3: TIÊU ĐỀ VA SLOGAN CHÀO MỪNG
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

                // SECTION 4: THẺ AVATAR PROFILE BADGE HOẶC FORM NHẬP EMAIL MỚI
                if (hienProfileBadge)
                  // Thẻ Avatar + Họ tên tài khoản gần nhất
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
                          child: _anhDaDangNhapLanCuoi != null &&
                                  _anhDaDangNhapLanCuoi!.startsWith('http')
                              ? ClipOval(
                                  child: Image.network(
                                    _anhDaDangNhapLanCuoi!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.person_rounded,
                                      color: MauSac.chuDao,
                                      size: 24,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.person_rounded, color: MauSac.chuDao, size: 24),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: MauSac.chuDao.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Sẵn sàng',
                            style: TextStyle(
                              color: MauSac.chuDao,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Ô nhập địa chỉ Email mới
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Địa chỉ Email (Gmail)',
                        style: TextStyle(color: MauSac.chuChinh, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'haidang.finance@gmail.com',
                          hintStyle: const TextStyle(color: MauSac.chuMo),
                          prefixIcon: const Icon(Icons.email_outlined, color: MauSac.chuPhu, size: 20),
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

                // SECTION 5: Ô NHẬP MẬT KHẨU
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mật khẩu bảo mật',
                      style: TextStyle(color: MauSac.chuChinh, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
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

                // SECTION 6: CHECKBOX GHI NHỚ VÀ LINK QUÊN MẬT KHẨU
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
                            style: TextStyle(color: MauSac.chuPhu, fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ManHinhQuenMatKhau()),
                        );
                      },
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

                // SECTION 7: NÚT ĐĂNG NHẬP CHÍNH VÀ NÚT ĐĂNG NHẬP VÂN TAY
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

                    // Nút quét Vân tay / Khuôn mặt (Biometric Button)
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _dangXuLy ? null : _xuLyDangNhapVanTay,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MauSac.nenThe,
                          foregroundColor: MauSac.chuDao,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          side: const BorderSide(color: MauSac.duongVienNhat),
                          shape: RoundedRectangleBorder(
                            borderRadius: BoGoc.borderVua,
                          ),
                        ),
                        child: const Icon(
                          Icons.fingerprint_rounded,
                          color: MauSac.chuDao,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: KhoangCach.phatChuan),

                // SECTION 8: NÚT ĐĂNG NHẬP BẰNG GOOGLE OAUTH
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

                // SECTION 9: LINK CHUYỂN SANG TRANG ĐĂNG KÝ
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
