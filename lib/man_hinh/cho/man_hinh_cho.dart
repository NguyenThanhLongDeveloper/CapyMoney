import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/kieu_chu.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../../giao_dien/chuan_thiet_ke/hinh_anh.dart';
import '../../giao_dien/chuan_thiet_ke/dap_ung.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import '../xac_thuc/man_hinh_dang_nhap.dart';
import '../dieu_huong/man_hinh_chinh_tab.dart';

/// Màn hình Chờ Khởi Động Ứng Dụng (Splash Screen)
/// 
/// Hiển thị linh vật Capybara phát sáng Neon, hiệu ứng nạp tiến độ (Progress Bar) 
/// và tự động kiểm tra phiên làm việc để điều hướng người dùng vào Màn hình chính hoặc Đăng nhập.
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
    // Quy đổi tiến độ ra số nguyên phần trăm (0% -> 100%)
    final double phanTramText = (_tienDo * 100).clamp(0, 100).toDouble();

    return Scaffold(
      backgroundColor: MauSac.nenChinh,
      body: SafeArea(
        child: DapUng.bocKhungForm(
          child: Padding(
            padding: KhoangCach.lNgangLon,
            child: Column(
              children: [
                const SizedBox(height: KhoangCach.phatChuan),

                // SECTION 1: HÀNG BADGES THÔNG TIN ĐỈNH TRANG
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge trái: Phiên bản ứng dụng VAULT V2.4
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

                    // Badge phải: Công nghệ trợ lý tài chính ✨ AI 4.0
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

                // SECTION 2: CARD AVATAR LINH VẬT CAPYBARA PHÁT SÁNG NEON MINT
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

                // SECTION 3: TIÊU ĐỀ THƯƠNG HIỆU CAPY MONEY
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

                // Slogan định vị ứng dụng
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

                // SECTION 4: THANH TIẾN ĐỘ LOADING GRADIENT (PROGRESS BAR)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

                    // Nhãn thông báo trạng thái và chỉ số phần trăm
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

                // SECTION 5: FOOTER THÔNG TIN BẢO MẬT & BẢO QUYỀN
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
      ),
    );
  }
}
