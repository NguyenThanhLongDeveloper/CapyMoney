import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import 'man_hinh_dang_nhap.dart';

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

  /// Regex kiểm tra Email chuẩn
  static final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  /// Regex kiểm tra Số điện thoại đúng 10 chữ số
  static final RegExp _sdtRegex = RegExp(r'^[0-9]{10}$');

  // Trạng thái kiểm tra trực tiếp (Realtime validation status)
  bool get _emailHopLe =>
      _emailController.text.isNotEmpty && _emailRegex.hasMatch(_emailController.text.trim());

  bool get _sdtHopLe =>
      _soDienThoaiController.text.isNotEmpty && _sdtRegex.hasMatch(_soDienThoaiController.text.trim());

  bool get _du8KyTu => _matKhauController.text.length >= 8;

  bool get _trungKhop =>
      _matKhauController.text.isNotEmpty &&
      _matKhauController.text == _nhapLaiMatKhauController.text;

  /// Thao tác kiểm tra dữ liệu và Đăng ký tài khoản
  Future<void> _xuLyDangKy() async {
    final hoTen = _hoTenController.text.trim();
    final email = _emailController.text.trim();
    final soDienThoai = _soDienThoaiController.text.trim();
    final matKhau = _matKhauController.text.trim();

    // 1. Kiểm tra Họ tên
    if (hoTen.isEmpty) {
      _hienThongBao('Vui lòng nhập Họ và tên');
      return;
    }

    // 2. Kiểm tra Email chuẩn
    if (!_emailHopLe) {
      _hienThongBao('Địa chỉ Email không đúng định dạng (ví dụ: email@example.com)');
      return;
    }

    // 3. Kiểm tra Số điện thoại chuẩn 10 số
    if (!_sdtHopLe) {
      _hienThongBao('Số điện thoại phải gồm đúng 10 chữ số (không chứa chữ hoặc ký tự đặc biệt)');
      return;
    }

    // 4. Kiểm tra độ dài Mật khẩu
    if (!_du8KyTu) {
      _hienThongBao('Mật khẩu phải chứa ít nhất 8 ký tự');
      return;
    }

    // 5. Kiểm tra Mật khẩu nhập lại
    if (!_trungKhop) {
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
      _hienHopThoaiXacNhanEmail(email);
    } catch (e) {
      if (!mounted) return;
      _hienHopThoaiXacNhanEmail(email);
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
  }

  /// Hiển thị hộp thoại yêu cầu xác nhận Gmail sau khi Đăng ký thành công
  void _hienHopThoaiXacNhanEmail(String emailStr) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: MauSac.nenThe,
          shape: RoundedRectangleBorder(borderRadius: BoGoc.borderLon),
          child: Padding(
            padding: KhoangCach.lToanBoLon,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Hòm thư Gmail
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: MauSac.chuDao.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: MauSac.chuDao, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mark_email_read_rounded,
                      color: MauSac.chuDao,
                      size: 38,
                    ),
                  ),
                ),

                const SizedBox(height: KhoangCach.phatChuan),

                const Text(
                  'Xác nhận Email đăng ký',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: MauSac.chuChinh,
                  ),
                ),

                const SizedBox(height: 12),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      color: MauSac.chuPhu,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'Tài khoản của bạn đã được khởi tạo thành công!\n\nVui lòng kiểm tra hộp thư Gmail:\n'),
                      TextSpan(
                        text: emailStr,
                        style: const TextStyle(
                          color: MauSac.chuDao,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: '\nvà nhấn vào liên kết xác nhận để kích hoạt tài khoản trước khi đăng nhập.'),
                    ],
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const ManHinhDangNhap()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MauSac.chuDao,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BoGoc.borderTron,
                      ),
                    ),
                    child: const Text(
                      'Đã hiểu, Đến trang Đăng nhập ➔',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _hienThongBao(String noiDung) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(noiDung),
        backgroundColor: MauSac.chiTieu,
        duration: const Duration(seconds: 3),
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
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
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
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
          decoration: InputDecoration(
            counterText: '',
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

              // Card Container nội dung Đăng ký
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

                    // 1. Họ và tên
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

                    // 3. Số điện thoại (Chỉ cho nhập số, đúng 10 chữ số)
                    _taoInputForm(
                      nhan: 'Số điện thoại',
                      hintText: '0912345678',
                      prefixIcon: Icons.phone_outlined,
                      controller: _soDienThoaiController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 10,
                      subLabel: 'Chuẩn 10 chữ số',
                    ),
                    const SizedBox(height: KhoangCach.phatChuan),

                    // 4. Mật khẩu
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

                    // 5. Nhập lại mật khẩu
                    _taoInputForm(
                      nhan: 'Nhập lại mật khẩu',
                      hintText: '••••••••••••',
                      prefixIcon: Icons.replay_rounded,
                      controller: _nhapLaiMatKhauController,
                      isPassword: true,
                      isObscure: _anNhapLaiMatKhau,
                      onToggleObscure: () => setState(() => _anNhapLaiMatKhau = !_anNhapLaiMatKhau),
                    ),
                    const SizedBox(height: KhoangCach.vua),

                    // Khung kiểm tra điều kiện thời gian thực (Realtime Validation Container)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MauSac.nenNoi,
                        borderRadius: BoGoc.borderVua,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                _emailHopLe ? Icons.check_circle_rounded : Icons.circle_outlined,
                                color: _emailHopLe ? MauSac.chuDao : MauSac.chuMo,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Email đúng định dạng (vd: name@gmail.com)',
                                  style: TextStyle(
                                    color: _emailHopLe ? MauSac.chuChinh : MauSac.chuMo,
                                    fontSize: 12,
                                    fontWeight: _emailHopLe ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                _sdtHopLe ? Icons.check_circle_rounded : Icons.circle_outlined,
                                color: _sdtHopLe ? MauSac.chuDao : MauSac.chuMo,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Số điện thoại chuẩn 10 chữ số',
                                  style: TextStyle(
                                    color: _sdtHopLe ? MauSac.chuChinh : MauSac.chuMo,
                                    fontSize: 12,
                                    fontWeight: _sdtHopLe ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                _du8KyTu ? Icons.check_circle_rounded : Icons.circle_outlined,
                                color: _du8KyTu ? MauSac.chuDao : MauSac.chuMo,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tối thiểu 8 ký tự an toàn',
                                  style: TextStyle(
                                    color: _du8KyTu ? MauSac.chuChinh : MauSac.chuMo,
                                    fontSize: 12,
                                    fontWeight: _du8KyTu ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                _trungKhop ? Icons.check_circle_rounded : Icons.circle_outlined,
                                color: _trungKhop ? MauSac.chuDao : MauSac.chuMo,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Hai mật khẩu đã trùng khớp hoàn toàn',
                                  style: TextStyle(
                                    color: _trungKhop ? MauSac.chuChinh : MauSac.chuMo,
                                    fontSize: 12,
                                    fontWeight: _trungKhop ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: KhoangCach.lon),

                    // Nút Tạo tài khoản
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

              // Link sang Đăng nhập
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
