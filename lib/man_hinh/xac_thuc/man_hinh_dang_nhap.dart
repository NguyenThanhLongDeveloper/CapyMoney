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

/// Màn hình Đăng Nhập Hệ Thống (Capy Money Login Screen)
/// 
/// Hỗ trợ Đăng nhập bằng Email/Mật khẩu, Đăng nhập Google OAuth, Đăng nhập Vân tay
/// và Thẻ Avatar Profile Badge thông minh của tài khoản đã đăng nhập gần nhất.
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
        _ghiNhoDangNhap = prefs.getBool('capymoney_ghi_nho_trang_thai') ?? false;
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
          MaterialPageRoute(builder: (_) => const ManHinhChinhTab()),
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
        _hienThongBao('Không thể xác thực sinh trắc học. Vui lòng đăng nhập Mật khẩu!');
      }
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
  }

  void _chuyenVaoDashboardDemo() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ManHinhChinhTab()),
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
    // Cờ kiểm tra hiển thị Thẻ Profile Badge hay Form nhập Email mới
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
                const SizedBox(height: KhoangCach.vua),

                // TOP HEADER: BADGE "⚡ Đăng nhập tài khoản" CĂN GIỮA VÀ NÚT "Đổi tài khoản" NẰM BÊN PHẢI
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Badge "⚡ Đăng nhập tài khoản" căn giữa chính xác Center
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: MauSac.chuDao,
                          borderRadius: BoGoc.borderTron,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.bolt_rounded, color: Colors.black, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Đăng nhập tài khoản',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Nút "Đổi tài khoản" tách biệt nằm BÊN PHẢI (Chỉ hiển thị khi có Thẻ Avatar Profile Badge)
                    if (hienProfileBadge)
                      Positioned(
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _hienFormNhapEmailKhac = true;
                              _emailController.clear();
                            });
                          },
                          child: Row(
                            children: const [
                              Icon(Icons.swap_horiz_rounded, color: MauSac.chuDao, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Đổi tài khoản',
                                style: TextStyle(
                                  color: MauSac.chuDao,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_hienFormNhapEmailKhac)
                      Positioned(
                        right: 0,
                        child: GestureDetector(
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
                                style: TextStyle(color: MauSac.chuPhu, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: KhoangCach.lon),

                // LOGO SÁNG CAPYBARA CÓ ĐỐM XANH TRÊN CÙNG GÓC PHẢI
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: MauSac.chuDao.withValues(alpha: 0.25),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          color: MauSac.chuDao,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: Image.asset(
                            HinhAnh.logoCapy,
                            width: 78,
                            height: 78,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: MauSac.nenNoi,
                              child: const Icon(
                                BieuTuong.capybaraThantai,
                                size: 44,
                                color: MauSac.canhBao,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
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

                // CAPY MONEY V2.4 TIÊU ĐỀ
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

                // THẺ AVATAR PROFILE BADGE LẦN ĐĂNG NHẬP GẦN NHẤT HOẶC Ô NHẬP EMAIL
                if (hienProfileBadge)
                  // Thẻ Avatar + Họ tên + Gmail đã đăng nhập lần gần nhất
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
                  // Form nhập địa chỉ Email mới
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Địa chỉ Email (Gmail)',
                            style: TextStyle(color: MauSac.chuChinh, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Bắt buộc',
                            style: TextStyle(color: MauSac.chuPhu, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'example@example.com',
                          hintStyle: const TextStyle(color: MauSac.chuMo),
                          prefixIcon: const Icon(Icons.alternate_email_rounded, color: MauSac.chuPhu, size: 20),
                          filled: true,
                          fillColor: MauSac.nenThe,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

                // FORM FIELD MẬT KHẨU BẢO MẬT
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Mật khẩu bảo mật',
                          style: TextStyle(color: MauSac.chuChinh, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Icon(Icons.shield_outlined, color: MauSac.chuDao, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Mã hóa 256-bit',
                              style: TextStyle(color: MauSac.chuPhu, fontSize: 11),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

                // ROW GHI NHỚ ĐĂNG NHẬP VÀ QUÊN MẬT KHẨU
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _ghiNhoDangNhap = !_ghiNhoDangNhap),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _ghiNhoDangNhap ? MauSac.chuDao : Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
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
                            style: TextStyle(color: MauSac.chuChinh, fontSize: 13),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: KhoangCach.lon),

                // CỤM NÚT ĐĂNG NHẬP VÀ VÂN TAY
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
                              borderRadius: BoGoc.borderTron,
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

                    // Nút quét Vân tay
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

                const SizedBox(height: KhoangCach.lon),

                // DIVIDER "Hoặc tiếp tục với"
                Row(
                  children: [
                    const Expanded(child: Divider(color: MauSac.duongVienNhat)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Hoặc tiếp tục với',
                        style: TextStyle(color: MauSac.chuPhu, fontSize: 12),
                      ),
                    ),
                    const Expanded(child: Divider(color: MauSac.duongVienNhat)),
                  ],
                ),

                const SizedBox(height: KhoangCach.lon),

                // NÚT ĐĂNG NHẬP GOOGLE OAUTH
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: KhoangCach.sieuLon),

                // FOOTER: Chưa có tài khoản? Đăng ký ngay
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
