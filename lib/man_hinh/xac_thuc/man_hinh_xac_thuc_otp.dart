import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import 'man_hinh_dang_nhap.dart';

/// Màn hình Nhập Mã Xác Thực OTP & Đặt Mật Khẩu Mới (Capy Money Reset Password)
/// 
/// Nhận 6 ô nhập mã OTP gửi về Gmail, đồng thời cho phép nhập mật khẩu mới và xác thực trực tiếp qua Supabase Auth.
class ManHinhXacThucOtp extends StatefulWidget {
  /// Địa chỉ Gmail nhận mã xác thực OTP
  final String email;

  const ManHinhXacThucOtp({super.key, required this.email});

  @override
  State<ManHinhXacThucOtp> createState() => _ManHinhXacThucOtpState();
}

class _ManHinhXacThucOtpState extends State<ManHinhXacThucOtp> {
  /// Danh sách 6 controller điều khiển 6 ô nhập chữ số mã OTP
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());

  /// Danh sách 6 focus node tự động chuyển ô nhập khi người dùng gõ
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  /// Bộ điều khiển ô nhập Mật khẩu mới
  final _matKhauMoiController = TextEditingController();

  /// Bộ điều khiển ô nhập lại Mật khẩu xác nhận
  final _xacNhanMatKhauController = TextEditingController();

  /// Ẩn/hiện mật khẩu mới
  bool _anMatKhauMoi = true;

  /// Ẩn/hiện mật khẩu xác nhận
  bool _anXacNhanMatKhau = true;

  /// Trạng thái đang gửi yêu cầu xác thực OTP
  bool _dangXuLy = false;

  /// Thời gian đếm ngược 60 giây để cho phép bấm nút "Gửi lại mã OTP"
  int _demNguoc = 60;

  /// Timer đếm ngược hàng giây
  Timer? _boDemTimer;

  @override
  void initState() {
    super.initState();
    _batDauDemNguoc();
  }

  /// Khởi chạy bộ đếm ngược 60 giây gửi lại mã OTP
  void _batDauDemNguoc() {
    setState(() => _demNguoc = 60);
    _boDemTimer?.cancel();
    _boDemTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_demNguoc > 0) {
        setState(() => _demNguoc--);
      } else {
        _boDemTimer?.cancel();
      }
    });
  }

  /// Thao tác yêu cầu Supabase Auth gửi lại mã OTP mới về Gmail
  Future<void> _guiLaiMaOtp() async {
    if (_demNguoc > 0) return;

    try {
      await DichVuSupabase.guiMaKhoiPhuc(widget.email);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gửi lại mã OTP mới về Gmail ${widget.email}'),
          backgroundColor: MauSac.chuDao,
        ),
      );
      _batDauDemNguoc();
    } catch (e) {
      if (mounted) {
        _hienThongBao('Không thể gửi lại mã OTP: $e');
      }
    }
  }

  /// Kiểm tra mật khẩu đạt độ dài an toàn tối thiểu 8 ký tự
  bool get _du8KyTu => _matKhauMoiController.text.length >= 8;

  /// Kiểm tra hai mật khẩu có trùng khớp không
  bool get _trungKhop =>
      _matKhauMoiController.text.isNotEmpty &&
      _matKhauMoiController.text == _xacNhanMatKhauController.text;

  /// Thao tác xác thực mã OTP và cập nhật mật khẩu mới lên Supabase Auth
  Future<void> _xuLyDoiMatKhau() async {
    final maOtp = _otpControllers.map((c) => c.text.trim()).join();
    final matKhauMoi = _matKhauMoiController.text.trim();

    // 1. Validation mã OTP 6 số
    if (maOtp.length < 6) {
      _hienThongBao('Vui lòng nhập đủ 6 chữ số mã OTP');
      return;
    }

    // 2. Validation độ dài mật khẩu mới
    if (!_du8KyTu) {
      _hienThongBao('Mật khẩu mới phải chứa ít nhất 8 ký tự');
      return;
    }

    // 3. Validation trùng khớp mật khẩu
    if (!_trungKhop) {
      _hienThongBao('Mật khẩu xác nhận không trùng khớp');
      return;
    }

    setState(() => _dangXuLy = true);

    try {
      // Gọi Supabase Auth xác thực OTP recovery và cập nhật mật khẩu mới
      await DichVuSupabase.capNhatMatKhauMoi(
        email: widget.email,
        maOtp: maOtp,
        matKhauMoi: matKhauMoi,
      );

      // Xóa thông tin mật khẩu cũ lưu tạm trong SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('capymoney_ghi_nho_mat_khau');
      await prefs.setBool('capymoney_ghi_nho_trang_thai', false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công! Vui lòng đăng nhập bằng mật khẩu mới.'),
          backgroundColor: MauSac.chuDao,
          duration: Duration(seconds: 4),
        ),
      );

      // Điều hướng về Màn hình Đăng nhập
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ManHinhDangNhap()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _hienThongBao('Mã OTP không chính xác hoặc đã hết hạn (${e.message})');
    } catch (e) {
      if (!mounted) return;
      _hienThongBao('Lỗi đổi mật khẩu: $e');
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
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
    _boDemTimer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    _matKhauMoiController.dispose();
    _xacNhanMatKhauController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MauSac.nenChinh,
      appBar: AppBar(
        backgroundColor: MauSac.nenChinh,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: MauSac.chuDao, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quên Mật Khẩu',
          style: TextStyle(
            color: MauSac.chuChinh,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: KhoangCach.lNgangLon,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: KhoangCach.vua),

              // SECTION 1: BIỂU TƯỢNG KHIÊN BẢO MẬT
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: MauSac.nenNoi,
                  shape: BoxShape.circle,
                  border: Border.all(color: MauSac.chuDao.withValues(alpha: 0.3), width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: MauSac.chuDao,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Colors.black,
                      size: 22,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: KhoangCach.vua),

              const Text(
                'Xác thực & Tạo mật khẩu mới',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: MauSac.chuChinh,
                ),
              ),

              const SizedBox(height: 8),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(color: MauSac.chuPhu, fontSize: 13, height: 1.4),
                  children: [
                    const TextSpan(text: 'Mã OTP gồm 6 số đã được gửi đến\n'),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        color: MauSac.chuDao,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: '. Vui lòng nhập mã để hoàn tất cấp lại mật khẩu.'),
                  ],
                ),
              ),

              const SizedBox(height: KhoangCach.lon),

              // SECTION 2: CARD CONTAINER CHỨA Ô NHẬP OTP 6 CHỮ SỐ VÀ Ô MẬT KHẨU MỚI
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
                    // Header MÃ XÁC THỰC
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'MÃ XÁC THỰC (6 CHỮ SỐ)',
                          style: TextStyle(
                            color: MauSac.chuPhu,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '🔄 Đang kích hoạt',
                          style: TextStyle(
                            color: MauSac.chuDao,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 6 Ô Nhập OTP với tự động chuyển focus thông minh
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 44,
                          height: 52,
                          child: TextField(
                            controller: _otpControllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              color: MauSac.chuDao,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: MauSac.nenNoi,
                              contentPadding: EdgeInsets.zero,
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
                                borderSide: const BorderSide(color: MauSac.chuDao, width: 2),
                              ),
                            ),
                            onChanged: (val) {
                              if (val.isNotEmpty && index < 5) {
                                _focusNodes[index + 1].requestFocus();
                              } else if (val.isEmpty && index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                            },
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 12),

                    // Đồng hồ đếm ngược & Nút yêu cầu gửi lại mã OTP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '⏰ Gửi lại mã sau ${_demNguoc}s',
                          style: const TextStyle(color: MauSac.chuMo, fontSize: 12),
                        ),
                        GestureDetector(
                          onTap: _demNguoc == 0 ? _guiLaiMaOtp : null,
                          child: Text(
                            'Gửi lại mã OTP',
                            style: TextStyle(
                              color: _demNguoc == 0 ? MauSac.chuDao : MauSac.chuMo,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              decoration: _demNguoc == 0 ? TextDecoration.underline : TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: KhoangCach.lon),
                    const Divider(color: MauSac.duongVienNhat),
                    const SizedBox(height: KhoangCach.vua),

                    const Center(
                      child: Text(
                        'MẬT KHẨU MỚI',
                        style: TextStyle(
                          color: MauSac.chuMo,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),

                    const SizedBox(height: KhoangCach.vua),

                    // Ô nhập Mật khẩu mới
                    const Text(
                      'Mật khẩu mới',
                      style: TextStyle(color: MauSac.chuChinh, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _matKhauMoiController,
                      obscureText: _anMatKhauMoi,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: '••••••••••••',
                        hintStyle: const TextStyle(color: MauSac.chuMo),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: MauSac.chuPhu, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _anMatKhauMoi ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: MauSac.chuPhu,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _anMatKhauMoi = !_anMatKhauMoi),
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

                    // Ô nhập lại Mật khẩu xác nhận
                    const Text(
                      'Xác nhận mật khẩu',
                      style: TextStyle(color: MauSac.chuChinh, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _xacNhanMatKhauController,
                      obscureText: _anXacNhanMatKhau,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: '••••••••••••',
                        hintStyle: const TextStyle(color: MauSac.chuMo),
                        prefixIcon: const Icon(Icons.verified_user_outlined, color: MauSac.chuPhu, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _anXacNhanMatKhau ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: MauSac.chuPhu,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _anXacNhanMatKhau = !_anXacNhanMatKhau),
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

                    // SECTION 3: BẢNG KIỂM TRA ĐIỀU KIỆN MẬT KHẨU MỚI REALTIME
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
                                'Tối thiểu 8 ký tự an toàn',
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
                                'Hai mật khẩu đã trùng khớp hoàn toàn',
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

                    // SECTION 4: NÚT CTA XÁC NHẬN VÀ ĐỔI MẬT KHẨU
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _dangXuLy ? null : _xuLyDoiMatKhau,
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
                                    'Xác nhận & Đổi mật khẩu',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 18),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KhoangCach.lon),

              // SECTION 5: LINK QUAY VỀ MÀN HÌNH ĐĂNG NHẬP
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const ManHinhDangNhap()),
                    (route) => false,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.logout_rounded, color: MauSac.chuPhu, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Quay về Đăng nhập',
                      style: TextStyle(
                        color: MauSac.chuPhu,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KhoangCach.vua),

              const Text(
                '🛡 Bảo mật 256–bit chuẩn ngân hàng Capy Money',
                style: TextStyle(color: MauSac.chuMo, fontSize: 11),
              ),

              const SizedBox(height: KhoangCach.lon),
            ],
          ),
        ),
      ),
    );
  }
}
