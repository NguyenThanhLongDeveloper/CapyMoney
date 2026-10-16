import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/hinh_anh.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../../giao_dien/bottom_sheet/bs_lien_ket_tai_khoan.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import '../xac_thuc/man_hinh_dang_nhap.dart';

/// Tab 4: Màn hình Tài khoản Tôi (Profile & Settings)
class TabTaiKhoan extends StatefulWidget {
  const TabTaiKhoan({super.key});

  @override
  State<TabTaiKhoan> createState() => _TabTaiKhoanState();
}

class _TabTaiKhoanState extends State<TabTaiKhoan> {
  bool _baoCaoGmail = true;
  bool _nhacNhoGhiChep = true;
  bool _dangNhapVanTay = false;

  String _hoTen = 'Nguyễn Hải Đăng';
  String _email = 'haidang.finance@gmail.com';

  @override
  void initState() {
    super.initState();
    _loadThongTinNguoiDung();
  }

  /// Nạp thông tin người dùng từ Supabase Auth & SharedPreferences
  Future<void> _loadThongTinNguoiDung() async {
    final user = DichVuSupabase.client.auth.currentUser;
    final prefs = await SharedPreferences.getInstance();

    final String emailCurrent = (user?.email ??
            prefs.getString('capymoney_da_dang_nhap_lan_cuoi_email') ??
            'haidang.finance@gmail.com')
        .toLowerCase()
        .trim();

    final String hoTenCurrent = (user?.userMetadata?['ho_ten'] as String?) ??
        prefs.getString('capymoney_da_dang_nhap_lan_cuoi_ten') ??
        'Nguyễn Hải Đăng';

    // Đọc chính xác trạng thái bật/tắt vân tay
    bool trangThaiVanTay = false;
    if (emailCurrent.isNotEmpty && prefs.containsKey('capymoney_van_tay_bat_$emailCurrent')) {
      trangThaiVanTay = prefs.getBool('capymoney_van_tay_bat_$emailCurrent')!;
    } else if (prefs.containsKey('capymoney_van_tay_bat')) {
      trangThaiVanTay = prefs.getBool('capymoney_van_tay_bat')!;
    }

    if (emailCurrent.isNotEmpty) {
      await prefs.setString('capymoney_da_dang_nhap_lan_cuoi_email', emailCurrent);
    }
    await prefs.setString('capymoney_da_dang_nhap_lan_cuoi_ten', hoTenCurrent);

    if (mounted) {
      setState(() {
        _email = emailCurrent.isNotEmpty ? emailCurrent : _email;
        _hoTen = hoTenCurrent;
        _dangNhapVanTay = trangThaiVanTay;
      });
    }
  }

  /// Cập nhật bật/tắt đăng nhập bằng vân tay cho tài khoản hiện tại
  Future<void> _thayDoiTrangThaiVanTay(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    final emailKey = _email.toLowerCase().trim();

    setState(() => _dangNhapVanTay = val);

    // Lưu đồng bộ cả khóa theo email lẫn khóa toàn cục
    if (emailKey.isNotEmpty) {
      await prefs.setBool('capymoney_van_tay_bat_$emailKey', val);
    }
    await prefs.setBool('capymoney_van_tay_bat', val);
    await prefs.setString('capymoney_van_tay_email', emailKey);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          val
              ? 'Đã bật đăng nhập bằng vân tay cho tài khoản $_email'
              : 'Đã tắt đăng nhập bằng vân tay cho tài khoản $_email',
        ),
        backgroundColor: val ? MauSac.chuDao : MauSac.nenNoi,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Thao tác đăng xuất tài khoản
  Future<void> _xuLyDangXuat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Đặt lại trạng thái ghi nhớ đăng nhập về false và xóa mật khẩu lưu tạm
      await prefs.setBool('capymoney_ghi_nho_trang_thai', false);
      await prefs.remove('capymoney_ghi_nho_mat_khau');

