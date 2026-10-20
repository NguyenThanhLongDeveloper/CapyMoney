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
/// Cung cấp Form nhập thông tin cá nhân, ràng buộc Email/SĐT chuẩn, độ dài mật khẩu 
/// và khởi tạo người dùng trong Supabase Auth & bảng `nguoi_dung`.
class ManHinhDangKy extends StatefulWidget {
  const ManHinhDangKy({super.key});

  @override
  State<ManHinhDangKy> createState() => _ManHinhDangKyState();
}

class _ManHinhDangKyState extends State<ManHinhDangKy> {
  /// Bộ điều khiển ô nhập Họ và tên
  final _hoTenController = TextEditingController();

  /// Bộ điều khiển ô nhập Email
  final _emailController = TextEditingController();

  /// Bộ điều khiển ô nhập Số điện thoại
  final _soDienThoaiController = TextEditingController();

  /// Bộ điều khiển ô nhập Mật khẩu
  final _matKhauController = TextEditingController();

  /// Bộ điều khiển ô nhập lại Mật khẩu xác nhận
  final _nhapLaiMatKhauController = TextEditingController();

  /// Biến ẩn/hiện mật khẩu chính
  bool _anMatKhau = true;

  /// Biến ẩn/hiện mật khẩu xác nhận
  bool _anNhapLaiMatKhau = true;

  /// Biến trạng thái đang gửi request đăng ký
  bool _dangXuLy = false;

  /// Biểu thức chính quy (Regex) kiểm tra Email chuẩn quốc tế
  static final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  /// Biểu thức chính quy (Regex) kiểm tra Số điện thoại đúng 10 chữ số Việt Nam
  static final RegExp _sdtRegex = RegExp(r'^[0-9]{10}$');

  // ==========================================
  // GETTERS KIỂM TRA TRẠNG THÁI RÀNG BUỘC REALTIME
  // ==========================================

  /// Kiểm tra Email nhập vào có khớp định dạng không
  bool get _emailHopLe =>
      _emailController.text.isNotEmpty && _emailRegex.hasMatch(_emailController.text.trim());

  /// Kiểm tra Số điện thoại có đủ 10 chữ số không
  bool get _sdtHopLe =>
      _soDienThoaiController.text.isNotEmpty && _sdtRegex.hasMatch(_soDienThoaiController.text.trim());

  /// Kiểm tra Mật khẩu đạt độ dài an toàn tối thiểu 8 ký tự
  bool get _du8KyTu => _matKhauController.text.length >= 8;

  /// Kiểm tra hai mật khẩu nhập vào có trùng khớp hoàn toàn không
  bool get _trungKhop =>
      _matKhauController.text.isNotEmpty &&
      _matKhauController.text == _nhapLaiMatKhauController.text;

