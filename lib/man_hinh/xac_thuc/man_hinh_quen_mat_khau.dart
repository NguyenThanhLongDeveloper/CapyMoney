import 'package:flutter/material.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import 'man_hinh_xac_thuc_otp.dart';

/// Màn hình Quên mật khẩu qua Gmail (Capy Money Forgot Password)
class ManHinhQuenMatKhau extends StatefulWidget {
  const ManHinhQuenMatKhau({super.key});

  @override
  State<ManHinhQuenMatKhau> createState() => _ManHinhQuenMatKhauState();
}

class _ManHinhQuenMatKhauState extends State<ManHinhQuenMatKhau> {
  final _emailController = TextEditingController(text: 'vidu@gmail.com');
  bool _dangXuLy = false;

  Future<void> _guiMaOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập địa chỉ Gmail'),
          backgroundColor: MauSac.chiTieu,
        ),
      );
      return;
    }

    setState(() => _dangXuLy = true);

    try {
      await DichVuSupabase.guiMaKhoiPhuc(email);
    } catch (e) {
      // Tiep tuc gia lap sang trang OTP neu chua gui duoc
    } finally {
      if (mounted) {
        setState(() => _dangXuLy = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ManHinhXacThucOtp(email: email),
          ),
        );
      }
    }
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
              const SizedBox(height: KhoangCach.lon),

              // Icon vong tron khoi phục mật khẩu phat sang
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: MauSac.nenNoi,
                  shape: BoxShape.circle,
                  border: Border.all(color: MauSac.chuDao.withValues(alpha: 0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: MauSac.chuDao.withValues(alpha: 0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: MauSac.chuDao,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restore_rounded,
                      color: Colors.black,
                      size: 26,
                    ),
                  ),
                ),
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

              const SizedBox(height: KhoangCach.sieuLon),

              // Form Nhap Gmail
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.alternate_email_rounded, color: MauSac.chuDao, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'ĐỊA CHỈ GMAIL XÁC THỰC',
                            style: TextStyle(
                              color: MauSac.chuPhu,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '● Bảo mật SSL',
                        style: TextStyle(
                          color: MauSac.chuDao,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email_outlined, color: MauSac.chuPhu, size: 20),
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

              // Note thong bao time 5 phut
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.access_time_filled_rounded, color: MauSac.canhBao, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mã OTP có hiệu lực trong 5 phút. Vui lòng kiểm tra cả hộp thư Spam / Thư rác nếu không thấy thư.',
                      style: TextStyle(
                        color: MauSac.chuPhu,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: KhoangCach.lon),

              // Nut Gửi mã xác thực
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
                            Icon(Icons.send_rounded, color: Colors.black, size: 18),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: KhoangCach.lon),

              // Card Mẹo nhận mã & Hỗ trợ
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
                        Icon(Icons.shield_outlined, color: MauSac.chuDao, size: 18),
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
                      children: const [
                        Icon(Icons.check_circle_outline_rounded, color: MauSac.chuDao, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kiểm tra chính xác địa chỉ email trước khi bấm gửi.',
                            style: TextStyle(color: MauSac.chuPhu, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.sync_rounded, color: MauSac.phu, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Chưa nhận được mã? Bạn có thể yêu cầu gửi lại sau 60 giây.',
                            style: TextStyle(color: MauSac.chuPhu, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KhoangCach.sieuLon),

              // Link quay ve dang nhap
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
                        Icon(Icons.arrow_forward_rounded, color: MauSac.chuDao, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
