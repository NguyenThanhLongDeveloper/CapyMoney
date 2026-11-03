import 'package:flutter/material.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../../giao_dien/chuan_thiet_ke/hinh_anh.dart';
import '../../giao_dien/chuan_thiet_ke/dap_ung.dart';
import '../../mo_hinh/tai_khoan_ngan_hang_model.dart';
import '../../mo_hinh/danh_muc_model.dart';
import '../../mo_hinh/danh_muc_ngan_sach_model.dart';
import '../../mo_hinh/quy_tiet_kiem_model.dart';
import '../../mo_hinh/lich_su_quy_model.dart';
import '../../mo_hinh/giao_dich_hop_nhat_model.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import '../giao_dich/man_hinh_danh_sach_giao_dich.dart';
import '../giao_dich/man_hinh_chi_tiet_giao_dich.dart';

/// Tab 1: Màn Hình Tổng Quan Tài Chính (Dashboard Screen)
/// 
/// Khớp 100% giao diện Kinetic Neo-Fintech Dark Mode:
/// Card 1: Tổng tài sản khả dụng + Carousel Lướt Trái/Phải xem các ví ngân hàng, 👁 Ẩn/Hiện số tiền,
/// Card 2: Thu nhập tháng & Chi tiêu tháng thực tế (không dính giao dịch nạp/rút quỹ),
/// Card 3: Biểu đồ thanh Chi tiêu tuần này (T2 -> CN),
/// và Danh sách Giao dịch gần đây hợp nhất (Hợp nhất Thu chi + Nạp/Rút quỹ).
class TabTongQuan extends StatefulWidget {
  const TabTongQuan({super.key});

  @override
  State<TabTongQuan> createState() => _TabTongQuanState();
}

class _TabTongQuanState extends State<TabTongQuan> {
  /// Cờ ẩn/hiện số tiền tài sản
  bool _anSoTien = false;

  /// Bộ điều khiển PageView lướt thẻ tài sản
  final PageController _cardPageController = PageController();

  /// Index thẻ tài khoản đang xem (0: Ví 1, 1: Ví 2...)
  int _trangThoatHienTai = 0;

  /// Index ngày đang chọn trong tuần (0: T2, 1: T3, ... 4: T6, 5: T7, 6: CN)
  int _ngayChonIndex = 4; // Mặc định T6

  /// Trạng thái đang tải từ CSDL
  bool _dangTai = true;

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

  /// Danh sách danh mục thu chi
  List<DanhMucModel> _danhSachDanhMuc = [];

  /// Danh sách danh mục ngân sách / quỹ
  List<DanhMucNganSachModel> _danhSachDanhMucNganSach = [];

  /// Danh sách giao dịch hợp nhất trên Timeline
  List<GiaoDichHopNhatModel> _danhSachGiaoDichHopNhat = [];

  @override
  void initState() {
    super.initState();
    final weekday = DateTime.now().weekday; // 1: T2 -> 7: CN
    _ngayChonIndex = (weekday - 1) % 7;
    _loadDuLieuDashboard();
  }

  @override
  void dispose() {
    _cardPageController.dispose();
    super.dispose();
  }

