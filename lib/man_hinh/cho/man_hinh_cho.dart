import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/kieu_chu.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../../giao_dien/chuan_thiet_ke/hinh_anh.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import '../xac_thuc/man_hinh_dang_nhap.dart';
import '../dieu_huong/man_hinh_chinh_tab.dart';

/// Màn hình chờ (Splash Screen) khởi động ứng dụng CapyMoney
class ManHinhCho extends StatefulWidget {
  const ManHinhCho({super.key});

  @override
  State<ManHinhCho> createState() => _ManHinhChoState();
}

class _ManHinhChoState extends State<ManHinhCho> with SingleTickerProviderStateMixin {
  double _tienDo = 0.0;
  late Timer _boDemTienDo;

  @override
  void initState() {
    super.initState();
    _batDauTienDoLoading();
  }

  /// Giả lập tiến độ loading 0% -> 100% trong 1.8 giây và chuyển màn hình
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

  /// Chuyển màn hình dựa trên trạng thái Checkbox "Ghi nhớ đăng nhập"
  Future<void> _chuyenManHinh() async {
    final prefs = await SharedPreferences.getInstance();
    final bool trangThaiGhiNho = prefs.getBool('capymoney_ghi_nho_trang_thai') ?? false;
    final nguoiDungHienTai = DichVuSupabase.client.auth.currentUser;

    // Chỉ vào thẳng Màn hình chính nếu người dùng CÓ TICK "Ghi nhớ đăng nhập"
    final Widget manHinhTiepTheo = (trangThaiGhiNho && nguoiDungHienTai != null)
        ? const ManHinhChinhTab()
        : const ManHinhDangNhap();

    if (!mounted) return;

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
    final double phanTramText = (_tienDo * 100).clamp(0, 100).toDouble();

    return Scaffold(
      backgroundColor: MauSac.nenChinh,
      body: SafeArea(
        child: Padding(
          padding: KhoangCach.lNgangLon,
          child: Column(
            children: [
              const SizedBox(height: KhoangCach.phatChuan),

              // Top Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge trai: ● VAULT V2.4
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: MauSac.nenNoi,
                      borderRadius: BoGoc.borderTron,
                      border: Border.all(color: MauSac.duongVienNhat),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.circle, color: MauSac.chuDao, size: 8),
                        SizedBox(width: 6),
                        Text(
                          'VAULT V2.4',
                          style: TextStyle(
                            color: MauSac.phu,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge phai: ✨ AI 4.0
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: MauSac.nenNoi,
                      borderRadius: BoGoc.borderTron,
                      border: Border.all(color: MauSac.duongVienNhat),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.auto_awesome, color: MauSac.phu, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'AI 4.0',
                          style: TextStyle(
                            color: MauSac.phu,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Linh vat Capybara Avatar Card phat sang Neon
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: MauSac.chuDao.withValues(alpha: 0.35),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: MauSac.chuDao,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Image.asset(
                      HinhAnh.logoCapy,
                      width: 132,
                      height: 132,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFFFF4D8),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                BieuTuong.capybaraThantai,
                                size: 80,
                                color: const Color(0xFF8D4B00),
                              ),
                              Positioned(
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: MauSac.canhBao,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    '💰 CAPY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: KhoangCach.lon),

              // Title Capy Money + Sparkle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Capy ',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: MauSac.canhBao,
                            fontFamily: KieuChu.fontMacDinh,
                          ),
                        ),
                        TextSpan(
                          text: 'Money',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: MauSac.chuDao,
                            fontFamily: KieuChu.fontMacDinh,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.auto_awesome_rounded, color: MauSac.canhBao, size: 28),
                ],
              ),

              const SizedBox(height: KhoangCach.nho),

              // Slogan
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Quản lý chi tiêu siêu dễ • Tích lũy thần tài cùng Capy! 🪙',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: MauSac.chuChinh,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const Spacer(),

              // Thanh Loading Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gradient Bar Container
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: MauSac.nenNoi,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Stack(
                      children: [
                        FractionallySizedBox(
                          widthFactor: _tienDo,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [MauSac.phu, MauSac.chuDao],
                              ),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: MauSac.chuDao.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.nho),

                  // Text thong bao San sang don chao ban + 100%
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.lock_rounded, color: MauSac.chuDao, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Sẵn sàng đón chào bạn!',
                            style: TextStyle(
                              color: MauSac.chuPhu,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${phanTramText.toInt()}%',
                        style: const TextStyle(
                          color: MauSac.chuChinh,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: KhoangCach.lon),

              // Footer section
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.verified_user_rounded, color: MauSac.chuDao, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Bảo mật 256–bit chuẩn ngân hàng • Phiên bản 2.4.0',
                        style: TextStyle(
                          color: MauSac.chuMo,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '© 2024 Capy Money Inc. Giữ toàn quyền bảo lưu.',
                    style: TextStyle(
                      color: MauSac.chuMo,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: KhoangCach.phatChuan),
            ],
          ),
        ),
      ),
    );
  }
}
