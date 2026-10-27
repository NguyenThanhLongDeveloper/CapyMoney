import 'package:flutter/material.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../../giao_dien/chuan_thiet_ke/hinh_anh.dart';
import '../../giao_dien/chuan_thiet_ke/dap_ung.dart';
import '../../mo_hinh/giao_dich_model.dart';
import '../../mo_hinh/tai_khoan_ngan_hang_model.dart';
import '../../mo_hinh/danh_muc_model.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import '../giao_dich/man_hinh_danh_sach_giao_dich.dart';

/// Tab 1: Màn Hình Tổng Quan Tài Chính (Dashboard Screen)
/// 
/// Khớp 100% giao diện mockup: Thẻ Tổng tài sản khả dụng + 👁 Ẩn/Hiện số tiền, 
/// Thẻ Thu nhập tháng & Chi tiêu tháng, Biểu đồ thanh Chi tiêu tuần này (T2 -> CN),
/// và Danh sách Giao dịch gần đây.
class TabTongQuan extends StatefulWidget {
  const TabTongQuan({super.key});

  @override
  State<TabTongQuan> createState() => _TabTongQuanState();
}

class _TabTongQuanState extends State<TabTongQuan> {
  /// Cờ ẩn/hiện số tiền tài sản
  bool _anSoTien = false;

  /// Index ngày đang chọn trong tuần (0: T2, 1: T3, ... 4: T6, 5: T7, 6: CN)
  int _ngayChonIndex = 4; // Mặc định T6

  /// Trạng thái đang tải từ CSDL
  bool _dangTai = true;

  /// Tổng tài sản khả dụng
  double _tongTaiSan = 0.0;

  /// Thu nhập tháng này
  double _thuNhapThang = 0.0;

  /// Chi tiêu tháng này
  double _chiTieuThang = 0.0;

  /// Chi tiêu tổng tuần này
  double _chiTieuTuanNay = 0.0;

  /// Mảng chi tiêu 7 ngày trong tuần từ T2 -> CN
  List<double> _chiTieuCacNgay = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

  /// Danh sách tài khoản / ví ngân hàng
  List<TaiKhoanNganHangModel> _danhSachVi = [];

  /// Danh sách giao dịch gần đây
  List<GiaoDichModel> _danhSachGiaoDich = [];

  /// Danh sách danh mục thu chi từ CSDL
  List<DanhMucModel> _danhSachDanhMuc = [];

  @override
  void initState() {
    super.initState();
    final weekday = DateTime.now().weekday; // 1: T2 -> 7: CN
    _ngayChonIndex = (weekday - 1) % 7;
    _loadDuLieuDashboard();
  }