  /// Nạp dữ liệu thực tế từ CSDL Supabase
  Future<void> _loadDuLieuDashboard() async {
    setState(() => _dangTai = true);
    try {
      final viList = await DichVuSupabase.layDanhSachTaiKhoan();
      final giaoDichList = await DichVuSupabase.layDanhSachGiaoDich();
      final danhMucList = await DichVuSupabase.layDanhSachDanhMuc();
      final danhMucNganSachList = await DichVuSupabase.layDanhSachDanhMucNganSach();
      final quyList = await DichVuSupabase.layDanhSachQuy();

      // Nạp lịch sử nạp rút quỹ từng quỹ
      final List<LichSuQuyModel> lichSuQuyTatCa = [];
      for (var q in quyList) {
        final ls = await DichVuSupabase.layDanhSachLichSuQuy(quyId: q.id);
        lichSuQuyTatCa.addAll(ls);
      }

      if (mounted) {
        // Sắp xếp ví có laNhanChinh == true đứng ĐẦU TIÊN (Index 0)
        viList.sort((a, b) => (b.laNhanChinh ? 1 : 0) - (a.laNhanChinh ? 1 : 0));

        setState(() {
          _danhSachVi = viList;
          _danhSachDanhMuc = danhMucList;
          _danhSachDanhMucNganSach = danhMucNganSachList;

          // 1. Tính thu nhập và chi tiêu tháng này từ giao_dich
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

          // 2. Tính chi tiêu tuần này (Từ Thứ 2 đến Chủ nhật của tuần hiện tại)
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

          // 3. Hợp nhất Dòng thời gian giao dịch (Thu/Chi + Nạp/Rút quỹ thuộc tháng hiện tại)
          final List<GiaoDichHopNhatModel> listHopNhat = [];

          // Thêm các bản ghi thu/chi từ giao_dich
          for (var gd in giaoDichList) {
            if (gd.ngayGiaoDich.month == now.month && gd.ngayGiaoDich.year == now.year) {
              listHopNhat.add(GiaoDichHopNhatModel.fromGiaoDich(gd));
            }
          }

          // Thêm các bản ghi nạp/rút quỹ từ lich_su_quy
          for (var ls in lichSuQuyTatCa) {
            final dtLs = ls.taoLuc ?? DateTime.now();
            if (dtLs.month == now.month && dtLs.year == now.year) {
              final quyMatch = quyList.timTheoId(ls.quyId);
              final String dmNganSachId = quyMatch?.danhMucNganSachId ?? '';
              final String tenQuyStr = quyMatch?.tenQuy ?? 'Quỹ tích lũy';

              listHopNhat.add(
                GiaoDichHopNhatModel.fromLichSuQuy(
                  ls: ls,
                  danhMucNganSachId: dmNganSachId,
                  tenQuy: tenQuyStr,
                ),
              );
            }
          }

          // Sắp xếp thời gian giảm dần
          listHopNhat.sort((a, b) => b.thoiGian.compareTo(a.thoiGian));
          _danhSachGiaoDichHopNhat = listHopNhat;

          _dangTai = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi nạp Dashboard: $e');
      if (mounted) setState(() => _dangTai = false);
    }
  }

  /// Tính tổng tài sản khả dụng cộng tất cả các ví
  double get _tongTaiSanTatCa {
    double sum = 0.0;
    for (var v in _danhSachVi) {
      sum += v.soDu;
    }
    return sum;
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

  /// Tên ngày đầy đủ kèm ngày tháng năm chính xác
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

                  // DÒNG TỔNG TÀI SẢN TẤT CẢ VÍ PHÍA TRÊN CARD
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(BieuTuong.chamTron, color: MauSac.chuDao, size: 8),
                        const SizedBox(width: 6),
                        const Text(
                          'TỔNG TÀI SẢN TẤT CẢ VÍ: ',
                          style: TextStyle(
                            color: MauSac.chuPhu,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          _dinhDangTien(_tongTaiSanTatCa),
                          style: const TextStyle(
                            color: MauSac.chuDao,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // CARD 1: THẺ NGÂN HÀNG KINETIC LƯỚT TRÁI/PHẢI (MOCKUP EXACT)
                  Container(
                    width: double.infinity,
                    height: 205,
                    decoration: BoxDecoration(
                      color: MauSac.nenThe,
                      borderRadius: BoGoc.borderLon,
                      border: Border.all(color: MauSac.duongVienNhat),
                      boxShadow: [
                        BoxShadow(
                          color: MauSac.chuDao.withValues(alpha: 0.06),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: PageView.builder(
                      controller: _cardPageController,
                      onPageChanged: (idx) => setState(() => _trangThoatHienTai = idx),
                      itemCount: _danhSachVi.isNotEmpty ? _danhSachVi.length : 1,
                      itemBuilder: (context, index) {
                        if (_danhSachVi.isEmpty) {
                          return Padding(
                            padding: KhoangCach.lToanBoLon,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD4AF37),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    const Text('CAPYPAY', style: TextStyle(color: MauSac.chuDao, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const Text('Chưa liên kết tài khoản nào', style: TextStyle(color: MauSac.chuPhu)),
                              ],
                            ),
                          );
                        }

                        final vi = _danhSachVi[index];
                        final String soCuoi = vi.soTaiKhoan.length >= 4
                            ? vi.soTaiKhoan.substring(vi.soTaiKhoan.length - 4)
                            : vi.soTaiKhoan;
                        final String tenChuTaiKhoan = vi.tenChuTaiKhoan.isNotEmpty
                            ? vi.tenChuTaiKhoan.toUpperCase()
                            : 'CHỦ TÀI KHOẢN';

                        return Padding(
                          padding: KhoangCach.lToanBoLon,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // HÀNG 1: EMV CHIP VÀNG + CONTACTLESS ICON TRÊN BÊN TRÁI & TÊN NGÂN HÀNG BÊN PHẢI
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      // Thẻ Chip EMV Mạ Vàng
                                      Container(
                                        width: 38,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFF7D070), Color(0xFFC59B27)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFF9A7B1C), width: 0.8),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 18,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: const Color(0xFF705608), width: 0.8),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.wifi_rounded, color: MauSac.chuPhu, size: 20),
                                    ],
                                  ),
                                  Text(
                                    vi.tenNganHang.toUpperCase(),
                                    style: const TextStyle(
                                      color: MauSac.chuDao,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),

                              // HÀNG 2: TỔNG TÀI SẢN KHẢ DỤNG + SỐ TIỀN CỠ LỚN VÀ NÚT 👁 BÊN PHẢI
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TỔNG TÀI SẢN KHẢ DỤNG',
                                    style: TextStyle(
                                      color: MauSac.chuPhu,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            _dinhDangTien(vi.soDu),
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              color: MauSac.chuChinh,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () => setState(() => _anSoTien = !_anSoTien),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: MauSac.nenNoi.withValues(alpha: 0.8),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: MauSac.duongVienNhat),
                                          ),
                                          child: Icon(
                                            _anSoTien ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            color: MauSac.chuPhu,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // HÀNG 3: MÃ SỐ TÀI KHOẢN MASKED + HỌ TÊN CHỦ THẺ & NHÃN CapyPay BÊN PHẢI
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '••••   ••••   ••••   $soCuoi',
                                    style: const TextStyle(
                                      color: MauSac.chuChinh,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          tenChuTaiKhoan,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: MauSac.chuChinh,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        'CapyPay',
                                        style: TextStyle(
                                          color: MauSac.chuChinh,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          fontStyle: FontStyle.italic,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // CỤM CHẤM TRƯỢT CHỈ BÁO THẺ VÍ CĂN GIỮA BÊN DƯỚI CARD
                  if (_danhSachVi.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _danhSachVi.length,
                          (dotIdx) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _trangThoatHienTai == dotIdx ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _trangThoatHienTai == dotIdx ? MauSac.chuDao : MauSac.nenNoi,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
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
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: MauSac.nenNoi,
                            borderRadius: BoGoc.borderVua,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Đang xem: ${_layTenNgayFull(_ngayChonIndex)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: MauSac.chuChinh, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
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

                  // SECTION 4: GIAO DỊCH GẦN ĐÂY (TIMELINE HỢP NHẤT)
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

                  // DANH SÁCH CÁC THẺ GIAO DỊCH HỢP NHẤT GẦN ĐÂY
                  if (_dangTai)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: MauSac.chuDao)))
                  else if (_danhSachGiaoDichHopNhat.isEmpty)
                    _taoEmptyStateChuaCoGiaoDich()
                  else
                    Column(
                      children: _danhSachGiaoDichHopNhat.take(5).map((item) {
                        return _taoItemGiaoDichHopNhat(item);
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

  /// Dựng Item Giao dịch Hợp nhất (Thu chi hoặc Nạp/Rút quỹ)
  Widget _taoItemGiaoDichHopNhat(GiaoDichHopNhatModel item) {
    IconData iconData;
    Color iconColor;
    String tieuDeStr;
    String loaiBadgeText;
    Color amountColor;
    String amountPrefix;

    if (item.isBienDongQuy) {
      // Biến động nạp / rút quỹ
      iconData = _danhSachDanhMucNganSach.layIcon(item.danhMucId);
      iconColor = _danhSachDanhMucNganSach.layMauSac(item.danhMucId);
      tieuDeStr = item.tieuDe;
      loaiBadgeText = item.isNapQuy ? 'Nạp quỹ' : 'Rút quỹ';
      amountColor = MauSac.chuDao;
      amountPrefix = item.isNapQuy ? '-' : '+';
    } else {
      // Giao dịch thu nhập / chi tiêu thực tế
      iconData = _danhSachDanhMuc.layIcon(item.danhMucId, isThu: item.isThuNhap);
      iconColor = item.isThuNhap ? MauSac.thuNhap : MauSac.phu;
      tieuDeStr = _danhSachDanhMuc.layTen(item.danhMucId, isThu: item.isThuNhap);
      loaiBadgeText = item.isThuNhap ? 'Đã nhận' : 'Đã trừ';
      amountColor = item.isThuNhap ? MauSac.thuNhap : MauSac.chuChinh;
      amountPrefix = item.isThuNhap ? '+' : '-';
    }

    return GestureDetector(
      onTap: () async {
        if (item.giaoDichGoc != null) {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManHinhChiTietGiaoDich(giaoDich: item.giaoDichGoc!),
            ),
          );
          if (res == true) {
            _loadDuLieuDashboard();
          }
        }
      },
      child: Container(
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
                iconData,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tieuDeStr,
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
                    item.ghiChu,
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
                  '$amountPrefix${_dinhDangTien(item.soTien)}',
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.isBienDongQuy
                        ? MauSac.chuDao.withValues(alpha: 0.15)
                        : MauSac.nenNoi,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    loaiBadgeText,
                    style: TextStyle(
                      color: item.isBienDongQuy ? MauSac.chuDao : MauSac.chuPhu,
                      fontSize: 9,
                      fontWeight: item.isBienDongQuy ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
