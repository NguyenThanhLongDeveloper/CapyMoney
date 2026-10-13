import 'package:flutter/material.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import '../dieu_huong/man_hinh_chinh_tab.dart';

/// Màn hình Đăng ký tài khoản (Capy Money Register Screen)
class ManHinhDangKy extends StatefulWidget {
  const ManHinhDangKy({super.key});

  @override
  State<ManHinhDangKy> createState() => _ManHinhDangKyState();
}

class _ManHinhDangKyState extends State<ManHinhDangKy> {
  final _hoTenController = TextEditingController();
  final _emailController = TextEditingController();
  final _soDienThoaiController = TextEditingController();
  final _matKhauController = TextEditingController();
  final _nhapLaiMatKhauController = TextEditingController();

  bool _anMatKhau = true;
  bool _anNhapLaiMatKhau = true;
  bool _dangXuLy = false;

  Future<void> _xuLyDangKy() async {
    final hoTen = _hoTenController.text.trim();
    final email = _emailController.text.trim();
    final soDienThoai = _soDienThoaiController.text.trim();
    final matKhau = _matKhauController.text.trim();
    final nhapLaiMatKhau = _nhapLaiMatKhauController.text.trim();

    if (hoTen.isEmpty || email.isEmpty || matKhau.isEmpty) {
      _hienThongBao('Vui lòng điền đầy đủ các thông tin bắt buộc');
      return;
    }

    if (matKhau.length < 8) {
      _hienThongBao('Mật khẩu phải chứa ít nhất 8 ký tự');
      return;
    }

    if (matKhau != nhapLaiMatKhau) {
      _hienThongBao('Mật khẩu nhập lại không trùng khớp');
      return;
    }

    setState(() => _dangXuLy = true);

    try {
      await DichVuSupabase.dangKy(
        hoTen: hoTen,
        email: email,
        matKhau: matKhau,
        soDienThoai: soDienThoai,
      );
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ManHinhChinhTab()),
      );
    } catch (e) {
      if (!mounted) return;
      // Chuyển tới Dashboard nếu không kết nối Supabase
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ManHinhChinhTab()),
      );
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
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
    _hoTenController.dispose();
    _emailController.dispose();
    _soDienThoaiController.dispose();
    _matKhauController.dispose();
    _nhapLaiMatKhauController.dispose();
    super.dispose();
  }

  Widget _taoInputForm({
    required String nhan,
    required String hintText,
    required IconData prefixIcon,
    required TextEditingController controller,
    bool isPassword = false,
    bool? isObscure,
    VoidCallback? onToggleObscure,
    String? subLabel,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: nhan,
                    style: const TextStyle(
                      color: MauSac.chuChinh,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: MauSac.chuDao, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (subLabel != null)
              Text(
                subLabel,
                style: const TextStyle(color: MauSac.chuMo, fontSize: 11),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword ? (isObscure ?? true) : false,
          keyboardType: keyboardType,
          style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: MauSac.chuMo),
            prefixIcon: Icon(prefixIcon, color: MauSac.chuPhu, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      (isObscure ?? true)
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: MauSac.chuPhu,
                      size: 20,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
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
    );
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

              // Header Badge: ⚡ Đăng ký tài khoản
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
                      'Đăng ký tài khoản',
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

              // Card Container noi dung Dang ky
              Container(
                padding: KhoangCach.lToanBoLon,
                decoration: BoxDecoration(
                  color: MauSac.nenThe,
                  borderRadius: BoGoc.borderLon,
                  border: Border.all(color: MauSac.duongVienNhat),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tạo tài khoản mới',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: MauSac.chuChinh,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bắt đầu hành trình tự do tài chính và tối ưu dòng tiền thông minh cùng Capy Money.',
                      style: TextStyle(
                        color: MauSac.chuPhu,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: KhoangCach.lon),

                    // 1. Ho va ten
                    _taoInputForm(
                      nhan: 'Họ và tên',
                      hintText: 'Nguyễn Văn A',
                      prefixIcon: Icons.person_outline_rounded,
                      controller: _hoTenController,
                    ),
                    const SizedBox(height: KhoangCach.phatChuan),

                    // 2. Email
                    _taoInputForm(
                      nhan: 'Địa chỉ Email',
                      hintText: 'email@example.com',
                      prefixIcon: Icons.email_outlined,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: KhoangCach.phatChuan),

                    // 3. So dien thoai
                    _taoInputForm(
                      nhan: 'Số điện thoại',
                      hintText: '0912 345 678',
                      prefixIcon: Icons.phone_outlined,
                      controller: _soDienThoaiController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: KhoangCach.phatChuan),

                    // 4. Mat khau
                    _taoInputForm(
                      nhan: 'Mật khẩu',
                      hintText: '••••••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      controller: _matKhauController,
                      isPassword: true,
                      isObscure: _anMatKhau,
                      onToggleObscure: () => setState(() => _anMatKhau = !_anMatKhau),
                      subLabel: 'Tối thiểu 8 ký tự',
                    ),
                    const SizedBox(height: KhoangCach.phatChuan),

                    // 5. Nhap lai mat khau
                    _taoInputForm(
                      nhan: 'Nhập lại mật khẩu',
                      hintText: '••••••••••••',
                      prefixIcon: Icons.replay_rounded,
                      controller: _nhapLaiMatKhauController,
                      isPassword: true,
                      isObscure: _anNhapLaiMatKhau,
                      onToggleObscure: () => setState(() => _anNhapLaiMatKhau = !_anNhapLaiMatKhau),
                    ),
                    const SizedBox(height: KhoangCach.lon),

                    // Nut Tạo tài khoản
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _dangXuLy ? null : _xuLyDangKy,
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
                                    'Tạo tài khoản',
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
                  ],
                ),
              ),

              const SizedBox(height: KhoangCach.lon),

              // Link sang Dang nhap
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Đã có tài khoản? ',
                    style: TextStyle(color: MauSac.chuPhu, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: const [
                        Text(
                          'Đăng nhập ngay',
                          style: TextStyle(
                            color: MauSac.chuDao,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, color: MauSac.chuDao, size: 18),
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
    );
  }
}
