import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/hinh_anh.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../../giao_dien/chuan_thiet_ke/dap_ung.dart';
import '../../giao_dien/bottom_sheet/bs_lien_ket_tai_khoan.dart';
import '../../giao_dien/bottom_sheet/bs_cai_dat_nhac_nho.dart';
import '../../cau_hinh/duong_dan_api.dart';
import '../../mo_hinh/tai_khoan_ngan_hang_model.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import '../xac_thuc/man_hinh_dang_nhap.dart';

/// Tab 4: Màn hình Tài khoản Cá nhân "Tôi" (Profile & Security Settings)
/// 
/// Quản lý thông tin hồ sơ, tải/đổi avatar, cập nhật SĐT, liên kết ví ngân hàng và bật/tắt sinh trắc học vân tay.
class TabTaiKhoan extends StatefulWidget {
  const TabTaiKhoan({super.key});

  @override
  State<TabTaiKhoan> createState() => _TabTaiKhoanState();
}

class _TabTaiKhoanState extends State<TabTaiKhoan> {
  /// Cấu hình bật/tắt nhận báo cáo tuần qua Gmail
  bool _baoCaoGmail = true;

  /// Cấu hình bật/tắt nhắc nhở ghi chép giao dịch hàng ngày
  bool _nhacNhoGhiChep = true;

  /// Thời gian phát thông báo nhắc nhở (Mặc định '21:30')
  String _thoiGianNhacNho = '21:30';

  /// Cấu hình bật/tắt đăng nhập bằng vân tay cho tài khoản hiện tại
  bool _dangNhapVanTay = false;

  /// Họ và tên người dùng
  String _hoTen = '';

  /// Số điện thoại (10 chữ số)
  String _soDienThoai = '';

  /// Địa chỉ Gmail liên kết
  String _email = '';

  /// Đường dẫn URL ảnh đại diện (Online hoặc Cục bộ)
  String? _anhDaiDienPath;

  /// Thời điểm khởi tạo tài khoản của người dùng
  DateTime? _thoiGianTaoTaiKhoan;

  /// Số lượng ví / tài khoản ngân hàng liên kết
  int _soLuongVi = 0;

  /// Danh sách tài khoản / ví nhận tiền liên kết từ CSDL
  List<TaiKhoanNganHangModel> _danhSachViNganHang = [];