      await DichVuSupabase.dangXuat();
    } catch (_) {}

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ManHinhDangNhap()),
      (route) => false,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: KhoangCach.phatChuan),

              // Header Bar: Logo + Capy Money (Tôi) + Bell + Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          HinhAnh.logoCapy,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 36,
                            height: 36,
                            color: MauSac.nenNoi,
                            child: const Icon(BieuTuong.capybaraThantai, color: MauSac.canhBao, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Capy Money',
                            style: TextStyle(
                              color: MauSac.chuChinh,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Tôi',
                            style: TextStyle(
                              color: MauSac.chuPhu,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      // Chuông thông báo
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: MauSac.nenThe,
                              shape: BoxShape.circle,
                              border: Border.all(color: MauSac.duongVienNhat),
                            ),
                            child: const Icon(Icons.notifications_none_rounded, color: MauSac.chuChinh, size: 20),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: MauSac.chuDao,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),

                      // Avatar góc phải
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: MauSac.nenNoi,
                        child: const Icon(Icons.person_rounded, color: MauSac.chuDao, size: 20),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: KhoangCach.lon),

              // Card Hồ sơ cá nhân
              Container(
                padding: KhoangCach.lToanBoLon,
                decoration: BoxDecoration(
                  color: MauSac.nenThe,
                  borderRadius: BoGoc.borderLon,
                  border: Border.all(color: MauSac.duongVienNhat),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar tròn cỡ lớn + Icon camera
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: MauSac.chuDao, width: 2),
                              ),
                              child: const CircleAvatar(
                                backgroundColor: MauSac.nenNoi,
                                child: Icon(Icons.person_rounded, color: MauSac.chuDao, size: 36),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: MauSac.chuDao,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 12),
                            ),
                          ],
                        ),

                        const SizedBox(width: 16),

                        // Tên + Nút sửa
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _hoTen,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: MauSac.chuChinh,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: MauSac.nenNoi,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.edit_outlined, color: MauSac.chuPhu, size: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: KhoangCach.vua),

                    // Thẻ Định danh Google Account
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: MauSac.nenNoi,
                        borderRadius: BoGoc.borderVua,
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'G',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Text(
                                      'TÀI KHOẢN GOOGLE',
                                      style: TextStyle(
                                        color: MauSac.chuPhu,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.check_circle_rounded, color: MauSac.chuDao, size: 12),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _email,
                                  style: const TextStyle(
                                    color: MauSac.chuChinh,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KhoangCach.phatChuan),

              // Cụm 2 Thẻ Thống kê Tinh gọn
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: KhoangCach.lToanBoChuan,
                      decoration: BoxDecoration(
                        color: MauSac.nenThe,
                        borderRadius: BoGoc.borderVua,
                        border: Border.all(color: MauSac.duongVienNhat),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: MauSac.nenNoi,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded,
                                color: MauSac.chuDao, size: 18),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '3 Ví',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: MauSac.chuChinh,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Tài khoản hoạt động',
                            style: TextStyle(color: MauSac.chuPhu, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: KhoangCach.lToanBoChuan,
                      decoration: BoxDecoration(
                        color: MauSac.nenThe,
                        borderRadius: BoGoc.borderVua,
                        border: Border.all(color: MauSac.duongVienNhat),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: MauSac.nenNoi,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.access_time_rounded,
                                color: MauSac.phu, size: 18),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '12 Thg',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: MauSac.chuChinh,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Thời gian gắn bó',
                            style: TextStyle(color: MauSac.chuPhu, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: KhoangCach.lon),

              // SECTION 1: TÀI CHÍNH & TÀI KHOẢN
              const Text(
                'TÀI CHÍNH & TÀI KHOẢN',
                style: TextStyle(
                  color: MauSac.chuPhu,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: KhoangCach.nho),

              Container(
                decoration: BoxDecoration(
                  color: MauSac.nenThe,
                  borderRadius: BoGoc.borderVua,
                  border: Border.all(color: MauSac.duongVienNhat),
                ),
                child: Column(
                  children: [
                    // Tài khoản & Ví liên kết
                    ListTile(
                      onTap: () => BsLienKetTaiKhoan.hienThi(context),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MauSac.nenNoi,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded,
                            color: MauSac.chuDao, size: 20),
                      ),
                      title: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Tài khoản & Ví liên kết',
                              style: TextStyle(
                                color: MauSac.chuChinh,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              _taoChipVi('VCB'),
                              const SizedBox(width: 4),
                              _taoChipVi('TCB'),
                              const SizedBox(width: 4),
                              _taoChipVi('MoMo'),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: MauSac.chuDao.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  '3 nguồn',
                                  style: TextStyle(
                                    color: MauSac.chuDao,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: MauSac.chuPhu, size: 20),
                    ),

                    const Divider(color: MauSac.duongVienNhat, height: 1),

                    // Báo cáo tuần qua Gmail
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MauSac.nenNoi,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.mark_email_unread_rounded,
                            color: MauSac.phu, size: 20),
                      ),
                      title: const Text(
                        'Báo cáo tuần qua Gmail',
                        style: TextStyle(
                          color: MauSac.chuChinh,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Gửi bảng phân tích tự động mỗi Chủ Nhật',
                        style: TextStyle(color: MauSac.chuPhu, fontSize: 11),
                      ),
                      trailing: Switch(
                        value: _baoCaoGmail,
                        activeTrackColor: MauSac.chuDao,
                        onChanged: (val) => setState(() => _baoCaoGmail = val),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KhoangCach.lon),

              // SECTION 2: BẢO MẬT & HỆ THỐNG
              const Text(
                'BẢO MẬT & HỆ THỐNG',
                style: TextStyle(
                  color: MauSac.chuPhu,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: KhoangCach.nho),

              Container(
                decoration: BoxDecoration(
                  color: MauSac.nenThe,
                  borderRadius: BoGoc.borderVua,
                  border: Border.all(color: MauSac.duongVienNhat),
                ),
                child: Column(
                  children: [
                    // Nhắc nhở ghi chép
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MauSac.nenNoi,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_active_rounded,
                            color: MauSac.canhBao, size: 20),
                      ),
                      title: const Text(
                        'Nhắc nhở ghi chép',
                        style: TextStyle(
                          color: MauSac.chuChinh,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Thông báo mỗi 21:30 hàng ngày',
                        style: TextStyle(color: MauSac.chuPhu, fontSize: 11),
                      ),
                      trailing: Switch(
                        value: _nhacNhoGhiChep,
                        activeTrackColor: MauSac.chuDao,
                        onChanged: (val) => setState(() => _nhacNhoGhiChep = val),
                      ),
                    ),

                    const Divider(color: MauSac.duongVienNhat, height: 1),

                    // Đăng nhập bằng vân tay
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MauSac.nenNoi,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.fingerprint_rounded,
                            color: MauSac.chuDao, size: 20),
                      ),
                      title: const Text(
                        'Đăng nhập bằng vân tay',
                        style: TextStyle(
                          color: MauSac.chuChinh,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Xác thực sinh trắc học nhanh và an toàn',
                        style: TextStyle(color: MauSac.chuPhu, fontSize: 11),
                      ),
                      trailing: Switch(
                        value: _dangNhapVanTay,
                        activeTrackColor: MauSac.chuDao,
                        onChanged: (val) => _thayDoiTrangThaiVanTay(val),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KhoangCach.lon),

              // Nút Đăng xuất tài khoản Google
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _xuLyDangXuat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MauSac.nenThe,
                    foregroundColor: MauSac.chiTieu,
                    elevation: 0,
                    side: const BorderSide(color: MauSac.duongVienNhat),
                    shape: RoundedRectangleBorder(
                      borderRadius: BoGoc.borderVua,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout_rounded, color: MauSac.chiTieu, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Đăng xuất tài khoản Google',
                        style: TextStyle(
                          color: MauSac.chiTieu,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: KhoangCach.lon),

              // Footer thông tin ứng dụng
              Center(
                child: Column(
                  children: const [
                    Text(
                      'Capy Money Studio Mobile Edition • v2.4.0 (Build 412)',
                      style: TextStyle(
                        color: MauSac.chuDao,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Bảo mật mã hóa 256–bit AES chuẩn tổ chức tài chính',
                      style: TextStyle(
                        color: MauSac.chuMo,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KhoangCach.lon),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taoChipVi(String ten) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: MauSac.nenNoi,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        ten,
        style: const TextStyle(
          color: MauSac.chuPhu,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