  /// Thao tác kiểm tra toàn bộ điều kiện và đăng ký tài khoản qua Supabase Auth
  Future<void> _xuLyDangKy() async {
    final hoTen = _hoTenController.text.trim();
    final email = _emailController.text.trim();
    final soDienThoai = _soDienThoaiController.text.trim();
    final matKhau = _matKhauController.text.trim();

    // 1. Validation Họ tên
    if (hoTen.isEmpty) {
      _hienThongBao('Vui lòng nhập Họ và tên');
      return;
    }

    // 2. Validation Email
    if (!_emailHopLe) {
      _hienThongBao('Địa chỉ Email không đúng định dạng (ví dụ: email@example.com)');
      return;
    }

    // 3. Validation Số điện thoại
    if (!_sdtHopLe) {
      _hienThongBao('Số điện thoại phải gồm đúng 10 chữ số (không chứa chữ hoặc ký tự đặc biệt)');
      return;
    }

    // 4. Validation Độ dài Mật khẩu
    if (!_du8KyTu) {
      _hienThongBao('Mật khẩu phải chứa ít nhất 8 ký tự');
      return;
    }

    // 5. Validation Trùng khớp Mật khẩu
    if (!_trungKhop) {
      _hienThongBao('Mật khẩu nhập lại không trùng khớp');
      return;
    }

    setState(() => _dangXuLy = true);

    try {
      // Thực hiện đăng ký tài khoản mới trên Supabase Auth
      final res = await DichVuSupabase.dangKy(
        hoTen: hoTen,
        email: email,
        matKhau: matKhau,
        soDienThoai: soDienThoai,
      );

      if (!mounted) return;

      // Xử lý trường hợp Email đã được sử dụng từ trước
      if (res.user != null &&
          res.user!.identities != null &&
          res.user!.identities!.isEmpty) {
        _hienThongBao('Địa chỉ Email "$email" đã được đăng ký tài khoản. Vui lòng chọn Đăng nhập!');
        return;
      }

      // Thông báo thành công và chuyển về Màn hình Đăng nhập
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

  /// Hàm hỗ trợ hiển thị SnackBar thông báo ngắn cho người dùng
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: KhoangCach.phatChuan),

                // SECTION 1: HEADER NÚT QUAY LẠI VÀ TIÊU ĐỀ MÀN HÌNH
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, color: MauSac.chuDao, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Tạo Tài Khoản Mới',
                      style: TextStyle(
                        color: MauSac.chuChinh,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                const Padding(
                  padding: EdgeInsets.only(left: 48),
                  child: Text(
                    'Tham gia Capy Money để quản lý tài chính thông minh',
                    style: TextStyle(color: MauSac.chuPhu, fontSize: 13),
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),

                // SECTION 2: CARD CONTAINER CHỨA FORM NHẬP THÔNG TIN
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
                      // 1. Ô nhập Họ và tên
                      const Text(
                        'Họ và tên người dùng',
                        style: TextStyle(color: MauSac.chuChinh, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _hoTenController,
                        style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Nguễn Văn A',
                          hintStyle: const TextStyle(color: MauSac.chuMo),
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: MauSac.chuPhu, size: 20),
                          filled: true,
                          fillColor: MauSac.nenNoi,
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

                      const SizedBox(height: KhoangCach.phatChuan),

                      // 2. Ô nhập Địa chỉ Email
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Địa chỉ Email (Gmail)',
                            style: TextStyle(color: MauSac.chuChinh, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          if (_emailController.text.isNotEmpty)
                            Icon(
                              _emailHopLe ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: _emailHopLe ? MauSac.chuDao : MauSac.chiTieu,
                              size: 16,
                            ),
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

                      const SizedBox(height: KhoangCach.phatChuan),

                      // 3. Ô nhập Số điện thoại
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Số điện thoại (10 chữ số)',
                            style: TextStyle(color: MauSac.chuChinh, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          if (_soDienThoaiController.text.isNotEmpty)
                            Icon(
                              _sdtHopLe ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: _sdtHopLe ? MauSac.chuDao : MauSac.chiTieu,
                              size: 16,
                            ),
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
                          hintText: '09********',
                          hintStyle: const TextStyle(color: MauSac.chuMo),
                          prefixIcon: const Icon(Icons.phone_outlined, color: MauSac.chuPhu, size: 20),
                          filled: true,
                          fillColor: MauSac.nenNoi,
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

                      const SizedBox(height: KhoangCach.phatChuan),

                      // 4. Ô nhập Mật khẩu
                      const Text(
                        'Mật khẩu bảo mật',
                        style: TextStyle(color: MauSac.chuChinh, fontSize: 13, fontWeight: FontWeight.w600),
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

                      const SizedBox(height: KhoangCach.phatChuan),

                      // 5. Ô nhập lại Mật khẩu xác nhận
                      const Text(
                        'Xác nhận lại mật khẩu',
                        style: TextStyle(color: MauSac.chuChinh, fontSize: 13, fontWeight: FontWeight.w600),
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
                          prefixIcon: const Icon(Icons.verified_user_outlined, color: MauSac.chuPhu, size: 20),
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

                      const SizedBox(height: KhoangCach.vua),

                      // SECTION 3: KHUNG KIỂM TRA ĐIỀU KIỆN MẬT KHẨU THỜI GIAN THỰC (REALTIME INDICATORS)
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
                                  _du8KyTu ? Icons.check_circle_rounded : Icons.circle_outlined,
                                  color: _du8KyTu ? MauSac.chuDao : MauSac.chuMo,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Mật khẩu chứa ít nhất 8 ký tự',
                                  style: TextStyle(
                                    color: _du8KyTu ? MauSac.chuChinh : MauSac.chuMo,
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
                                  'Hai mật khẩu nhập vào trùng khớp',
                                  style: TextStyle(
                                    color: _trungKhop ? MauSac.chuChinh : MauSac.chuMo,
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

                      // SECTION 4: NÚT ĐĂNG KÝ TÀI KHOẢN CTA
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

                // SECTION 5: LINK CHUYỂN SANG ĐĂNG NHẬP
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