  /// Thư viện chọn/chụp ảnh ImagePicker
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadThongTinNguoiDung();
  }

  /// Tính toán thời gian gắn bó quy ra số ngày, tháng hoặc năm từ lúc tạo tài khoản đến thời điểm hiện tại
  String _tinhThoiGianGanBo(DateTime? thoiGianTao) {
    if (thoiGianTao == null) return '1 Ngày';
    final now = DateTime.now();
    final diff = now.difference(thoiGianTao);
    final soNgay = diff.inDays;

    if (soNgay < 1) {
      return '1 Ngày';
    } else if (soNgay < 30) {
      return '$soNgay Ngày';
    } else if (soNgay < 365) {
      final soThang = (soNgay / 30).floor();
      return '$soThang Tháng';
    } else {
      final soNam = (soNgay / 365).floor();
      final soThangDu = ((soNgay % 365) / 30).floor();
      if (soThangDu > 0) {
        return '$soNam Năm $soThangDu Thg';
      }
      return '$soNam Năm';
    }
  }

  /// Nạp thông tin người dùng từ Supabase CSDL, Auth & SharedPreferences
  Future<void> _loadThongTinNguoiDung() async {
    final user = DichVuSupabase.nguoiDungHienTai;
    final prefs = await SharedPreferences.getInstance();

    final String emailCurrent = (user?.email ??
            prefs.getString('capymoney_da_dang_nhap_lan_cuoi_email') ??
            'example@gmail.com')
        .toLowerCase()
        .trim();

    String hoTenCurrent = (user?.userMetadata?['ho_ten'] as String?) ??
        prefs.getString('capymoney_da_dang_nhap_lan_cuoi_ten') ??
        'Nguoi dung Capy';

    String sdtCurrent = (user?.userMetadata?['so_dien_thoai'] as String?) ??
        prefs.getString('capymoney_da_dang_nhap_lan_cuoi_sdt') ??
        'Chưa có SĐT';

    String? anhPathCurrent = prefs.getString('capymoney_anh_dai_dien_$emailCurrent');

    DateTime? taoLucAcc = user?.createdAt != null ? DateTime.tryParse(user!.createdAt) : null;
    int soViCount = 0;
    List<TaiKhoanNganHangModel> listViLoaded = [];

    bool nhacNhoGhiChepVal = prefs.getBool('capymoney_nhac_nho_bat_$emailCurrent') ?? true;
    String thoiGianNhacNhoVal = prefs.getString('capymoney_nhac_nho_gio_$emailCurrent') ?? '21:30';
    bool baoCaoGmailVal = prefs.getBool('capymoney_bao_cao_gmail_$emailCurrent') ?? true;

    // Ưu tiên đọc thông tin mới nhất trực tiếp từ Service CSDL Supabase
    if (user != null) {
      try {
        var ndModel = await DichVuSupabase.layThongTinNguoiDung(user.id);
        // Nếu lần đầu tiên chưa có bản ghi hoặc mang tên mặc định cũ -> Khởi tạo / đồng bộ tên thực từ Google Auth
        if (ndModel == null || ndModel.hoTen.isEmpty || ndModel.hoTen == 'Nguoi dung Capy' || ndModel.hoTen == 'Chủ tài khoản') {
          ndModel = await DichVuSupabase.dongBoThongTinNguoiDungGoogle();
        }

        if (ndModel != null) {
          if (ndModel.hoTen.isNotEmpty) hoTenCurrent = ndModel.hoTen;
          sdtCurrent = ndModel.soDienThoai ?? '';
          if (ndModel.anhDaiDien != null && ndModel.anhDaiDien!.startsWith('http')) {
            anhPathCurrent = ndModel.anhDaiDien;
            await prefs.setString('capymoney_anh_dai_dien_$emailCurrent', ndModel.anhDaiDien!);
          }
          if (ndModel.taoLuc != null) {
            taoLucAcc = ndModel.taoLuc;
          }
          nhacNhoGhiChepVal = ndModel.nhacNhoGhiChep;
          if (ndModel.thoiGianNhacNho.isNotEmpty) {
            thoiGianNhacNhoVal = ndModel.thoiGianNhacNho;
          }
          baoCaoGmailVal = ndModel.baoCaoGmail;
        }

        // Lấy danh sách tài khoản & ví thực tế từ Service CSDL Supabase
        final listVi = await DichVuSupabase.layDanhSachTaiKhoan();
        soViCount = listVi.length;
        listViLoaded = listVi;
      } catch (_) {}
    }

    final bool trangThaiVanTay =
        prefs.getBool('capymoney_van_tay_bat_$emailCurrent') ??
            prefs.getBool('capymoney_van_tay_bat') ??
            false;

    await prefs.setString('capymoney_da_dang_nhap_lan_cuoi_email', emailCurrent);
    await prefs.setString('capymoney_da_dang_nhap_lan_cuoi_ten', hoTenCurrent);
    await prefs.setString('capymoney_da_dang_nhap_lan_cuoi_sdt', sdtCurrent);

    if (mounted) {
      setState(() {
        _email = emailCurrent.isNotEmpty ? emailCurrent : _email;
        _hoTen = hoTenCurrent;
        _soDienThoai = sdtCurrent;
        _anhDaiDienPath = anhPathCurrent;
        _dangNhapVanTay = trangThaiVanTay;
        _thoiGianTaoTaiKhoan = taoLucAcc;
        _soLuongVi = soViCount;
        _danhSachViNganHang = listViLoaded;
        _nhacNhoGhiChep = nhacNhoGhiChepVal;
        _thoiGianNhacNho = thoiGianNhacNhoVal;
        _baoCaoGmail = baoCaoGmailVal;
      });
    }
  }

  /// Mở Bottom Sheet chọn nguồn ảnh đại diện từ Thư viện (Gallery) hoặc Máy ảnh (Camera)
  Future<void> _chonAnhDaiDien() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: MauSac.nenThe,
      shape: const RoundedRectangleBorder(
        borderRadius: BoGoc.borderBottomSheet,
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: KhoangCach.lToanBoChuan,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Cập nhật ảnh đại diện',
                  style: TextStyle(
                    color: MauSac.chuChinh,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: KhoangCach.lon),
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded, color: MauSac.chuDao),
                  title: const Text('Chụp ảnh mới (Camera)', style: TextStyle(color: MauSac.chuChinh)),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                    if (image != null) _capNhatAnhDaiDien(image);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: MauSac.phu),
                  title: const Text('Chọn từ Thư viện (Gallery)', style: TextStyle(color: MauSac.chuChinh)),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) _capNhatAnhDaiDien(image);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Lưu ảnh đại diện mới lên Supabase Storage, CSDL & SharedPreferences
  Future<void> _capNhatAnhDaiDien(XFile xFile) async {
    final prefs = await SharedPreferences.getInstance();
    final user = DichVuSupabase.nguoiDungHienTai;

    // Hiển thị tạm thời bằng file/blob cục bộ trong khi chờ tải lên
    setState(() => _anhDaiDienPath = xFile.path);

    if (user != null) {
      try {
        // 1. Tải ảnh lên Supabase Storage Bucket 'avatars' (tự động xóa ảnh cũ & gắn timestamp độc nhất)
        final urlOnline = await DichVuSupabase.taiAnhDaiDienLenStorage(xFile, user.id);

        if (urlOnline != null && urlOnline.isNotEmpty) {
          // 2. Cập nhật URL công khai mới nhất vào state & bộ nhớ máy
          setState(() => _anhDaiDienPath = urlOnline);
          await prefs.setString('capymoney_anh_dai_dien_$_email', urlOnline);

          // 3. Chỉ lưu URL HTTP công khai vào bảng nguoi_dung (đảm bảo hiển thị trên mọi thiết bị)
          await DichVuSupabase.client
              .from(DuongDanApi.bangNguoiDung)
              .update({'anh_dai_dien': urlOnline})
              .eq('id', user.id);
        }
      } catch (e) {
        debugPrint('Lỗi cập nhật ảnh đại diện: $e');
      }
    } else {
      await prefs.setString('capymoney_anh_dai_dien_$_email', xFile.path);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cập nhật ảnh đại diện thành công!'),
        backgroundColor: MauSac.chuDao,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Hộp thoại Chỉnh sửa Họ tên & Số điện thoại người dùng
  Future<void> _hienHopThoaiSuaThongTin() async {
    final hoTenCtrl = TextEditingController(text: _hoTen);
    final sdtCtrl = TextEditingController(text: _soDienThoai);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: MauSac.nenThe,
          shape: RoundedRectangleBorder(borderRadius: BoGoc.borderLon),
          title: Row(
            children: const [
              Icon(Icons.edit_note_rounded, color: MauSac.chuDao, size: 24),
              SizedBox(width: 8),
              Text(
                'Sửa thông tin cá nhân',
                style: TextStyle(color: MauSac.chuChinh, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Họ và tên', style: TextStyle(color: MauSac.chuPhu, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: hoTenCtrl,
                  style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: MauSac.chuPhu, size: 18),
                    filled: true,
                    fillColor: MauSac.nenNoi,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                    focusedBorder: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.chuDao)),
                  ),
                ),

                const SizedBox(height: KhoangCach.phatChuan),

                const Text('Số điện thoại (10 chữ số)', style: TextStyle(color: MauSac.chuPhu, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: sdtCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10,
                  style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                  decoration: InputDecoration(
                    counterText: '',
                    prefixIcon: const Icon(Icons.phone_outlined, color: MauSac.chuPhu, size: 18),
                    filled: true,
                    fillColor: MauSac.nenNoi,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                    focusedBorder: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.chuDao)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: MauSac.chuPhu)),
            ),
            ElevatedButton(
              onPressed: () async {
                final tenMoi = hoTenCtrl.text.trim();
                final sdtMoi = sdtCtrl.text.trim();

                if (tenMoi.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Họ và tên không được để trống'), backgroundColor: MauSac.chiTieu),
                  );
                  return;
                }

                if (sdtMoi.length != 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Số điện thoại phải gồm đúng 10 chữ số'), backgroundColor: MauSac.chiTieu),
                  );
                  return;
                }

                final user = DichVuSupabase.nguoiDungHienTai;
                final prefs = await SharedPreferences.getInstance();

                await prefs.setString('capymoney_da_dang_nhap_lan_cuoi_ten', tenMoi);
                await prefs.setString('capymoney_da_dang_nhap_lan_cuoi_sdt', sdtMoi);

                if (user != null) {
                  try {
                    await DichVuSupabase.capNhatThongTinCaNhan(
                      userId: user.id,
                      hoTen: tenMoi,
                      soDienThoai: sdtMoi,
                    );
                  } catch (_) {}
                }

                if (!context.mounted) return;

                setState(() {
                  _hoTen = tenMoi;
                  _soDienThoai = sdtMoi;
                });

                Navigator.of(context, rootNavigator: true).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cập nhật thông tin cá nhân thành công!'), backgroundColor: MauSac.chuDao),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MauSac.chuDao,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BoGoc.borderTron),
              ),
              child: const Text('Cập nhật', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  /// Cập nhật bật/tắt nhắc nhở ghi chép giao dịch hàng ngày
  Future<void> _thayDoiTrangThaiNhacNho(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    final user = DichVuSupabase.nguoiDungHienTai;

    setState(() => _nhacNhoGhiChep = val);

    if (_email.isNotEmpty) {
      await prefs.setBool('capymoney_nhac_nho_bat_$_email', val);
    }

    if (user != null) {
      await DichVuSupabase.capNhatCaiDatNhacNho(
        userId: user.id,
        nhacNhoGhiChep: val,
        thoiGianNhacNho: _thoiGianNhacNho,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          val
              ? 'Đã bật nhắc nhở ghi chép giao dịch lúc $_thoiGianNhacNho hàng ngày'
              : 'Đã tắt nhắc nhở ghi chép giao dịch',
        ),
        backgroundColor: val ? MauSac.chuDao : MauSac.nenNoi,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Mở Bảng trượt Cài đặt giờ nhắc nhở ghi chép giao dịch (BsCaiDatNhacNho)
  Future<void> _chonThoiGianNhacNho() async {
    final String? gioMoi = await BsCaiDatNhacNho.hienThi(
      context,
      thoiGianBanDau: _thoiGianNhacNho,
    );

    if (gioMoi != null && gioMoi.isNotEmpty) {
      setState(() {
        _thoiGianNhacNho = gioMoi;
        _nhacNhoGhiChep = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final user = DichVuSupabase.nguoiDungHienTai;

      if (_email.isNotEmpty) {
        await prefs.setString('capymoney_nhac_nho_gio_$_email', gioMoi);
        await prefs.setBool('capymoney_nhac_nho_bat_$_email', true);
      }

      if (user != null) {
        await DichVuSupabase.capNhatCaiDatNhacNho(
          userId: user.id,
          nhacNhoGhiChep: true,
          thoiGianNhacNho: gioMoi,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật giờ nhắc nhở ghi chép thành $gioMoi hàng ngày!'),
          backgroundColor: MauSac.chuDao,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Cập nhật bật/tắt nhận báo cáo tuần qua Gmail
  Future<void> _thayDoiBaoCaoGmail(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    final user = DichVuSupabase.nguoiDungHienTai;

    setState(() => _baoCaoGmail = val);

    if (_email.isNotEmpty) {
      await prefs.setBool('capymoney_bao_cao_gmail_$_email', val);
    }

    if (user != null) {
      await DichVuSupabase.capNhatCaiDatBaoCaoGmail(
        userId: user.id,
        baoCaoGmail: val,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          val
              ? 'Đã bật nhận báo cáo phân tích tuần qua Gmail'
              : 'Đã tắt nhận báo cáo phân tích qua Gmail',
        ),
        backgroundColor: val ? MauSac.chuDao : MauSac.nenNoi,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Cập nhật bật/tắt đăng nhập bằng vân tay cho tài khoản hiện tại trong SharedPreferences
  Future<void> _thayDoiTrangThaiVanTay(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    final emailKey = _email.toLowerCase().trim();

    setState(() => _dangNhapVanTay = val);

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

  /// Thao tác đăng xuất tài khoản và xóa thông tin phiên làm việc
  Future<void> _xuLyDangXuat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
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
        child: DapUng.bocKhungNoiDung(
          child: SingleChildScrollView(
            padding: KhoangCach.lNgangLon,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: KhoangCach.phatChuan),

                // SECTION 1: HEADER BAR LOGO CAPY MONEY (TÔI) VA BELL NOTIFICATION
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

                        // Avatar nhỏ góc phải
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

                // SECTION 2: CARD HỒ SƠ CÁ NHÂN (AVATAR, HỌ TÊN, SĐT VA ĐỊNH DANH GMAIL)
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
                          // Avatar tròn cỡ lớn + Nút Camera
                          GestureDetector(
                            onTap: _chonAnhDaiDien,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: MauSac.chuDao, width: 2),
                                  ),
                                  child: ClipOval(
                                    child: _anhDaiDienPath != null && _anhDaiDienPath!.isNotEmpty
                                        ? (kIsWeb ||
                                                _anhDaiDienPath!.startsWith('http') ||
                                                _anhDaiDienPath!.startsWith('blob:'))
                                            ? Image.network(
                                                _anhDaiDienPath!,
                                                fit: BoxFit.cover,
                                                width: 68,
                                                height: 68,
                                                errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                                                  backgroundColor: MauSac.nenNoi,
                                                  child: Icon(Icons.person_rounded, color: MauSac.chuDao, size: 36),
                                                ),
                                              )
                                            : Image.file(
                                                File(_anhDaiDienPath!),
                                                fit: BoxFit.cover,
                                                width: 68,
                                                height: 68,
                                                errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                                                  backgroundColor: MauSac.nenNoi,
                                                  child: Icon(Icons.person_rounded, color: MauSac.chuDao, size: 36),
                                                ),
                                              )
                                        : const CircleAvatar(
                                            backgroundColor: MauSac.nenNoi,
                                            child: Icon(Icons.person_rounded, color: MauSac.chuDao, size: 36),
                                          ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: MauSac.chuDao,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 12),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Tên, SĐT + Nút sửa ✏️
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
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: MauSac.chuChinh,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _hienHopThoaiSuaThongTin,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: MauSac.nenNoi,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.edit_outlined, color: MauSac.chuDao, size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // Dòng nhỏ hiển thị Số điện thoại
                                Row(
                                  children: [
                                    const Icon(Icons.phone_android_rounded, color: MauSac.chuPhu, size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      _soDienThoai.isNotEmpty ? _soDienThoai : 'Chưa có SĐT',
                                      style: const TextStyle(
                                        color: MauSac.chuPhu,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: KhoangCach.vua),

                      // Thẻ Định danh Tài khoản Google
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

                // SECTION 3: CỤM 2 THẺ THỐNG KÊ VÍ & THỜI GIAN GẮN BÓ DỰA TRÊN NGÀY TẠO TÀI KHOẢN
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
                            Text(
                              '$_soLuongVi Ví',
                              style: const TextStyle(
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
                            Text(
                              _tinhThoiGianGanBo(_thoiGianTaoTaiKhoan),
                              style: const TextStyle(
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

                // SECTION 4: QUẢN LÝ TÀI CHÍNH & TÀI KHOẢN
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
                      // Nút Mở Bottom Sheet Liên kết ví & tài khoản ngân hàng
                      ListTile(
                        onTap: () async {
                          await BsLienKetTaiKhoan.hienThi(context);
                          _loadThongTinNguoiDung();
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: MauSac.nenNoi,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded,
                              color: MauSac.chuDao, size: 20),
                        ),
                        title: const Text(
                          'Tài khoản & Ví liên kết',
                          style: TextStyle(
                            color: MauSac.chuChinh,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: _danhSachViNganHang.isNotEmpty
                              ? Text(
                                  _danhSachViNganHang.map((e) => e.tenNganHang).join(' • '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: MauSac.chuPhu, fontSize: 11),
                                )
                              : const Text(
                                  'Chưa liên kết ví / ngân hàng nào',
                                  style: TextStyle(color: MauSac.chuPhu, fontSize: 11),
                                ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _danhSachViNganHang.isNotEmpty
                                    ? MauSac.chuDao.withValues(alpha: 0.15)
                                    : MauSac.nenNoi,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _danhSachViNganHang.isNotEmpty
                                    ? '${_danhSachViNganHang.length} nguồn'
                                    : '0 nguồn',
                                style: TextStyle(
                                  color: _danhSachViNganHang.isNotEmpty ? MauSac.chuDao : MauSac.chuPhu,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, color: MauSac.chuPhu, size: 20),
                          ],
                        ),
                      ),

                      const Divider(color: MauSac.duongVienNhat, height: 1),

                      // Bật/tắt Báo cáo tuần qua Gmail
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
                          onChanged: (val) => _thayDoiBaoCaoGmail(val),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),

                // SECTION 5: BẢO MẬT & HỆ THỐNG
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
                      // Bật/tắt & Cài đặt giờ Nhắc nhở ghi chép giao dịch
                      ListTile(
                        onTap: _chonThoiGianNhacNho,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: MauSac.nenNoi,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notifications_active_rounded,
                              color: MauSac.canhBao, size: 20),
                        ),
                        title: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Nhắc nhở ghi chép',
                                style: TextStyle(
                                  color: MauSac.chuChinh,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: MauSac.nenNoi,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: MauSac.duongVienNhat),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time_rounded, color: MauSac.canhBao, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    _thoiGianNhacNho,
                                    style: const TextStyle(
                                      color: MauSac.canhBao,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.edit_rounded, color: MauSac.chuPhu, size: 10),
                                ],
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          _nhacNhoGhiChep
                              ? 'Chạm để đổi giờ • Nhắc nhở lúc $_thoiGianNhacNho hàng ngày'
                              : 'Đã tắt thông báo nhắc nhở hàng ngày',
                          style: const TextStyle(color: MauSac.chuPhu, fontSize: 11),
                        ),
                        trailing: Switch(
                          value: _nhacNhoGhiChep,
                          activeTrackColor: MauSac.chuDao,
                          onChanged: (val) => _thayDoiTrangThaiNhacNho(val),
                        ),
                      ),

                      const Divider(color: MauSac.duongVienNhat, height: 1),

                      // Bật/tắt Đăng nhập bằng vân tay
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

                // SECTION 6: NÚT ĐĂNG XUẤT TÀI KHOẢN
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

                // SECTION 7: FOOTER THÔNG TIN ỨNG DỤNG BẢO MẬT
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
      ),
    );
  }
}