  /// Nạp dữ liệu thực tế từ CSDL Supabase
  Future<void> _loadDuLieuDashboard() async {
    setState(() => _dangTai = true);
    try {
      final viList = await DichVuSupabase.layDanhSachTaiKhoan();
      final giaoDichList = await DichVuSupabase.layDanhSachGiaoDich();
      final danhMucList = await DichVuSupabase.layDanhSachDanhMuc();

      if (mounted) {
        setState(() {
          _danhSachVi = viList;
          _danhSachGiaoDich = giaoDichList;
          _danhSachDanhMuc = danhMucList;

          // Lấy số dư tài khoản ngân hàng mặc định (la_nhan_chinh == true)
          if (viList.isNotEmpty) {
            final viMacDinh = viList.firstWhere(
              (vi) => vi.laNhanChinh,
              orElse: () => viList.first,
            );
            _tongTaiSan = viMacDinh.soDu;
          } else {
            _tongTaiSan = 0.0;
          }

          // Tính thu nhập và chi tiêu tháng này từ toàn bộ giao dịch CSDL trong tháng hiện tại (Không phân biệt ví)
          final now = DateTime.now();
          double sumThu = 0.0;
          double sumChi = 0.0;

          for (var gd in giaoDichList) {
            if (gd.ngayGiaoDich.month == now.month && gd.ngayGiaoDich.year == now.year) {
              if (gd.loaiGiaoDich == 'thu_nhap') {
                sumThu += gd.soTien;
              } else if (gd.loaiGiaoDich == 'chi_tieu') {
                sumChi += gd.soTien;
              }
            }
          }

          _thuNhapThang = sumThu;
          _chiTieuThang = sumChi;

          // 3. Tính chi tiêu tuần này (Từ Thứ 2 đến Chủ nhật của tuần hiện tại)
          final dtMonday = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: now.weekday - 1));

          final List<double> chiTieuTuanList = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

          for (var gd in giaoDichList) {
            if (gd.loaiGiaoDich == 'chi_tieu') {
              for (int i = 0; i < 7; i++) {
                final dayI = dtMonday.add(Duration(days: i));
                if (gd.ngayGiaoDich.year == dayI.year &&
                    gd.ngayGiaoDich.month == dayI.month &&
                    gd.ngayGiaoDich.day == dayI.day) {
                  chiTieuTuanList[i] += gd.soTien;
                  break;
                }
              }
            }
          }

          _chiTieuCacNgay = chiTieuTuanList;
          _chiTieuTuanNay = chiTieuTuanList.fold(0.0, (sum, val) => sum + val);

          // 4. Lọc danh sách giao dịch gần đây chỉ thuộc THÁNG HIỆN TẠI (Tất cả tài khoản)
          final List<GiaoDichModel> giaoDichThangNay = giaoDichList.where((gd) {
            return gd.ngayGiaoDich.month == now.month &&
                gd.ngayGiaoDich.year == now.year;
          }).toList();

          _danhSachGiaoDich = giaoDichThangNay;

          _dangTai = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi nạp Dashboard: $e');
      if (mounted) setState(() => _dangTai = false);
    }
  }

  /// Định dạng tiền VND
  String _dinhDangTien(double amount) {
    if (_anSoTien) return '•••••••• đ';
    final String numStr = amount.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formatted = numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return '$formatted đ';
  }

  /// Lấy ngày Thứ 2 của tuần hiện tại
  DateTime get _ngayThuHaiTuanNay {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  }

  /// Tính số tuần thứ mấy trong năm
  int get _soTuanTrongNam {
    final now = DateTime.now();
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final days = now.difference(firstDayOfYear).inDays;
    return ((days + firstDayOfYear.weekday) / 7).ceil();
  }

  /// Tên viết tắt các ngày trong tuần (T2 -> CN)
  String _layTenNgayShort(int index) {
    const list = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return list[index % 7];
  }

  /// Tên ngày đầy đủ kèm ngày tháng năm chính xác (Ví dụ: 'T6 (Hôm nay, 17/10/2026)')
  String _layTenNgayFull(int index) {
    final now = DateTime.now();
    final weekdayNowIndex = now.weekday - 1;
    final dayTarget = _ngayThuHaiTuanNay.add(Duration(days: index));
    final tenShort = _layTenNgayShort(index);

    final ngayThangStr = '${dayTarget.day.toString().padLeft(2, '0')}/${dayTarget.month.toString().padLeft(2, '0')}/${dayTarget.year}';

    if (index == weekdayNowIndex) {
      return '$tenShort (Hôm nay, $ngayThangStr)';
    }
    return '$tenShort ($ngayThangStr)';
  }

  @override
  Widget build(BuildContext context) {
    final viMacDinh = _danhSachVi.firstWhere(
      (vi) => vi.laNhanChinh,
      orElse: () => _danhSachVi.isNotEmpty
          ? _danhSachVi.first
          : TaiKhoanNganHangModel(
              id: '',
              nguoiDungId: '',
              tenNganHang: '',
              soTaiKhoan: '',
              tenChuTaiKhoan: '',
              soDu: 0,
            ),
    );

    final String tenChuTaiKhoan = viMacDinh.tenChuTaiKhoan.isNotEmpty
        ? viMacDinh.tenChuTaiKhoan.toUpperCase()
        : 'TRAN THI MAI';

    final String tenViPrimary = viMacDinh.soTaiKhoan.isNotEmpty
        ? '${viMacDinh.tenNganHang} • • • • ${viMacDinh.soTaiKhoan.length >= 4 ? viMacDinh.soTaiKhoan.substring(viMacDinh.soTaiKhoan.length - 4) : viMacDinh.soTaiKhoan}'
        : 'VCB • • • • 8912';

    return Scaffold(
      backgroundColor: MauSac.nenChinh,
      appBar: AppBar(
        backgroundColor: MauSac.nenChinh,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: MauSac.nenNoi,
              child: ClipOval(
                child: Image.asset(
                  HinhAnh.logoCapy,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    BieuTuong.capybaraThantai,
                    size: 22,
                    color: MauSac.canhBao,
                  ),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tổng quan',
                  style: TextStyle(
                    color: MauSac.chuPhu,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: DapUng.bocKhungNoiDung(
          child: RefreshIndicator(
            onRefresh: _loadDuLieuDashboard,
            color: MauSac.chuDao,
            backgroundColor: MauSac.nenThe,
            child: SingleChildScrollView(
              padding: KhoangCach.lNgangLon,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: KhoangCach.nho),

                  // CARD 1: TỔNG TÀI SẢN KHẢ DỤNG
                  Container(
                    width: double.infinity,
                    padding: KhoangCach.lToanBoLon,
                    decoration: BoxDecoration(
                      color: MauSac.nenThe,
                      borderRadius: BoGoc.borderLon,
                      border: Border.all(color: MauSac.duongVienNhat),
                      boxShadow: [
                        BoxShadow(
                          color: MauSac.chuDao.withValues(alpha: 0.05),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hàng 1: Label + Eye Icon Toggle
                        Row(
                          children: [
                            const Text(
                              'Tổng tài sản khả dụng',
                              style: TextStyle(
                                color: MauSac.chuPhu,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _anSoTien = !_anSoTien),
                              child: Icon(
                                _anSoTien ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: MauSac.chuPhu,
                                size: 16,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Hàng 2: Số tiền tài sản cỡ lớn
                        Text(
                          _dinhDangTien(_tongTaiSan),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: MauSac.chuChinh,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Hàng 3: Thẻ Ví VCB + Tên chủ tài khoản (Sắp xếp theo cột dọc)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // Canh lề trái (hoặc dùng CrossAxisAlignment.center nếu muốn căn giữa)
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.credit_card_rounded, color: MauSac.chuDao, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  tenViPrimary,
                                  style: const TextStyle(
                                    color: MauSac.chuPhu,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4), // Khoảng cách giữa tên ví và tên chủ tài khoản
                            Text(
                              tenChuTaiKhoan,
                              style: const TextStyle(
                                color: MauSac.chuPhu,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // CARD 2: HÀNG 2 CỘT (THU NHẬP THÁNG & CHI TIÊU THÁNG)
                  Row(
                    children: [
                      // Thẻ Thu Nhập Tháng
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text(
                                    'THU NHẬP THÁNG',
                                    style: TextStyle(
                                      color: MauSac.chuPhu,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Icon(Icons.arrow_downward_rounded, color: MauSac.thuNhap, size: 16),
                                ],
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                child: Text(
                                  _dinhDangTien(_thuNhapThang),
                                  style: const TextStyle(
                                    color: MauSac.chuChinh,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Thẻ Chi Tiêu Tháng
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text(
                                    'CHI TIÊU THÁNG',
                                    style: TextStyle(
                                      color: MauSac.chuPhu,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Icon(Icons.arrow_upward_rounded, color: MauSac.chiTieu, size: 16),
                                ],
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                child: Text(
                                  _dinhDangTien(_chiTieuThang),
                                  style: const TextStyle(
                                    color: MauSac.chuChinh,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // CARD 3: CHI TIÊU TUẦN NÀY (BIỂU ĐỒ BAR CHART T2 -> CN)
                  Container(
                    width: double.infinity,
                    padding: KhoangCach.lToanBoLon,
                    decoration: BoxDecoration(
                      color: MauSac.nenThe,
                      borderRadius: BoGoc.borderLon,
                      border: Border.all(color: MauSac.duongVienNhat),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Biểu đồ
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Chi tiêu tuần này',
                                  style: TextStyle(
                                    color: MauSac.chuChinh,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tổng: ${_dinhDangTien(_chiTieuTuanNay)}',
                                  style: const TextStyle(color: MauSac.chuPhu, fontSize: 11),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: MauSac.nenNoi,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Tuần $_soTuanTrongNam',
                                style: const TextStyle(color: MauSac.chuPhu, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: KhoangCach.lon),

                        // Hàng 7 Thanh Cột Bar Chart (T2 -> CN)
                        SizedBox(
                          height: 110,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(7, (index) {
                              final bool isSelected = _ngayChonIndex == index;
                              final double value = _chiTieuCacNgay[index];
                              final double maxValInWeek = _chiTieuCacNgay.reduce((a, b) => a > b ? a : b);
                              final double maxRef = maxValInWeek > 0 ? maxValInWeek : 1000000;
                              final double barHeight = value > 0
                                  ? ((value / maxRef) * 75).clamp(16.0, 75.0)
                                  : 12.0;

                              return GestureDetector(
                                onTap: () => setState(() => _ngayChonIndex = index),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: 22,
                                      height: barHeight,
                                      decoration: BoxDecoration(
                                        color: isSelected ? MauSac.chuDao : MauSac.nenNoi,
                                        borderRadius: BorderRadius.circular(11),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: MauSac.chuDao.withValues(alpha: 0.5),
                                                  blurRadius: 10,
                                                  spreadRadius: 1,
                                                )
                                              ]
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _layTenNgayShort(index),
                                      style: TextStyle(
                                        color: isSelected ? MauSac.chuDao : MauSac.chuPhu,
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),

                        const SizedBox(height: KhoangCach.vua),

                        // Footer chi tiết ngày đang xem
                        Container(
                          width: double.infinity, // Mở rộng hết chiều ngang để dễ căn giữa nếu cần
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: MauSac.nenNoi,
                            borderRadius: BoGoc.borderVua,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center, // Căn giữa theo chiều dọc
                            crossAxisAlignment: CrossAxisAlignment.center, // Căn giữa theo chiều ngang
                            children: [
                              Text(
                                'Đang xem: ${_layTenNgayFull(_ngayChonIndex)}',
                                textAlign: TextAlign.center, // Căn giữa text nếu dòng quá dài xuống dòng
                                style: const TextStyle(color: MauSac.chuChinh, fontSize: 12),
                              ),
                              const SizedBox(height: 4), // Khoảng cách nhỏ giữa 2 dòng text
                              Text(
                                _dinhDangTien(_chiTieuCacNgay[_ngayChonIndex]),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: MauSac.chuDao,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 4: GIAO DỊCH GẦN ĐÂY
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Giao dịch gần đây',
                        style: TextStyle(
                          color: MauSac.chuChinh,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManHinhDanhSachGiaoDich(),
                            ),
                          );
                          _loadDuLieuDashboard();
                        },
                        child: Row(
                          children: const [
                            Text(
                              'Xem tất cả',
                              style: TextStyle(
                                color: MauSac.chuDao,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.arrow_forward_rounded, color: MauSac.chuDao, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: KhoangCach.nho),

                  // DANH SÁCH CÁC THẺ GIAO DỊCH GẦN ĐÂY
                  if (_dangTai)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: MauSac.chuDao)))
                  else if (_danhSachGiaoDich.isEmpty)
                    _taoEmptyStateChuaCoGiaoDich()
                  else
                    Column(
                      children: _danhSachGiaoDich.take(5).map((gd) {
                        final isThu = gd.loaiGiaoDich == 'thu_nhap';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: KhoangCach.lToanBoChuan,
                          decoration: BoxDecoration(
                            color: MauSac.nenThe,
                            borderRadius: BoGoc.borderVua,
                            border: Border.all(color: MauSac.duongVienNhat),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: MauSac.nenNoi,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _danhSachDanhMuc.layIcon(gd.danhMucId, isThu: isThu),
                                  color: isThu ? MauSac.thuNhap : MauSac.phu,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _danhSachDanhMuc.layTen(gd.danhMucId, isThu: isThu),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: MauSac.chuChinh,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      gd.ghiChu != null && gd.ghiChu!.trim().isNotEmpty
                                          ? gd.ghiChu!
                                          : (isThu ? 'Ghi nhận thu nhập' : 'Ghi nhận chi tiêu'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: MauSac.chuPhu, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isThu ? "+" : "-"}${_dinhDangTien(gd.soTien)}',
                                    style: TextStyle(
                                      color: isThu ? MauSac.thuNhap : MauSac.chuChinh,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isThu ? 'Đã nhận' : 'Đã trừ',
                                    style: const TextStyle(color: MauSac.chuPhu, fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: KhoangCach.lon),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Khung hiển thị khi không có giao dịch nào trong tháng hiện tại
  Widget _taoEmptyStateChuaCoGiaoDich() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: MauSac.nenThe,
        borderRadius: BoGoc.borderVua,
        border: Border.all(color: MauSac.duongVienNhat),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: MauSac.nenNoi,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: MauSac.chuPhu,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Chưa có giao dịch',
            style: TextStyle(
              color: MauSac.chuChinh,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chưa có khoản thu chi nào trong tháng này.\nHãy nhấn nút (+) bên dưới để thêm ghi chép mới!',
            textAlign: TextAlign.center,
            style: TextStyle(color: MauSac.chuPhu, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
