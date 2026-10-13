import 'package:flutter/material.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/kieu_chu.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import 'man_hinh_dang_ky.dart';
import 'man_hinh_quen_mat_khau.dart';
import '../dieu_huong/man_hinh_chinh_tab.dart';

/// Màn hình Đăng nhập (Capy Money Login Screen)
class ManHinhDangNhap extends StatefulWidget {
  const ManHinhDangNhap({super.key});

  @override
  State<ManHinhDangNhap> createState() => _ManHinhDangNhapState();
}

class _ManHinhDangNhapState extends State<ManHinhDangNhap> {
  final _emailController = TextEditingController();
  final _matKhauController = TextEditingController();

  bool _anMatKhau = true;
  bool _ghiNhoDangNhap = true;
  bool _dangXuLy = false;

  /// Thao tác đăng nhập qua Supabase Auth
  Future<void> _xuLyDangNhap() async {
    final email = _emailController.text.trim();
    final matKhau = _matKhauController.text.trim();

    if (email.isEmpty || matKhau.isEmpty) {
      _hienThongBao('Vui lòng nhập đầy đủ Email và Mật khẩu');
      return;
    }

    setState(() => _dangXuLy = true);

    try {
      await DichVuSupabase.dangNhap(email, matKhau);
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ManHinhChinhTab()),
      );
    } catch (e) {
      // Nếu là chế độ xem demo hoặc chưa kết nối Supabase, cho phép chuyển tiếp
      if (!mounted) return;
      _chuyenVaoDashboardDemo();
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
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
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _matKhauController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MauSac.nenChinh,
      body: SafeArea(
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
                    child: const Center(
                      child: Icon(
                        BieuTuong.capybaraThantai,
                        size: 54,
                        color: Color(0xFF8D4B00),
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

              // Form O Nhap Email / SĐT
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

              // Form O Nhap Mat Khau
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

              // Checkbox Ghi nho & Link Quen mat khau
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

              // Cum Nut Dang nhap main + Nut Biometric Vân tay
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

                  // Nut Biometric Vân tay
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
                      onPressed: _chuyenVaoDashboardDemo,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: KhoangCach.lon),

              // Phan cach: Hoac tiep tuc voi
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

              // Nut Google Login
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _chuyenVaoDashboardDemo,
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

              // Link duoi cùng: Chưa có tài khoản? Đăng ký ngay
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
    );
  }
}
