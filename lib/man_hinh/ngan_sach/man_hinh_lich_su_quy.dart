import 'package:flutter/material.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../../giao_dien/chuan_thiet_ke/dap_ung.dart';
import '../../giao_dien/bottom_sheet/bs_loc_thoi_gian.dart';
import '../../mo_hinh/quy_tiet_kiem_model.dart';
import '../../mo_hinh/lich_su_quy_model.dart';
import '../../mo_hinh/tai_khoan_ngan_hang_model.dart';
import '../../mo_hinh/danh_muc_ngan_sach_model.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import 'man_hinh_tao_quy_tiet_kiem.dart';

/// Màn Hình Lịch Sử Biến Động Quỹ (Savings Fund History Screen)
/// 
/// Thiết kế chuẩn Kinetic Neo-Fintech Dark Mode khớp 100% UI mockup:
/// Thẻ Tổng số dư tích lũy, Đã nạp tháng này vs Đã rút tháng này, Tiến độ năm,
/// Lọc theo loại thao tác (Tất cả, Nạp quỹ, Rút quỹ, Lãi/Thưởng), Nhóm danh sách theo ngày.
class ManHinhLichSuQuy extends StatefulWidget {
  final String? quyIdBanDau;

  const ManHinhLichSuQuy({
    super.key,
    this.quyIdBanDau,
  });

  @override
  State<ManHinhLichSuQuy> createState() => _ManHinhLichSuQuyState();
}

class _ManHinhLichSuQuyState extends State<ManHinhLichSuQuy> {
  /// Quỹ đang được chọn lọc (Null = Tất cả quỹ)
  String? _quyIdLoc;

  /// Tab phân loại thao tác: 'tat_ca', 'nap_tien', 'rut_tien', 'lai_thuong'
  String _tabLoaiThaoTac = 'tat_ca';

  /// Thời gian chọn lọc
  late DateTime _ngayBatDauChon;
  late DateTime _ngayKetThucChon;
  late String _nhanThoiGianHienThi;

  /// Trạng thái đang nạp CSDL
  bool _dangTai = true;

  /// Danh sách các quỹ
  List<QuyTietKiemModel> _danhSachQuy = [];

  /// Danh sách lịch sử nạp rút quỹ
  List<LichSuQuyModel> _danhSachLichSu = [];

  /// Danh sách ví ngân hàng
  List<TaiKhoanNganHangModel> _danhSachVi = [];

  /// Danh sách danh mục ngân sách
  List<DanhMucNganSachModel> _danhSachDanhMucNganSach = [];

  @override
  void initState() {
    super.initState();
    _quyIdLoc = widget.quyIdBanDau;

    final now = DateTime.now();
    _ngayBatDauChon = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    _ngayKetThucChon = DateTime(now.year, now.month, lastDay, 23, 59, 59);
    _nhanThoiGianHienThi = 'T${now.month}, ${now.year}';

    _loadDuLieu();
  }

