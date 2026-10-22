import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/dap_ung.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import 'man_hinh_dang_nhap.dart';

/// Màn hình Đăng Ký Tài Khoản Mới (Capy Money Register Screen)
/// 
/// Thiết kế chuẩn Kinetic Neo-Fintech Dark Mode khớp 100% UI mockup.
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

  static final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final RegExp _sdtRegex = RegExp(r'^[0-9]{10}$');

  bool get _emailHopLe =>
      _emailController.text.isNotEmpty && _emailRegex.hasMatch(_emailController.text.trim());

  bool get _sdtHopLe =>
      _soDienThoaiController.text.isNotEmpty && _sdtRegex.hasMatch(_soDienThoaiController.text.trim());

  bool get _du8KyTu => _matKhauController.text.length >= 8;

  bool get _trungKhop =>
      _matKhauController.text.isNotEmpty &&
      _matKhauController.text == _nhapLaiMatKhauController.text;

  Future<void> _xuLyDangKy() async {
    final hoTen = _hoTenController.text.trim();
    final email = _emailController.text.trim();
    final soDienThoai = _soDienThoaiController.text.trim();
    final matKhau = _matKhauController.text.trim();

    if (hoTen.isEmpty) {
      _hienThongBao('Vui lòng nhập Họ và tên');
      return;
    }

    if (!_emailHopLe) {
      _hienThongBao('Địa chỉ Email không đúng định dạng (ví dụ: email@gmail.com)');
      return;
    }

    if (!_sdtHopLe) {
      _hienThongBao('Số điện thoại phải gồm đúng 10 chữ số');
      return;
    }

    if (!_du8KyTu) {
      _hienThongBao('Mật khẩu phải chứa ít nhất 8 ký tự');
      return;
    }

    if (!_trungKhop) {
      _hienThongBao('Mật khẩu nhập lại không trùng khớp');
      return;
    }

    setState(() => _dangXuLy = true);

    try {
      final res = await DichVuSupabase.dangKy(
        hoTen: hoTen,
        email: email,
        matKhau: matKhau,
        soDienThoai: soDienThoai,
      );

      if (!mounted) return;

      if (res.user != null &&
          res.user!.identities != null &&
          res.user!.identities!.isEmpty) {
        _hienThongBao('Địa chỉ Email "$email" đã được đăng ký tài khoản. Vui lòng chọn Đăng nhập!');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng ký tài khoản thành công! Vui lòng đăng nhập với Gmail $email'),
          backgroundColor: MauSac.chuDao,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ManHinhDangNhap()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _hienThongBao('Lỗi đăng ký: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      _hienThongBao('Không thể tạo tài khoản: $e');
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
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

  @override
  Widget build(BuildContext context) {
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

                // TOP HEADER: Nút Quay lại góc trái + Badge Đăng ký tài khoản
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.chevron_left_rounded, color: MauSac.chuDao, size: 28),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Quay lại',
                    ),
                    Container(
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
                            'Đăng ký tài khoản',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 28), // Cân bằng khoảng trống với nút quay lại
                  ],
                ),

                const SizedBox(height: KhoangCach.lon),

                // HERO TITLE & SUBTITLE
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
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: MauSac.chuPhu,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),

                // CARD CONTAINER CHỨA CAC Ô NHẬP FORM
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
                      // 1. Họ và tên *
                      Row(
                        children: const [
                          Text('Họ và tên', style: TextStyle(color: MauSac.chuChinh, fontSize: 13, fontWeight: FontWeight.bold)),
                          SizedBox(width: 4),
                          Text('*', style: TextStyle(color: MauSac.chuDao, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _hoTenController,
                        style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Nguyễn Văn A',
                          hintStyle: const TextStyle(color: MauSac.chuMo),
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: MauSac.chuPhu, size: 20),
                          filled: true,
                          fillColor: MauSac.nenNoi,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                          enabledBorder: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                          focusedBorder: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.chuDao)),
                        ),
                      ),

                      const SizedBox(height: KhoangCach.phatChuan),

                      // 2. Địa chỉ Email *
                      Row(
                        children: const [
                          Text('Địa chỉ Email', style: TextStyle(color: MauSac.chuChinh, fontSize: 13, fontWeight: FontWeight.bold)),
                          SizedBox(width: 4),
                          Text('*', style: TextStyle(color: MauSac.chuDao, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'example@gmail.com',
                          hintStyle: const TextStyle(color: MauSac.chuMo),
                          prefixIcon: const Icon(Icons.email_outlined, color: MauSac.chuPhu, size: 20),
                          filled: true,
                          fillColor: MauSac.nenNoi,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                          enabledBorder: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                          focusedBorder: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.chuDao)),
                        ),
                      ),

                      const SizedBox(height: KhoangCach.phatChuan),

                      // 3. Số điện thoại *
                      Row(
                        children: const [
                          Text('Số điện thoại', style: TextStyle(color: MauSac.chuChinh, fontSize: 13, fontWeight: FontWeight.bold)),
                          SizedBox(width: 4),
                          Text('*', style: TextStyle(color: MauSac.chuDao, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _soDienThoaiController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        maxLength: 10,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '09*******78',
                          hintStyle: const TextStyle(color: MauSac.chuMo),
                          prefixIcon: const Icon(Icons.phone_outlined, color: MauSac.chuPhu, size: 20),
                          filled: true,
                          fillColor: MauSac.nenNoi,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                          enabledBorder: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                          focusedBorder: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.chuDao)),
                        ),
                      ),

                      const SizedBox(height: KhoangCach.phatChuan),

                      // 4. Mật khẩu *
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Text('Mật khẩu', style: TextStyle(color: MauSac.chuChinh, fontSize: 13, fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Text('*', style: TextStyle(color: MauSac.chuDao, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Text('Tối thiểu 8 ký tự', style: TextStyle(color: MauSac.chuPhu, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _matKhauController,
                        obscureText: _anMatKhau,
                        onChanged: (_) => setState(() {}),
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
                          fillColor: MauSac.nenNoi,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                          enabledBorder: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                          focusedBorder: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.chuDao)),
                        ),
                      ),

                      const SizedBox(height: KhoangCach.phatChuan),

                      // 5. Nhập lại mật khẩu *
                      Row(
                        children: const [
                          Text('Nhập lại mật khẩu', style: TextStyle(color: MauSac.chuChinh, fontSize: 13, fontWeight: FontWeight.bold)),
                          SizedBox(width: 4),
                          Text('*', style: TextStyle(color: MauSac.chuDao, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nhapLaiMatKhauController,
                        obscureText: _anNhapLaiMatKhau,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '••••••••••••',
                          hintStyle: const TextStyle(color: MauSac.chuMo),
                          prefixIcon: const Icon(Icons.history_rounded, color: MauSac.chuPhu, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _anNhapLaiMatKhau ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: MauSac.chuPhu,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _anNhapLaiMatKhau = !_anNhapLaiMatKhau),
                          ),
                          filled: true,
                          fillColor: MauSac.nenNoi,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                          enabledBorder: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                          focusedBorder: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.chuDao)),
                        ),
                      ),

                      const SizedBox(height: KhoangCach.vua),

                      // KHUNG KIỂM TRA RÀNG BUỘC THỜI GIAN THỰC
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: MauSac.nenNoi,
                          borderRadius: BoGoc.borderVua,
                          border: Border.all(color: MauSac.duongVienNhat),
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
                                Text(
                                  'Địa chỉ email đúng định dạng',
                                  style: TextStyle(
                                    color: _emailHopLe ? MauSac.chuDao : MauSac.chuMo,
                                    fontSize: 12,
                                    fontWeight: _emailHopLe ? FontWeight.bold : FontWeight.normal,
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
                                Text(
                                  'Số điện thoại gồm đúng 10 chữ số',
                                  style: TextStyle(
                                    color: _sdtHopLe ? MauSac.chuDao : MauSac.chuMo,
                                    fontSize: 12,
                                    fontWeight: _sdtHopLe ? FontWeight.bold : FontWeight.normal,
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
                                Text(
                                  'Tối thiểu 8 ký tự an toàn',
                                  style: TextStyle(
                                    color: _du8KyTu ? MauSac.chuDao : MauSac.chuMo,
                                    fontSize: 12,
                                    fontWeight: _du8KyTu ? FontWeight.bold : FontWeight.normal,
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
                                Text(
                                  'Hai mật khẩu đã trùng khớp hoàn toàn',
                                  style: TextStyle(
                                    color: _trungKhop ? MauSac.chuDao : MauSac.chuMo,
                                    fontSize: 12,
                                    fontWeight: _trungKhop ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: KhoangCach.lon),

                      // NÚT CTA TẠO TÀI KHOẢN
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

                // FOOTER: Đã có tài khoản? Đăng nhập ngay >
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
      ),
    );
  }
}
