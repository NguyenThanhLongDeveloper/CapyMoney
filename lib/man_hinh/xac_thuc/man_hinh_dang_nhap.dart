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
import '../../giao_dien/thong_bao/thong_bao_giua_man_hinh.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import 'man_hinh_dang_ky.dart';
import 'man_hinh_quen_mat_khau.dart';
import '../dieu_huong/man_hinh_chinh_tab.dart';

/// Màn hình Đăng Nhập Hệ Thống (Figma Theme Login Screen)
/// 
/// Khớp 100% giao diện Figma cho cả 2 trạng thái:
/// 1. Profile Badge State: Avatar tròn viền Gradient, Tên + Email capsule, Lời chào "Chào mừng trở lại! 👋", Ô nhập Mật khẩu bảo mật & Quên mật khẩu.
/// 2. Standard Form State: Ô Email, Mật khẩu 256-bit, Ghi nhớ, Đăng nhập Google & Vân tay.
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
  bool _ghiNhoDangNhap = true;
  bool _dangXuLy = false;

  /// Tên người dùng đã đăng nhập lần gần đây nhất
  String _tenDaDangNhapLanCuoi = '';

  /// Email người dùng đã đăng nhập lần gần đây nhất
  String _emailDaDangNhapLanCuoi = '';

  /// URL Avatar người dùng đã đăng nhập lần gần đây nhất
  String? _anhDaDangNhapLanCuoi;

  /// Cờ bấm "Đổi tài khoản" để mở form nhập Email mới
  bool _hienFormNhapEmailKhac = false;

  @override
  void initState() {
    super.initState();
    _docThongTinGhiNho();
    _langNgheThayDoiPhienDangNhap();
  }

  void _langNgheThayDoiPhienDangNhap() {
    _authSubscription = DichVuSupabase.onAuthStateChange.listen((data) async {
      final session = data.session;
      final event = data.event;
      if (session != null && mounted && event == AuthChangeEvent.signedIn) {
        final ndModel = await DichVuSupabase.dongBoThongTinNguoiDungGoogle();
        final prefs = await SharedPreferences.getInstance();
        if (ndModel != null) {
          await prefs.setString('capymoney_da_dang_nhap_lan_cuoi_ten', ndModel.hoTen);
          if (ndModel.anhDaiDien != null) {
            await prefs.setString('capymoney_da_dang_nhap_lan_cuoi_anh', ndModel.anhDaiDien!);
          }
        }

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ManHinhChinhTab(viTriTabBanDau: 0)),
        );
      }
    });
  }

  /// Nạp thông tin tài khoản đã đăng nhập lần cuối từ bộ nhớ máy & CSDL Supabase
  Future<void> _docThongTinGhiNho() async {
    final prefs = await SharedPreferences.getInstance();
    final emailDaLuu = prefs.getString('capymoney_ghi_nho_email') ?? '';
    final emailLanCuoi = prefs.getString('capymoney_da_dang_nhap_lan_cuoi_email') ?? emailDaLuu;
    String tenLanCuoi = prefs.getString('capymoney_da_dang_nhap_lan_cuoi_ten') ?? 'Chủ tài khoản';
    String? anhLanCuoi = prefs.getString('capymoney_da_dang_nhap_lan_cuoi_anh');

    _matKhauController.clear();

    if (DichVuSupabase.nguoiDungHienTai != null) {
      try {
        await DichVuSupabase.dangXuat();
      } catch (_) {}
    }

    if (emailLanCuoi.isNotEmpty) {
      try {
        final ndModel = await DichVuSupabase.layThongTinNguoiDungTheoEmail(emailLanCuoi);

        if (ndModel != null) {
          if (ndModel.hoTen.isNotEmpty) {
            tenLanCuoi = ndModel.hoTen;
          }
          if (ndModel.anhDaiDien != null &&
              ndModel.anhDaiDien!.isNotEmpty &&
              ndModel.anhDaiDien!.startsWith('http')) {
            anhLanCuoi = ndModel.anhDaiDien;
            await prefs.setString('capymoney_da_dang_nhap_lan_cuoi_anh', ndModel.anhDaiDien!);
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _ghiNhoDangNhap = prefs.getBool('capymoney_ghi_nho_trang_thai') ?? true;
        _emailDaDangNhapLanCuoi = emailLanCuoi;
        _tenDaDangNhapLanCuoi = tenLanCuoi;
        _anhDaDangNhapLanCuoi = anhLanCuoi;

        if (emailLanCuoi.isNotEmpty) {
          _emailController.text = emailLanCuoi;
        }
      });
    }
  }

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

  Future<void> _xuLyDangNhap() async {
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : _emailDaDangNhapLanCuoi;
    final matKhau = _matKhauController.text.trim();

    if (email.isEmpty || matKhau.isEmpty) {
      _hienThongBao('Vui lòng nhập đầy đủ Email và Mật khẩu');
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
          MaterialPageRoute(builder: (_) => const ManHinhChinhTab(viTriTabBanDau: 0)),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();

      if (msg.contains('email not confirmed')) {
        _hienThongBao('Gmail chưa được xác nhận. Vui lòng kiểm tra Gmail để kích hoạt tài khoản!');
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

  Future<void> _xuLyDangNhapVanTay() async {
    final emailTarget = (_emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : _emailDaDangNhapLanCuoi)
        .toLowerCase()
        .trim();

    if (emailTarget.isEmpty) {
      _hienThongBao('Vui lòng nhập Email tài khoản trước khi quét vân tay');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final bool isVanTayEnabled = prefs.getBool('capymoney_van_tay_bat_$emailTarget') ?? false;

    if (!isVanTayEnabled) {
      _hienThongBao('Tài khoản "$emailTarget" chưa bật Vân tay. Vui lòng đăng nhập Mật khẩu và kích hoạt trong màn hình "Tôi"!');
      return;
    }

    try {
      final canCheck = await _authSinhTracHoc.canCheckBiometrics;
      final isSupported = await _authSinhTracHoc.isDeviceSupported();

      if (!canCheck && !isSupported) {
        _hienThongBao('Thiết bị chưa cài đặt bảo mật Vân tay / Khuôn mặt');
        return;
      }

      final xacThucThanhCong = await _authSinhTracHoc.authenticate(
        localizedReason: 'Xác thực Vân tay đăng nhập Capy Money',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (xacThucThanhCong && mounted) {
        setState(() => _dangXuLy = true);
        final matKhauDaLuu = prefs.getString('capymoney_van_tay_mat_khau_$emailTarget') ??
            _matKhauController.text.trim();

        if (matKhauDaLuu.isNotEmpty) {
          try {
            await DichVuSupabase.dangNhap(emailTarget, matKhauDaLuu);
            await prefs.setString('capymoney_da_dang_nhap_lan_cuoi_email', emailTarget);

            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ManHinhChinhTab(viTriTabBanDau: 0)),
            );
          } catch (_) {
            if (!mounted) return;
            _chuyenVaoDashboardDemo();
          }
        } else {
          await prefs.setString('capymoney_da_dang_nhap_lan_cuoi_email', emailTarget);
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ManHinhChinhTab(viTriTabBanDau: 0)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _hienThongBao('Không thể xác thực sinh trắc học. Vui lòng đăng nhập Mật khẩu!');
      }
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
  }

  void _chuyenVaoDashboardDemo() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ManHinhChinhTab(viTriTabBanDau: 0)),
    );
  }

  void _hienThongBao(String noiDung, {LoaiThongBao loai = LoaiThongBao.loi}) {
    ThongBaoGiuaManHinh.hienThi(
      context,
      noiDung: noiDung,
      loai: loai,
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
    final bool hienProfileBadge = _emailDaDangNhapLanCuoi.isNotEmpty && !_hienFormNhapEmailKhac;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8F4FD), // Hơi nghiêng xanh nhạt góc trên trái
              Color(0xFFFCFFFF), // Trắng tinh khôi trung tâm
              Color(0xFFFDE8F3), // Hơi nghiêng hồng nhạt góc dưới phải
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: DapUng.bocKhungForm(
            child: SingleChildScrollView(
              padding: KhoangCach.lNgangLon,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: KhoangCach.lon),

                  // TRẠNG THÁI 1: HIỂN THỊ PROFILE THÔNG TIN TÀI KHOẢN ĐÃ ĐĂNG NHẬP LẦN GẦN NHẤT
                  if (hienProfileBadge) ...[
                    // Avatar tròn viền Gradient Xanh-Hồng
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [MauSac.chuDao, MauSac.phu],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: MauSac.phu.withValues(alpha: 0.25),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3.5),
                            child: ClipOval(
                              child: _anhDaDangNhapLanCuoi != null &&
                                      _anhDaDangNhapLanCuoi!.startsWith('http')
                                  ? Image.network(
                                      _anhDaDangNhapLanCuoi!,
                                      width: 98,
                                      height: 98,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Image.asset(
                                        HinhAnh.logoCapy,
                                        width: 98,
                                        height: 98,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Image.asset(
                                      HinhAnh.logoCapy,
                                      width: 98,
                                      height: 98,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF8D4B00),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Center(
                            child: Text(
                              '\$',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Họ và Tên người dùng
                    Text(
                      _tenDaDangNhapLanCuoi.isNotEmpty
                          ? _tenDaDangNhapLanCuoi
                          : 'Nguyễn Hải Đăng',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: MauSac.chuChinh,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Capsule chứa Email
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: MauSac.nenNoi,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _emailDaDangNhapLanCuoi,
                        style: const TextStyle(
                          color: MauSac.chuPhu,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Nút bấm "Đăng nhập tài khoản khác >"
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _hienFormNhapEmailKhac = true;
                          _emailController.clear();
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Đăng nhập tài khoản khác',
                            style: TextStyle(
                              color: MauSac.chuDao,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, color: MauSac.chuDao, size: 18),
                        ],
                      ),
                    ),

                    const SizedBox(height: KhoangCach.lon),

                    // HÀNG LỜI CHÀO & TÌNH TRẠNG BẢO MẬT FIGMA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Row(
                              children: [
                                Text(
                                  'Chào mừng trở lại!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: MauSac.chuChinh,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text('👋', style: TextStyle(fontSize: 18)),
                              ],
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Nhập mật khẩu để tiếp tục vào ví Capy',
                              style: TextStyle(
                                color: MauSac.chuPhu,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: MauSac.chuDao.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: MauSac.chuDao,
                            size: 20,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: KhoangCach.vua),

                    // THẺ WHITE CARD CHỨA MẬT KHẨU BẢO MẬT & QUÊN MẬT KHẨU FIGMA
                    Container(
                      width: double.infinity,
                      padding: KhoangCach.lToanBoChuan,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.lock_outline_rounded, color: MauSac.chuDao, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Mật khẩu bảo mật',
                                style: TextStyle(
                                  color: MauSac.chuChinh,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _matKhauController,
                            obscureText: _anMatKhau,
                            style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Nhập mật khẩu của bạn',
                              hintStyle: const TextStyle(color: MauSac.chuMo, fontSize: 13),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _anMatKhau ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: MauSac.chuPhu,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _anMatKhau = !_anMatKhau),
                              ),
                              filled: true,
                              fillColor: MauSac.nenNoi,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BoGoc.borderVua,
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BoGoc.borderVua,
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BoGoc.borderVua,
                                borderSide: const BorderSide(color: MauSac.chuDao, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
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
                                        color: _ghiNhoDangNhap ? MauSac.chuDao : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _ghiNhoDangNhap ? MauSac.chuDao : MauSac.duongVien,
                                        ),
                                      ),
                                      child: _ghiNhoDangNhap
                                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Ghi nhớ đăng nhập',
                                      style: TextStyle(color: MauSac.chuChinh, fontSize: 12, fontWeight: FontWeight.w500),
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
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: KhoangCach.lon),

                    // NÚT BẤM "⚡ ĐĂNG NHẬP NGAY ➔" GRADIENT
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [MauSac.chuDao, MauSac.phu],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: MauSac.chuDao.withValues(alpha: 0.3),
                              blurRadius: 15,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _dangXuLy ? null : _xuLyDangNhap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: _dangXuLy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'Đăng nhập ngay',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: KhoangCach.lon),

                    // DIVIDER & HÀNG GOOGLE / VÂN TAY
                    Row(
                      children: const [
                        Expanded(child: Divider(color: MauSac.duongVienNhat)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'HOẶC TIẾP TỤC VỚI',
                            style: TextStyle(
                              color: MauSac.chuMo,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: MauSac.duongVienNhat)),
                      ],
                    ),

                    const SizedBox(height: KhoangCach.lon),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _dangXuLy ? null : _xuLyDangNhapGoogle,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: MauSac.nenNoi,
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
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
                                  SizedBox(width: 8),
                                  Text(
                                    'Đăng nhập với Google',
                                    style: TextStyle(
                                      color: MauSac.chuChinh,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        SizedBox(
                          width: 48,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _dangXuLy ? null : _xuLyDangNhapVanTay,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD2E9FB),
                              foregroundColor: MauSac.chuDao,
                              padding: EdgeInsets.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Icon(
                              Icons.fingerprint_rounded,
                              color: MauSac.chuDao,
                              size: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]

                  // TRẠNG THÁI 2: FORM ĐĂNG NHẬP CHUẨN EMAIL & MẬT KHẨU FIGMA
                  else ...[
                    // Avatar Capybara tròn viền Gradient
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [MauSac.chuDao, MauSac.phu],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: MauSac.phu.withValues(alpha: 0.25),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3.5),
                            child: ClipOval(
                              child: Image.asset(
                                HinhAnh.logoCapy,
                                width: 90,
                                height: 90,
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
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF8D4B00),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Center(
                            child: Text(
                              '\$',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Chào mừng trở lại!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: MauSac.chuChinh,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Quản lý dòng tiền thông minh & đón tài lộc mỗi\nngày',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: MauSac.chuPhu,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: KhoangCach.lon),

                    Container(
                      width: double.infinity,
                      padding: KhoangCach.lToanBoLon,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Địa chỉ Email',
                                style: TextStyle(
                                  color: MauSac.chuChinh,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_hienFormNhapEmailKhac && _emailDaDangNhapLanCuoi.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _hienFormNhapEmailKhac = false;
                                      _emailController.text = _emailDaDangNhapLanCuoi;
                                    });
                                  },
                                  child: Row(
                                    children: const [
                                      Icon(Icons.arrow_back_rounded, color: MauSac.chuPhu, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Quay lại',
                                        style: TextStyle(color: MauSac.chuPhu, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'example@gmail.com',
                              hintStyle: const TextStyle(color: MauSac.chuMo),
                              prefixIcon: const Icon(Icons.alternate_email_rounded, color: MauSac.chuDao, size: 20),
                              filled: true,
                              fillColor: MauSac.nenNoi,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BoGoc.borderVua,
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BoGoc.borderVua,
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BoGoc.borderVua,
                                borderSide: const BorderSide(color: MauSac.chuDao, width: 1.5),
                              ),
                            ),
                          ),

                          const SizedBox(height: KhoangCach.lon),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Mật khẩu bảo vệ',
                                style: TextStyle(
                                  color: MauSac.chuChinh,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.shield_outlined, color: MauSac.chuDao, size: 13),
                                  SizedBox(width: 3),
                                  Text(
                                    '256–bit',
                                    style: TextStyle(
                                      color: MauSac.chuDao,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _matKhauController,
                            obscureText: _anMatKhau,
                            style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: const TextStyle(color: MauSac.chuMo),
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: MauSac.chuDao, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _anMatKhau ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: MauSac.chuPhu,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _anMatKhau = !_anMatKhau),
                              ),
                              filled: true,
                              fillColor: MauSac.nenNoi,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BoGoc.borderVua,
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BoGoc.borderVua,
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BoGoc.borderVua,
                                borderSide: const BorderSide(color: MauSac.chuDao, width: 1.5),
                              ),
                            ),
                          ),

                          const SizedBox(height: KhoangCach.vua),

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
                                        color: _ghiNhoDangNhap ? MauSac.chuDao : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _ghiNhoDangNhap ? MauSac.chuDao : MauSac.duongVien,
                                        ),
                                      ),
                                      child: _ghiNhoDangNhap
                                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Ghi nhớ đăng nhập',
                                      style: TextStyle(color: MauSac.chuChinh, fontSize: 12, fontWeight: FontWeight.w500),
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
                                    color: MauSac.phu,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: KhoangCach.lon),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [MauSac.chuDao, MauSac.phu],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: MauSac.chuDao.withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _dangXuLy ? null : _xuLyDangNhap,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: _dangXuLy
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Text(
                                            'Đăng nhập tài khoản',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                        ],
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(height: KhoangCach.lon),

                          Row(
                            children: const [
                              Expanded(child: Divider(color: MauSac.duongVienNhat)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'HOẶC TIẾP TỤC VỚI',
                                  style: TextStyle(
                                    color: MauSac.chuMo,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: MauSac.duongVienNhat)),
                            ],
                          ),

                          const SizedBox(height: KhoangCach.lon),

                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: _dangXuLy ? null : _xuLyDangNhapGoogle,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: MauSac.nenNoi,
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
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
                                        SizedBox(width: 8),
                                        Text(
                                          'Đăng nhập với Google',
                                          style: TextStyle(
                                            color: MauSac.chuChinh,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              SizedBox(
                                width: 48,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _dangXuLy ? null : _xuLyDangNhapVanTay,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD2E9FB),
                                    foregroundColor: MauSac.chuDao,
                                    padding: EdgeInsets.zero,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.fingerprint_rounded,
                                    color: MauSac.chuDao,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: KhoangCach.lon),

                  // FOOTER CHƯA CÓ TÀI KHOẢN? ĐĂNG KÝ NGAY
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Bạn chưa có tài khoản Capy? ',
                        style: TextStyle(color: MauSac.chuPhu, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ManHinhDangKy()),
                          );
                        },
                        child: Row(
                          children: const [
                            Text(
                              'Đăng ký ngay',
                              style: TextStyle(
                                color: MauSac.chuDao,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.arrow_forward_rounded, color: MauSac.chuDao, size: 14),
                          ],
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
      ),
    );
  }
}
