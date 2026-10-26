import 'dart:math';
import 'package:flutter/material.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../../giao_dien/chuan_thiet_ke/hinh_anh.dart';
import '../../giao_dien/chuan_thiet_ke/dap_ung.dart';
import '../../giao_dien/bottom_sheet/bs_loc_thoi_gian.dart';
import '../../mo_hinh/giao_dich_model.dart';
import '../../mo_hinh/danh_muc_model.dart';
import '../../dich_vu/dich_vu_supabase.dart';

/// Item thống kê chi tiêu theo danh mục
class MucCoCauChiTieu {
  final String danhMucId;
  final String tenDanhMuc;
  final double soTien;
  final int soGiaoDich;
  final double phanTram;
  final Color mauSac;

  MucCoCauChiTieu({
    required this.danhMucId,
    required this.tenDanhMuc,
    required this.soTien,
    required this.soGiaoDich,
    required this.phanTram,
    required this.mauSac,
  });
}

/// Tab 3: Màn Hình Báo Cáo & Phân Tích Tài Chính (Reports Screen)
/// 
/// Thiết kế chuẩn Kinetic Neo-Fintech Dark Mode khớp 100% UI mockup:
/// Thẻ Tổng chi tiêu tháng + % so sánh tháng trước, Biểu đồ Donut Cơ cấu chi tiêu theo danh mục,
/// Biểu đồ sóng Xu hướng dòng tiền (Thu vs Chi 4 tuần), và Top 3 khoản chi lớn nhất.
class TabBaoCao extends StatefulWidget {
  const TabBaoCao({super.key});

  @override
  State<TabBaoCao> createState() => _TabBaoCaoState();
}

class _TabBaoCaoState extends State<TabBaoCao> {
  /// Ngày bắt đầu và kết thúc khoảng thời gian chọn lọc
  late DateTime _ngayBatDauChon;
  late DateTime _ngayKetThucChon;

  /// Nhãn hiển thị thời gian chọn (Mặc định 'T10, 2026')
  late String _nhanThoiGianHienThi;

  /// Trạng thái đang tải dữ liệu CSDL
  bool _dangTai = true;

  /// Danh sách toàn bộ giao dịch từ Supabase
  List<GiaoDichModel> _tatCaGiaoDich = [];

  /// Danh sách danh mục từ Supabase
  List<DanhMucModel> _danhSachDanhMuc = [];

  /// Bảng màu dành cho các phân khúc danh mục chi tiêu
  final List<Color> _bangMauDanhMuc = const [
    Color(0xFF00F59B), // Neon Mint
    Color(0xFF38BDF8), // Cyan Blue
    Color(0xFFA855F7), // Purple
    Color(0xFFFB923C), // Orange
    Color(0xFF94A3B8), // Slate Grey
    Color(0xFFFB7185), // Coral Red
    Color(0xFFFBBF24), // Amber
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _ngayBatDauChon = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    _ngayKetThucChon = DateTime(now.year, now.month, lastDay, 23, 59, 59);
    _nhanThoiGianHienThi = 'T${now.month}, ${now.year}';
    _loadDuLieu();
  }

