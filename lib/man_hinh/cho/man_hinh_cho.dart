import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../../giao_dien/chuan_thiet_ke/hinh_anh.dart';
import '../../giao_dien/chuan_thiet_ke/dap_ung.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import '../xac_thuc/man_hinh_dang_nhap.dart';
import '../dieu_huong/man_hinh_chinh_tab.dart';

/// Màn hình Chờ Khởi Động Ứng Dụng (Figma Theme Splash Screen)
/// 
/// Khớp 100% giao diện Figma:
/// Avatar Capybara viền Gradient + Coin Badge, Slogan "Quản lý dòng tiền thông minh & Đón tài lộc mỗi ngày",
/// 2 Thẻ Capsule trắng "Ghi chép tức thì" & "Tích lũy thông minh", Thanh tiến độ Gradient và Chú thích bảo mật.
class ManHinhCho extends StatefulWidget {
  const ManHinhCho({super.key});

  @override
  State<ManHinhCho> createState() => _ManHinhChoState();
}

class _ManHinhChoState extends State<ManHinhCho> with SingleTickerProviderStateMixin {
  /// Biến giá trị tiến độ nạp ứng dụng (từ 0.0 đến 1.0)
  double _tienDo = 0.0;

  /// Bộ đếm thời gian cập nhật phần trăm loading
  late Timer _boDemTienDo;

  @override
  void initState() {
    super.initState();
    _batDauTienDoLoading();
  }

  /// Khởi chạy bộ đếm thời gian giả lập tiến độ loading mượt mà từ 0% đến 100% trong 1.5 giây
  void _batDauTienDoLoading() {
    _boDemTienDo = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) return;
      setState(() {
        if (_tienDo < 1.0) {
          _tienDo += 0.02;
        } else {
          _tienDo = 1.0;
          _boDemTienDo.cancel();
          _chuyenManHinh();
        }
      });
    });
  }

  /// Kiểm tra trạng thái "Ghi nhớ đăng nhập" và Session người dùng để chuyển tiếp màn hình thích hợp
  Future<void> _chuyenManHinh() async {
    final prefs = await SharedPreferences.getInstance();
    // Đọc cờ lưu trạng thái ghi nhớ từ bộ nhớ máy
    final bool trangThaiGhiNho = prefs.getBool('capymoney_ghi_nho_trang_thai') ?? false;
    final nguoiDungHienTai = DichVuSupabase.nguoiDungHienTai;

    // Ràng buộc bảo mật: Chỉ cho phép tự động vào thẳng Dashboard nếu người dùng CÓ TICK "Ghi nhớ đăng nhập"
    final Widget manHinhTiepTheo = (trangThaiGhiNho && nguoiDungHienTai != null)
        ? const ManHinhChinhTab()
        : const ManHinhDangNhap();

    if (!mounted) return;

    // Chuyển màn hình kèm hiệu ứng làm mờ Fade Transition
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => manHinhTiepTheo,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _boDemTienDo.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        child: Stack(
          children: [
            // CÁC NGÔI SAO LẤP LÁNH TRANG TRÍ (SPARKLES)
            const Positioned(
              top: 80,
              left: 30,
              child: Icon(Icons.auto_awesome_rounded, color: MauSac.chuDao, size: 28),
            ),
            const Positioned(
              top: 140,
              right: 30,
              child: Icon(Icons.auto_awesome_rounded, color: MauSac.phu, size: 24),
            ),
            const Positioned(
              bottom: 220,
              right: 25,
              child: Icon(Icons.auto_awesome_rounded, color: MauSac.phu, size: 20),
            ),

            SafeArea(
              child: DapUng.bocKhungForm(
                child: Padding(
                  padding: KhoangCach.lNgangLon,
                  child: Column(
                    children: [
                      const Spacer(),

                      // SECTION 1: AVATAR LINH VẬT CAPYBARA VIỀN GRADIENT & BADGE ĐỒNG XU
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 136,
                            height: 136,
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
                                  blurRadius: 25,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: ClipOval(
                                child: Image.asset(
                                  HinhAnh.logoCapy,
                                  width: 128,
                                  height: 128,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: const Color(0xFFFFF4D8),
                                      child: const Center(
                                        child: Icon(
                                          BieuTuong.capybaraThantai,
                                          size: 70,
                                          color: Color(0xFF8D4B00),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          // Badge Đồng xu vàng góc dưới phải Avatar
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF8D4B00),
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '\$',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: KhoangCach.lon),

                      // SECTION 2: TIÊU ĐỀ THƯƠNG HIỆU CAPY MONEY & MAGENTA SPARKLE BADGE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Capy',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: MauSac.chuChinh,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Money',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: MauSac.chuDao,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: MauSac.phu.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: MauSac.phu,
                              size: 16,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Slogan định vị thương hiệu từ Figma
                      const Text(
                        'Quản lý dòng tiền thông minh & Đón tài lộc\nmỗi ngày',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: MauSac.chuPhu,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: KhoangCach.lon),

                      // SECTION 3: HÀNG 2 THẺ CAPSULE TRẮNG
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Capsule 1: Ghi chép tức thì
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.bolt_rounded, color: MauSac.chuDao, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Ghi chép tức thì',
                                  style: TextStyle(
                                    color: MauSac.chuChinh,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Capsule 2: Tích lũy thông minh
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.track_changes_rounded, color: MauSac.phu, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Tích lũy thông minh',
                                  style: TextStyle(
                                    color: MauSac.chuChinh,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // SECTION 4: THANH TIẾN ĐỘ LOADING GRADIENT & DÒNG TRẠNG THÁI
                      Column(
                        children: [
                          Container(
                            height: 6,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: MauSac.duongVienNhat,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _tienDo,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [MauSac.chuDao, MauSac.phu],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.sync_rounded, color: MauSac.chuDao, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Đang khởi tạo bảo mật ví điện tử...',
                                style: TextStyle(
                                  color: MauSac.chuPhu,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: KhoangCach.sieuLon),

                      // SECTION 5: FOOTER CHÚ THÍCH BẢO MẬT & BẢO QUYỀN FIGMA
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.verified_user_rounded, color: MauSac.chuDao, size: 16),
                              const SizedBox(width: 6),
                              RichText(
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Bảo mật chuẩn ngân hàng số bởi ',
                                      style: TextStyle(
                                        color: MauSac.chuChinh,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Capy Security',
                                      style: TextStyle(
                                        color: MauSac.chuChinh,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'v2.4.0 (Build 412) • Powered by Capy FinTech',
                            style: TextStyle(
                              color: MauSac.chuMo,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: KhoangCach.phatChuan),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
