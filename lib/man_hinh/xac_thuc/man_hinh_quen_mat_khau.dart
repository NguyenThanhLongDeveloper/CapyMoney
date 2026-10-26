import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../../giao_dien/chuan_thiet_ke/dap_ung.dart';
import '../../giao_dien/thong_bao/thong_bao_giua_man_hinh.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import 'man_hinh_xac_thuc_otp.dart';

/// Màn hình Yêu Cầu Khôi Phục Mật Khẩu Qua Gmail (Capy Money Forgot Password Screen)
/// 
/// Thiết kế chuẩn Kinetic Neo-Fintech Dark Mode khớp 100% UI mockup.
class ManHinhQuenMatKhau extends StatefulWidget {
  const ManHinhQuenMatKhau({super.key});

  @override
  State<ManHinhQuenMatKhau> createState() => _ManHinhQuenMatKhauState();
}

class _ManHinhQuenMatKhauState extends State<ManHinhQuenMatKhau> {
  final _emailController = TextEditingController();
  bool _dangXuLy = false;

  static final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  Future<void> _guiMaOtp() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _hienThongBao('Vui lòng nhập địa chỉ Gmail khôi phục');
      return;
    }

    if (!_emailRegex.hasMatch(email)) {
      _hienThongBao('Địa chỉ Gmail không đúng định dạng (ví dụ: email@gmail.com)');
      return;
    }

    setState(() => _dangXuLy = true);

    try {
      await DichVuSupabase.guiMaKhoiPhuc(email);

      if (!mounted) return;

      ThongBaoGiuaManHinh.hienThi(
        context,
        noiDung: 'Mã OTP khôi phục đã được gửi về Gmail $email!',
        loai: LoaiThongBao.thanhCong,
      );

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManHinhXacThucOtp(email: email),
            ),
          );
        }
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      if (msg.contains('user not found') || msg.contains('not found') || msg.contains('invalid')) {
        _hienThongBao('Địa chỉ Gmail "$email" chưa được đăng ký trong hệ thống!');
      } else {
        _hienThongBao('Lỗi gửi mã khôi phục: ${e.message}');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ManHinhXacThucOtp(email: email),
        ),
      );
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
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
    _emailController.dispose();
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
          icon: const Icon(BieuTuong.muiTenTrai, color: MauSac.chuDao, size: 28),
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
        child: DapUng.bocKhungForm(
          child: SingleChildScrollView(
            padding: KhoangCach.lNgangLon,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: KhoangCach.lon),

                // BIỂU TƯỢNG VÒNG TRÒN KHÔI PHỤC PHÁT SÁNG CÓ ĐỐM XANH
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: MauSac.nenNoi,
                        shape: BoxShape.circle,
                        border: Border.all(color: MauSac.duongVienNhat, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: MauSac.chuDao.withValues(alpha: 0.15),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: MauSac.nenThe,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            BieuTuong.emailKhoiPhuc,
                            color: MauSac.chuDao,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
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

                const SizedBox(height: KhoangCach.lon),

                const Text(
                  'Khôi phục mật khẩu',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: MauSac.chuChinh,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Nhập địa chỉ Gmail liên kết với tài khoản Capy Money của bạn. Chúng tôi sẽ gửi mã xác thực gồm 6 chữ số để đặt lại mật khẩu mới.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: MauSac.chuPhu,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: KhoangCach.sieuLon),

                // FORM NHẬP GMAIL XÁC THỰC
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Row(
                          children: [
                            Icon(BieuTuong.emailA, color: MauSac.chuDao, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'ĐỊA CHỈ GMAIL XÁC THỰC',
                              style: TextStyle(
                                color: MauSac.chuPhu,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '● Bảo mật SSL',
                          style: TextStyle(
                            color: MauSac.chuDao,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'example@gmail.com',
                        hintStyle: const TextStyle(color: MauSac.chuMo),
                        prefixIcon: const Icon(BieuTuong.email, color: MauSac.chuPhu, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(BieuTuong.dongX, color: MauSac.chuPhu, size: 18),
                          onPressed: () => _emailController.clear(),
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

                // LƯU Ý MÃ OTP HIỆU LỰC
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(BieuTuong.dongHoDay, color: MauSac.canhBao, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(color: MauSac.chuPhu, fontSize: 12, height: 1.4),
                          children: [
                            TextSpan(text: 'Mã OTP có hiệu lực trong '),
                            TextSpan(text: '5 phút', style: TextStyle(color: MauSac.chuChinh, fontWeight: FontWeight.bold)),
                            TextSpan(text: '. Vui lòng kiểm tra cả hộp thư '),
                            TextSpan(text: 'Spam / Thư rác', style: TextStyle(color: MauSac.chuChinh, fontWeight: FontWeight.bold)),
                            TextSpan(text: ' nếu không thấy thư.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: KhoangCach.lon),

                // NÚT CTA GỬI MÃ XÁC THỰC
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _dangXuLy ? null : _guiMaOtp,
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
                                'Gửi mã xác thực về Gmail',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(BieuTuong.guiThu, color: Colors.black, size: 18),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),

                // CARD MẸO NHẬN MÃ & HỖ TRỢ
                Container(
                  padding: KhoangCach.lToanBoChuan,
                  decoration: BoxDecoration(
                    color: MauSac.nenThe,
                    borderRadius: BoGoc.borderVua,
                    border: Border.all(color: MauSac.duongVienNhat),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(BieuTuong.khienBaoMat, color: MauSac.chuDao, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Mẹo nhận mã & Hỗ trợ',
                            style: TextStyle(
                              color: MauSac.chuChinh,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(BieuTuong.dauTichTron, color: MauSac.chuDao, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đảm bảo nhập đúng tài khoản Gmail đã đăng ký và liên kết với Capy Money.',
                              style: TextStyle(color: MauSac.chuPhu, fontSize: 12, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(BieuTuong.dongBo, color: MauSac.phu, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(color: MauSac.chuPhu, fontSize: 12, height: 1.3),
                                children: [
                                  TextSpan(text: 'Chưa nhận được mã? Bạn có thể yêu cầu gửi lại sau '),
                                  TextSpan(text: '60 giây', style: TextStyle(color: MauSac.chuChinh, fontWeight: FontWeight.bold)),
                                  TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: KhoangCach.sieuLon),

                // FOOTER LINK ĐĂNG NHẬP NGAY
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Bạn nhớ mật khẩu rồi? ',
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
                          SizedBox(width: 4),
                          Icon(BieuTuong.muiTenTien, color: MauSac.chuDao, size: 16),
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