  /// Nạp dữ liệu giao dịch và danh mục từ Supabase
  Future<void> _loadDuLieu() async {
    setState(() => _dangTai = true);
    try {
      final giaoDichList = await DichVuSupabase.layDanhSachGiaoDich();
      final danhMucList = await DichVuSupabase.layDanhSachDanhMuc();

      if (mounted) {
        setState(() {
          _tatCaGiaoDich = giaoDichList;
          _danhSachDanhMuc = danhMucList;
          _dangTai = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi nạp Báo cáo: $e');
      if (mounted) setState(() => _dangTai = false);
    }
  }

  /// Mở Bảng trượt lọc thời gian (BsLocThoiGian)
  Future<void> _moLocThoiGian() async {
    final result = await BsLocThoiGian.hienThi(
      context,
      loaiLocBanDau: LoaiLocThoiGian.thangNay,
      khoangNgayTuyChonBanDau: DateTimeRange(start: _ngayBatDauChon, end: _ngayKetThucChon),
    );

    if (result != null) {
      final DateTime? start = result['ngayBatDau'] as DateTime?;
      final DateTime? end = result['ngayKetThuc'] as DateTime?;
      final String? label = result['tenLoaiLoc'] as String?;

      if (start != null && end != null && label != null) {
        setState(() {
          _ngayBatDauChon = start;
          _ngayKetThucChon = end;
          _nhanThoiGianHienThi = label;
        });
      }
    }
  }

  /// Định dạng tiền VND đầy đủ
  String _dinhDangTien(double amount) {
    final String numStr = amount.abs().toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formatted = numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return '$formatted đ';
  }

  /// Định dạng tiền VND viết tắt tâm Donut
  String _dinhDangTienDonutCenter(double amount) {
    if (amount >= 1000000) {
      final double valM = amount / 1000000;
      return '${valM.toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      final double valK = amount / 1000;
      return '${valK.toStringAsFixed(0)}K';
    }
    return amount.toInt().toString();
  }

  /// Lấy tên danh mục từ ID hoặc tên mặc định (Đồng bộ chuẩn TabTổngQuan)
  String _layTenDanhMuc(String? danhMucId, [bool isThu = false]) {
    if (danhMucId != null && danhMucId.isNotEmpty) {
      final dmList = _danhSachDanhMuc.where((d) => d.id == danhMucId).toList();
      if (dmList.isNotEmpty) {
        return dmList.first.tenDanhMuc;
      }
    }
    return isThu ? 'Khoản thu nhập' : 'Khoản chi tiêu';
  }

  /// Lấy Icon đại diện gọn gàng (Đồng bộ chuẩn TabTổngQuan)
  IconData _layIconDanhMuc(String? danhMucId, bool isThu) {
    if (danhMucId != null && danhMucId.isNotEmpty) {
      final dmList = _danhSachDanhMuc.where((d) => d.id == danhMucId).toList();
      if (dmList.isNotEmpty) {
        return isThu ? Icons.account_balance_rounded : Icons.shopping_cart_rounded;
      }
    }
    return isThu ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Lọc giao dịch trong khoảng thời gian được chọn
    final List<GiaoDichModel> giaoDichThangNay = _tatCaGiaoDich.where((gd) {
      final dt = gd.ngayGiaoDich;
      return dt.isAfter(_ngayBatDauChon.subtract(const Duration(seconds: 1))) &&
          dt.isBefore(_ngayKetThucChon.add(const Duration(seconds: 1)));
    }).toList();

    // 2. Lọc giao dịch kỳ trước cùng độ dài thời gian để so sánh %
    final duration = _ngayKetThucChon.difference(_ngayBatDauChon);
    final dtKyTruocStart = _ngayBatDauChon.subtract(duration);
    final dtKyTruocEnd = _ngayBatDauChon.subtract(const Duration(seconds: 1));

    final List<GiaoDichModel> giaoDichThangTruoc = _tatCaGiaoDich.where((gd) {
      final dt = gd.ngayGiaoDich;
      return dt.isAfter(dtKyTruocStart.subtract(const Duration(seconds: 1))) &&
          dt.isBefore(dtKyTruocEnd.add(const Duration(seconds: 1)));
    }).toList();

    // Tính tổng chi tháng này & tháng trước
    double tongChiThangNay = 0;
    for (var gd in giaoDichThangNay) {
      if (gd.loaiGiaoDich == 'chi_tieu') tongChiThangNay += gd.soTien;
    }

    double tongChiThangTruoc = 0;
    for (var gd in giaoDichThangTruoc) {
      if (gd.loaiGiaoDich == 'chi_tieu') tongChiThangTruoc += gd.soTien;
    }

    // Tính % chênh lệch so với kỳ trước
    double phanTramSoThangTruoc = 0;
    if (tongChiThangTruoc > 0) {
      phanTramSoThangTruoc = ((tongChiThangNay - tongChiThangTruoc) / tongChiThangTruoc) * 100;
    }

    // 3. Tính Cơ cấu chi tiêu theo Danh mục
    final Map<String, double> mapChiTieuDanhMuc = {};
    final Map<String, int> mapSoGiaoDichDanhMuc = {};

    for (var gd in giaoDichThangNay) {
      if (gd.loaiGiaoDich == 'chi_tieu') {
        final key = gd.danhMucId ?? 'khac';
        mapChiTieuDanhMuc[key] = (mapChiTieuDanhMuc[key] ?? 0) + gd.soTien;
        mapSoGiaoDichDanhMuc[key] = (mapSoGiaoDichDanhMuc[key] ?? 0) + 1;
      }
    }

    final List<MucCoCauChiTieu> dsCoCau = [];
    int colorIdx = 0;
    mapChiTieuDanhMuc.forEach((dmId, sumTien) {
      final double percent = tongChiThangNay > 0 ? (sumTien / tongChiThangNay) * 100 : 0;
      dsCoCau.add(MucCoCauChiTieu(
        danhMucId: dmId,
        tenDanhMuc: _layTenDanhMuc(dmId),
        soTien: sumTien,
        soGiaoDich: mapSoGiaoDichDanhMuc[dmId] ?? 0,
        phanTram: percent,
        mauSac: _bangMauDanhMuc[colorIdx % _bangMauDanhMuc.length],
      ));
      colorIdx++;
    });

    dsCoCau.sort((a, b) => b.soTien.compareTo(a.soTien));

    // 4. Tính Xu hướng Dòng tiền 4 Tuần (Thu vs Chi)
    final List<double> thu4Tuan = [0, 0, 0, 0];
    final List<double> chi4Tuan = [0, 0, 0, 0];

    for (var gd in giaoDichThangNay) {
      final day = gd.ngayGiaoDich.day;
      int weekIdx = (day - 1) ~/ 7;
      if (weekIdx > 3) weekIdx = 3;

      if (gd.loaiGiaoDich == 'thu_nhap') {
        thu4Tuan[weekIdx] += gd.soTien;
      } else {
        chi4Tuan[weekIdx] += gd.soTien;
      }
    }

    // 5. Lấy Top 3 khoản chi lớn nhất
    final List<GiaoDichModel> top3KhoanChi = giaoDichThangNay
        .where((gd) => gd.loaiGiaoDich == 'chi_tieu')
        .toList()
      ..sort((a, b) => b.soTien.compareTo(a.soTien));

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
                  'Báo cáo',
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
            onRefresh: _loadDuLieu,
            color: MauSac.chuDao,
            backgroundColor: MauSac.nenThe,
            child: SingleChildScrollView(
              padding: KhoangCach.lNgangLon,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: KhoangCach.nho),

                  // HEADER PAGE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Báo cáo',
                        style: TextStyle(
                          color: MauSac.chuChinh,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: _moLocThoiGian,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: MauSac.nenNoi,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: MauSac.duongVienNhat),
                          ),
                          child: Row(
                            children: [
                              const Icon(BieuTuong.lichThang, color: MauSac.chuDao, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                _nhanThoiGianHienThi,
                                style: const TextStyle(
                                  color: MauSac.chuChinh,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 1: CARD TỔNG CHI TIÊU THÁNG + % SO VỚI KỲ TRƯỚC
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
                        Text(
                          'TỔNG CHI TIÊU $_nhanThoiGianHienThi'.toUpperCase(),
                          style: const TextStyle(
                            color: MauSac.chuPhu,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),

                        const SizedBox(height: 8),

                        FittedBox(
                          child: Text(
                            _dinhDangTien(tongChiThangNay),
                            style: const TextStyle(
                              color: MauSac.chuChinh,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: phanTramSoThangTruoc <= 0
                                ? MauSac.chuDao.withValues(alpha: 0.15)
                                : MauSac.chiTieu.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                phanTramSoThangTruoc <= 0
                                    ? BieuTuong.xuHuongGiam
                                    : BieuTuong.xuHuongTang,
                                color: phanTramSoThangTruoc <= 0 ? MauSac.chuDao : MauSac.chiTieu,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${phanTramSoThangTruoc <= 0 ? "" : "+"}${phanTramSoThangTruoc.toStringAsFixed(0)}% so với kỳ trước',
                                style: TextStyle(
                                  color: phanTramSoThangTruoc <= 0 ? MauSac.chuDao : MauSac.chiTieu,
                                  fontSize: 11,
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

                  // SECTION 2: CƠ CẤU CHI TIÊU (DONUT CHART)
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Cơ cấu chi tiêu',
                              style: TextStyle(
                                color: MauSac.chuChinh,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${dsCoCau.length} danh mục',
                              style: const TextStyle(
                                color: MauSac.chuPhu,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: KhoangCach.lon),

                        Center(
                          child: SizedBox(
                            width: 180,
                            height: 180,
                            child: CustomPaint(
                              painter: VongTronCoCauPainter(dsCoCau: dsCoCau),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'TỔNG CỘNG',
                                      style: TextStyle(
                                        color: MauSac.chuPhu,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _dinhDangTienDonutCenter(tongChiThangNay),
                                      style: const TextStyle(
                                        color: MauSac.chuChinh,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'VND',
                                      style: TextStyle(
                                        color: MauSac.chuDao,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: KhoangCach.lon),

                        if (dsCoCau.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Chưa có chi tiêu trong khoảng thời gian này', style: TextStyle(color: MauSac.chuPhu, fontSize: 12)),
                            ),
                          )
                        else
                          Column(
                            children: dsCoCau.map((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: item.mauSac,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.tenDanhMuc,
                                              style: const TextStyle(
                                                color: MauSac.chuChinh,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${item.phanTram.toStringAsFixed(0)}% tổng chi',
                                              style: const TextStyle(
                                                color: MauSac.chuPhu,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _dinhDangTien(item.soTien),
                                          style: const TextStyle(
                                            color: MauSac.chuChinh,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item.soGiaoDich} giao dịch',
                                          style: const TextStyle(
                                            color: MauSac.chuPhu,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 3: XU HƯỚNG DÒNG TIỀN (TREND CHART)
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Xu hướng dòng tiền',
                                  style: TextStyle(
                                    color: MauSac.chuChinh,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Thu nhập vs Chi tiêu theo tuần',
                                  style: TextStyle(
                                    color: MauSac.chuPhu,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: const [
                                Icon(BieuTuong.chamTron, color: MauSac.thuNhap, size: 8),
                                SizedBox(width: 4),
                                Text('Thu', style: TextStyle(color: MauSac.chuPhu, fontSize: 11)),
                                SizedBox(width: 10),
                                Icon(BieuTuong.chamTron, color: MauSac.chiTieu, size: 8),
                                SizedBox(width: 4),
                                Text('Chi', style: TextStyle(color: MauSac.chuPhu, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: KhoangCach.lon),

                        SizedBox(
                          height: 140,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: BieuDoDuyetSongTrendPainter(
                              thuList: thu4Tuan,
                              chiList: chi4Tuan,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Tuần 1', style: TextStyle(color: MauSac.chuPhu, fontSize: 11)),
                            Text('Tuần 2', style: TextStyle(color: MauSac.chuPhu, fontSize: 11)),
                            Text('Tuần 3', style: TextStyle(color: MauSac.chuPhu, fontSize: 11)),
                            Text('Tuần 4', style: TextStyle(color: MauSac.chuPhu, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 4: TOP 3 KHOẢN CHI LỚN NHẤT
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Top 3 khoản chi lớn nhất',
                              style: TextStyle(
                                color: MauSac.chuChinh,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(BieuTuong.baoCao, color: MauSac.chuPhu, size: 18),
                          ],
                        ),

                        const SizedBox(height: KhoangCach.vua),

                        if (_dangTai)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator(color: MauSac.chuDao)),
                          )
                        else if (top3KhoanChi.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: Text(
                                'Chưa có khoản chi nào trong khoảng thời gian này',
                                style: TextStyle(color: MauSac.chuPhu, fontSize: 12),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: top3KhoanChi.take(3).map((gd) {
                              final tenDM = _layTenDanhMuc(gd.danhMucId);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: KhoangCach.lToanBoChuan,
                                decoration: BoxDecoration(
                                  color: MauSac.nenNoi,
                                  borderRadius: BoGoc.borderVua,
                                  border: Border.all(color: MauSac.duongVienNhat),
                                ),
                                child: Row(
                                  children: [
                                    // Icon Danh mục (Đồng bộ chuẩn TabTổngQuan)
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: MauSac.nenThe,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _layIconDanhMuc(gd.danhMucId, false),
                                        color: MauSac.chiTieu,
                                        size: 20,
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tenDM,
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
                                            '${gd.ngayGiaoDich.day.toString().padLeft(2, '0')}/${gd.ngayGiaoDich.month.toString().padLeft(2, '0')}/${gd.ngayGiaoDich.year} • ${gd.ghiChu != null && gd.ghiChu!.trim().isNotEmpty ? gd.ghiChu! : 'Ghi nhận chi tiêu'}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: MauSac.chuPhu,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    Text(
                                      '-${_dinhDangTien(gd.soTien)}',
                                      style: const TextStyle(
                                        color: MauSac.chiTieu,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
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
      ),
    );
  }
}

/// CustomPainter vẽ Vòng tròn Donut Chart Cơ cấu chi tiêu
class VongTronCoCauPainter extends CustomPainter {
  final List<MucCoCauChiTieu> dsCoCau;

  VongTronCoCauPainter({required this.dsCoCau});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 12;
    const strokeWidth = 16.0;

    final bgPaint = Paint()
      ..color = MauSac.nenNoi
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    if (dsCoCau.isEmpty) return;

    double startAngle = -pi / 2;

    for (var item in dsCoCau) {
      final sweepAngle = (item.phanTram / 100) * 2 * pi;
      if (sweepAngle <= 0) continue;

      final paint = Paint()
        ..color = item.mauSac
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        max(sweepAngle - 0.05, 0.02),
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// CustomPainter vẽ Biểu đồ Sóng Bezier Xu hướng Dòng tiền (Thu vs Chi 4 Tuần)
class BieuDoDuyetSongTrendPainter extends CustomPainter {
  final List<double> thuList;
  final List<double> chiList;

  BieuDoDuyetSongTrendPainter({
    required this.thuList,
    required this.chiList,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (thuList.length < 4 || chiList.length < 4) return;

    final double maxVal = max(
      1.0,
      max(
        thuList.reduce(max),
        chiList.reduce(max),
      ),
    );

    final double stepX = size.width / 3;

    final List<Offset> pointsThu = [];
    for (int i = 0; i < 4; i++) {
      final x = i * stepX;
      final y = size.height - (thuList[i] / maxVal) * (size.height - 20) - 10;
      pointsThu.add(Offset(x, y));
    }

    final List<Offset> pointsChi = [];
    for (int i = 0; i < 4; i++) {
      final x = i * stepX;
      final y = size.height - (chiList[i] / maxVal) * (size.height - 20) - 10;
      pointsChi.add(Offset(x, y));
    }

    _veDuongSongBeizer(canvas, size, pointsThu, MauSac.thuNhap);
    _veDuongSongBeizer(canvas, size, pointsChi, MauSac.chiTieu);
  }

  void _veDuongSongBeizer(Canvas canvas, Size size, List<Offset> points, Color color) {
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlP1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
      final controlP2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);
      path.cubicTo(controlP1.dx, controlP1.dy, controlP2.dx, controlP2.dy, p2.dx, p2.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.25),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawPath(path, strokePaint);

    final dotPaint = Paint()..color = color;
    final dotInnerPaint = Paint()..color = Colors.black;

    for (var pt in points) {
      canvas.drawCircle(pt, 4, dotPaint);
      canvas.drawCircle(pt, 2, dotInnerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}