  /// Nạp danh sách Quỹ, Lịch sử nạp/rút, Ví & Danh mục từ Supabase CSDL
  Future<void> _loadDuLieu() async {
    setState(() => _dangTai = true);
    try {
      final listQuy = await DichVuSupabase.layDanhSachQuy();
      final listLS = await DichVuSupabase.layDanhSachLichSuQuy(quyId: _quyIdLoc);
      final listVi = await DichVuSupabase.layDanhSachTaiKhoan();
      final listDM = await DichVuSupabase.layDanhSachDanhMucNganSach();

      if (mounted) {
        setState(() {
          _danhSachQuy = listQuy;
          _danhSachLichSu = listLS;
          _danhSachVi = listVi;
          _danhSachDanhMucNganSach = listDM;
          _dangTai = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi nạp Lịch sử quỹ: $e');
      if (mounted) setState(() => _dangTai = false);
    }
  }

  /// Mở Bảng trượt Lọc Thời Gian
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

  /// Định dạng tiền VND
  String _dinhDangTien(double amount) {
    final String numStr = amount.abs().toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formatted = numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return '$formatted đ';
  }

  /// Định dạng tiêu đề nhóm ngày (VD: HÔM NAY — 25 THG 10, 2026)
  String _dinhDangTieuDeNgay(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(dt.year, dt.month, dt.day);

    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');

    if (target == today) {
      return 'HÔM NAY — $dd THG $mm, ${dt.year}';
    } else if (target == yesterday) {
      return 'HÔM QUA — $dd THG $mm, ${dt.year}';
    } else {
      return '$dd THG $mm, ${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Tính toán tổng số dư tích lũy & tiến độ
    double tongHienCo = 0;
    double tongMucTieu = 0;
    for (var q in _danhSachQuy) {
      if (_quyIdLoc == null || q.id == _quyIdLoc) {
        tongHienCo += q.soTienHienCo;
        tongMucTieu += q.soTienMucTieu;
      }
    }
    final double phanTramTong = tongMucTieu > 0 ? (tongHienCo / tongMucTieu) * 100 : 0;

    // 2. Lọc danh sách lịch sử theo thời gian và tab loại thao tác
    final filteredLichSu = _danhSachLichSu.where((ls) {
      final dt = ls.taoLuc ?? DateTime.now();
      final withinTime = dt.isAfter(_ngayBatDauChon.subtract(const Duration(seconds: 1))) &&
          dt.isBefore(_ngayKetThucChon.add(const Duration(seconds: 1)));

      if (!withinTime) return false;

      if (_tabLoaiThaoTac == 'nap_tien') {
        return ls.loaiThaoTac == 'nap_tien';
      } else if (_tabLoaiThaoTac == 'rut_tien') {
        return ls.loaiThaoTac == 'rut_tien';
      } else if (_tabLoaiThaoTac == 'lai_thuong') {
        return ls.loaiThaoTac == 'lai_thuong';
      }
      return true;
    }).toList();

    // 3. Tính tổng nạp & rút trong khoảng thời gian chọn
    double tongNapThang = 0;
    double tongRutThang = 0;
    for (var ls in filteredLichSu) {
      if (ls.loaiThaoTac == 'nap_tien' || ls.loaiThaoTac == 'lai_thuong') {
        tongNapThang += ls.soTien;
      } else if (ls.loaiThaoTac == 'rut_tien') {
        tongRutThang += ls.soTien;
      }
    }

    // 4. Nhóm lịch sử theo ngày
    final Map<String, List<LichSuQuyModel>> mapNhomNgay = {};
    for (var ls in filteredLichSu) {
      final dt = ls.taoLuc ?? DateTime.now();
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      if (!mapNhomNgay.containsKey(key)) {
        mapNhomNgay[key] = [];
      }
      mapNhomNgay[key]!.add(ls);
    }

    final quyChonModel = _danhSachQuy.timTheoId(_quyIdLoc);

    return Scaffold(
      backgroundColor: MauSac.nenChinh,
      appBar: AppBar(
        backgroundColor: MauSac.nenChinh,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(BieuTuong.muiTenTrai, color: MauSac.chuChinh, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lịch Sử Biến Động Quỹ',
          style: TextStyle(
            color: MauSac.chuChinh,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
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

                  // TOP FILTER BAR (3 CHIP LỌC QUỸ & THỜI GIAN)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Chip lọc Tất cả quỹ
                        PopupMenuButton<String?>(
                          color: MauSac.nenThe,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BoGoc.borderVua,
                            side: BorderSide(color: MauSac.duongVienNhat),
                          ),
                          onSelected: (val) {
                            setState(() => _quyIdLoc = val);
                            _loadDuLieu();
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem<String?>(
                              value: null,
                              child: Text('Tất cả quỹ (${_danhSachQuy.length})', style: const TextStyle(color: MauSac.chuChinh, fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                            ..._danhSachQuy.map((q) => PopupMenuItem<String?>(
                                  value: q.id,
                                  child: Text(q.tenQuy, style: const TextStyle(color: MauSac.chuChinh, fontSize: 13)),
                                )),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _quyIdLoc == null ? MauSac.chuDao.withValues(alpha: 0.2) : MauSac.nenNoi,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _quyIdLoc == null ? MauSac.chuDao : MauSac.duongVienNhat),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _quyIdLoc == null ? 'Tất cả quỹ (${_danhSachQuy.length})' : (quyChonModel?.tenQuy ?? 'Chọn quỹ'),
                                  style: TextStyle(
                                    color: _quyIdLoc == null ? MauSac.chuDao : MauSac.chuChinh,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(BieuTuong.muiTenXuong, color: _quyIdLoc == null ? MauSac.chuDao : MauSac.chuPhu, size: 16),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Chip Lọc Thời Gian
                        GestureDetector(
                          onTap: _moLocThoiGian,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: MauSac.nenNoi,
                              borderRadius: BorderRadius.circular(14),
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
                                const SizedBox(width: 4),
                                const Icon(BieuTuong.muiTenXuong, color: MauSac.chuPhu, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 1: CARD TỔNG SỐ DƯ TÍCH LŨY
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
                            Row(
                              children: const [
                                Icon(BieuTuong.chamTron, color: MauSac.chuDao, size: 8),
                                SizedBox(width: 6),
                                Text(
                                  'TỔNG SỐ DƯ TÍCH LŨY',
                                  style: TextStyle(
                                    color: MauSac.chuPhu,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: MauSac.chuDao.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${phanTramTong.toStringAsFixed(1)}% Tổng mục tiêu',
                                style: const TextStyle(
                                  color: MauSac.chuDao,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        FittedBox(
                          child: Text(
                            _dinhDangTien(tongHienCo),
                            style: const TextStyle(
                              color: MauSac.chuChinh,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Hàng 2 Thẻ Nhỏ (Đã nạp tháng này vs Đã rút tháng này)
                        Row(
                          children: [
                            // Thẻ Nạp
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: MauSac.nenNoi,
                                  borderRadius: BoGoc.borderVua,
                                  border: Border.all(color: MauSac.duongVienNhat),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(BieuTuong.xuHuongTang, color: MauSac.thuNhap, size: 14),
                                        SizedBox(width: 4),
                                        Text('Đã nạp tháng này', style: TextStyle(color: MauSac.chuPhu, fontSize: 10)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    FittedBox(
                                      child: Text(
                                        '+${_dinhDangTien(tongNapThang)}',
                                        style: const TextStyle(color: MauSac.thuNhap, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Thẻ Rút
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: MauSac.nenNoi,
                                  borderRadius: BoGoc.borderVua,
                                  border: Border.all(color: MauSac.duongVienNhat),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(BieuTuong.xuHuongGiam, color: MauSac.chiTieu, size: 14),
                                        SizedBox(width: 4),
                                        Text('Đã rút tháng này', style: TextStyle(color: MauSac.chuPhu, fontSize: 10)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    FittedBox(
                                      child: Text(
                                        '-${_dinhDangTien(tongRutThang)}',
                                        style: const TextStyle(color: MauSac.chiTieu, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Tiến độ mục tiêu năm
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(BieuTuong.coVeDich, color: MauSac.chuDao, size: 12),
                                SizedBox(width: 4),
                                Text('Tiến độ mục tiêu năm:', style: TextStyle(color: MauSac.chuPhu, fontSize: 11)),
                              ],
                            ),
                            Text(
                              '${_dinhDangTien(tongHienCo)} / ${_dinhDangTien(tongMucTieu)}  ${phanTramTong.toStringAsFixed(0)}% hoàn thành',
                              style: const TextStyle(color: MauSac.chuDao, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (phanTramTong / 100).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: MauSac.nenNoi,
                            color: MauSac.chuDao,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 2: SEGMENTED TAB (Tất cả, Nạp quỹ, Rút quỹ)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: MauSac.nenThe,
                      borderRadius: BoGoc.borderTron,
                      border: Border.all(color: MauSac.duongVienNhat),
                    ),
                    child: Row(
                      children: [
                        _taoTabFilter('tat_ca', 'Tất cả'),
                        _taoTabFilter('nap_tien', 'Nạp quỹ'),
                        _taoTabFilter('rut_tien', 'Rút quỹ'),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 3: DANH SÁCH LỊCH SỬ BIẾN ĐỘNG QUỸ
                  if (_dangTai)
                    const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(color: MauSac.chuDao)))
                  else if (mapNhomNgay.isEmpty)
                    _taoEmptyStateLichSu()
                  else
                    Column(
                      children: mapNhomNgay.entries.map((entry) {
                        final listInDay = entry.value;
                        final firstDt = listInDay.first.taoLuc ?? DateTime.now();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Nhóm Ngày
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(BieuTuong.chamTron, color: MauSac.chiTieu, size: 6),
                                      const SizedBox(width: 6),
                                      Text(
                                        _dinhDangTieuDeNgay(firstDt),
                                        style: const TextStyle(
                                          color: MauSac.chuPhu,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${listInDay.length} giao dịch',
                                    style: const TextStyle(color: MauSac.chuPhu, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),

                            // Danh sách Item trong ngày
                            Column(
                              children: listInDay.map((ls) {
                                final quyModel = _danhSachQuy.timTheoId(ls.quyId);
                                final tkModel = _danhSachVi.where((v) => v.id == ls.taiKhoanId).firstOrNull;
                                final bool isNap = ls.loaiThaoTac == 'nap_tien' || ls.loaiThaoTac == 'lai_thuong';

                                final String tenQuyStr = quyModel?.tenQuy ?? 'Quỹ tiết kiệm';
                                final IconData iconQuy = _danhSachDanhMucNganSach.layIcon(quyModel?.danhMucNganSachId);
                                final Color colorQuy = _danhSachDanhMucNganSach.layMauSac(quyModel?.danhMucNganSachId);

                                final dt = ls.taoLuc ?? DateTime.now();
                                final String timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

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
                                      // Icon Quỹ (Luôn hiển thị biểu tượng chuẩn của Danh mục Ngân sách)
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: colorQuy.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          iconQuy,
                                          color: colorQuy,
                                          size: 20,
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // Thông tin chi tiết
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    isNap ? 'Nạp $tenQuyStr' : 'Rút $tenQuyStr',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: MauSac.chuChinh,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: MauSac.nenNoi,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    timeStr,
                                                    style: const TextStyle(color: MauSac.chuPhu, fontSize: 9),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 2),

                                            Text(
                                              ls.lyDo != null && ls.lyDo!.isNotEmpty ? ls.lyDo! : (isNap ? 'Nạp tiền tích lũy' : 'Rút tiền khỏi quỹ'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: MauSac.chuPhu, fontSize: 11),
                                            ),

                                            const SizedBox(height: 4),

                                            Row(
                                              children: [
                                                const Icon(BieuTuong.nganHang, color: MauSac.chuPhu, size: 11),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    tkModel != null ? '${tkModel.tenNganHang} •• ${tkModel.soTaiKhoan.length >= 4 ? tkModel.soTaiKhoan.substring(tkModel.soTaiKhoan.length - 4) : tkModel.soTaiKhoan}' : 'Ví liên kết',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(color: MauSac.chuPhu, fontSize: 10),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      // Cột số tiền & Badge
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${isNap ? '+' : '-'}${_dinhDangTien(ls.soTien)}',
                                            style: TextStyle(
                                              color: isNap ? MauSac.thuNhap : MauSac.chiTieu,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (isNap ? MauSac.thuNhap : MauSac.chiTieu).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isNap ? 'Đã nạp' : 'Đã rút',
                                              style: TextStyle(
                                                color: isNap ? MauSac.thuNhap : MauSac.chiTieu,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
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
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 4: NÚT CTA "+ TẠO KHOẢN TÍCH KIỆM"
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManHinhTaoQuyTietKiem(),
                          ),
                        );
                        if (res == true) {
                          _loadDuLieu();
                        }
                      },
                      icon: const Icon(BieuTuong.themGiaoDich, color: Colors.black, size: 20),
                      label: const FittedBox(
                        child: Text(
                          'Tạo khoản tích kiệm',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MauSac.chuDao,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BoGoc.borderTron),
                      ),
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

  /// Tab Filter Segmented Item
  Widget _taoTabFilter(String key, String nhan) {
    final bool isSelected = _tabLoaiThaoTac == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabLoaiThaoTac = key),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? MauSac.nenNoi : Colors.transparent,
            borderRadius: BoGoc.borderTron,
            border: isSelected ? Border.all(color: MauSac.duongVienNhat) : null,
          ),
          child: Center(
            child: Text(
              nhan,
              style: TextStyle(
                color: isSelected ? MauSac.chuChinh : MauSac.chuPhu,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Empty State Lịch sử rỗng
  Widget _taoEmptyStateLichSu() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
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
              BieuTuong.lichThang,
              color: MauSac.chuPhu,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Chưa có lịch sử nạp rút quỹ',
            style: TextStyle(
              color: MauSac.chuChinh,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chưa có giao dịch nạp tiền hoặc rút quỹ nào phát sinh trong khoảng thời gian này.',
            textAlign: TextAlign.center,
            style: TextStyle(color: MauSac.chuPhu, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
