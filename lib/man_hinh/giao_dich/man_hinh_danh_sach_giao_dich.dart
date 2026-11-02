import 'package:flutter/material.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../../giao_dien/chuan_thiet_ke/dap_ung.dart';
import '../../giao_dien/bottom_sheet/bs_loc_thoi_gian.dart';
import '../../mo_hinh/giao_dich_model.dart';
import '../../mo_hinh/danh_muc_model.dart';
import '../../mo_hinh/danh_muc_ngan_sach_model.dart';
import '../../mo_hinh/quy_tiet_kiem_model.dart';
import '../../mo_hinh/lich_su_quy_model.dart';
import '../../mo_hinh/tai_khoan_ngan_hang_model.dart';
import '../../mo_hinh/giao_dich_hop_nhat_model.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import 'man_hinh_them_giao_dich.dart';
import 'man_hinh_chi_tiet_giao_dich.dart';

/// Màn Hình Lịch Sử Tất Cả Giao Dịch (Transaction History Screen - Unified Timeline)
/// 
/// Thiết kế Kinetic Neo-Fintech Dark Mode:
/// Dòng thời gian hợp nhất Thu/Chi sinh hoạt + Nạp/Rút quỹ tiết kiệm, Thẻ Dòng tiền thực tế,
/// Ô tìm kiếm, Chip lọc, Gom nhóm danh sách theo Ngày và Thống kê tổng ngày.
class ManHinhDanhSachGiaoDich extends StatefulWidget {
  const ManHinhDanhSachGiaoDich({super.key});

  @override
  State<ManHinhDanhSachGiaoDich> createState() => _ManHinhDanhSachGiaoDichState();
}

class _ManHinhDanhSachGiaoDichState extends State<ManHinhDanhSachGiaoDich> {
  /// Ngày bắt đầu và kết thúc lọc
  late DateTime _ngayBatDauChon;
  late DateTime _ngayKetThucChon;

  /// Nhãn thời gian hiển thị
  late String _nhanThoiGianHienThi;

  /// Bộ điều khiển ô tìm kiếm
  final _timKiemController = TextEditingController();

  /// Từ khóa tìm kiếm hiện tại
  String _tuKhoaTimKiem = '';

  /// Chip lọc loại giao dịch đang chọn: 'tat_ca', 'chi_tieu', 'thu_nhap', 'bien_dong_quy'
  String _chipFilterChon = 'tat_ca';

  /// Trạng thái đang tải từ CSDL
  bool _dangTai = true;

  /// Danh sách toàn bộ giao dịch hợp nhất từ CSDL
  List<GiaoDichHopNhatModel> _tatCaHopNhat = [];

  /// Danh sách toàn bộ giao dịch gốc thu chi (để tính thống kê dòng tiền tháng)
  List<GiaoDichModel> _tatCaGiaoDichGoc = [];

  /// Danh sách danh mục thu chi
  List<DanhMucModel> _danhSachDanhMuc = [];

  /// Danh sách danh mục ngân sách / quỹ
  List<DanhMucNganSachModel> _danhSachDanhMucNganSach = [];

  /// Danh sách ví từ CSDL
  List<TaiKhoanNganHangModel> _danhSachVi = [];

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

  /// Nạp dữ liệu thực tế từ CSDL Supabase
  Future<void> _loadDuLieu() async {
    setState(() => _dangTai = true);
    try {
      final giaoDichList = await DichVuSupabase.layDanhSachGiaoDich();
      final danhMucList = await DichVuSupabase.layDanhSachDanhMuc();
      final danhMucNganSachList = await DichVuSupabase.layDanhSachDanhMucNganSach();
      final viList = await DichVuSupabase.layDanhSachTaiKhoan();
      final quyList = await DichVuSupabase.layDanhSachQuy();

      final List<LichSuQuyModel> lichSuQuyTatCa = [];
      for (var q in quyList) {
        final ls = await DichVuSupabase.layDanhSachLichSuQuy(quyId: q.id);
        lichSuQuyTatCa.addAll(ls);
      }

      // Hợp nhất dữ liệu thành GiaoDichHopNhatModel
      final List<GiaoDichHopNhatModel> listHopNhat = [];

      for (var gd in giaoDichList) {
        listHopNhat.add(GiaoDichHopNhatModel.fromGiaoDich(gd));
      }

      for (var ls in lichSuQuyTatCa) {
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

      if (mounted) {
        setState(() {
          _tatCaGiaoDichGoc = giaoDichList;
          _tatCaHopNhat = listHopNhat;
          _danhSachDanhMuc = danhMucList;
          _danhSachDanhMucNganSach = danhMucNganSachList;
          _danhSachVi = viList;
          _dangTai = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi nạp Lịch sử giao dịch: $e');
      if (mounted) setState(() => _dangTai = false);
    }
  }

  /// Mở Bảng trượt chọn Lọc thời gian (BsLocThoiGian)
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

  /// Định dạng tiền VND dạng đầy đủ
  String _dinhDangTien(double amount) {
    final String numStr = amount.abs().toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formatted = numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return '$formatted đ';
  }

  /// Định dạng tiền VND thu gọn
  String _dinhDangTienK(double amount, {bool isThu = false}) {
    final double absVal = amount.abs();
    final String numStr = (absVal / 1000).toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formatted = numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    final prefix = isThu ? '+' : (amount < 0 ? '-' : '');
    return '$prefix${formatted}k';
  }

  /// Lấy tên ví từ ID
  String _layTenVi(String? taiKhoanId) {
    if (taiKhoanId != null && taiKhoanId.isNotEmpty) {
      final viList = _danhSachVi.where((v) => v.id == taiKhoanId).toList();
      if (viList.isNotEmpty) {
        final vi = viList.first;
        final soCuoi = vi.soTaiKhoan.length >= 4
            ? vi.soTaiKhoan.substring(vi.soTaiKhoan.length - 4)
            : vi.soTaiKhoan;
        return '${vi.tenNganHang} •• $soCuoi';
      }
    }
    return 'Ví liên kết';
  }

  /// Trả về nhãn ngày đẹp (Hôm nay, Hôm qua, 23 Tháng 10 • Thứ Tư...)
  String _layNhanNgayGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return 'Hôm nay  •  ${date.day} Thg ${date.month}';
    } else if (target == yesterday) {
      return 'Hôm qua  •  ${date.day} Thg ${date.month}';
    } else {
      const weekdays = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
      final tenThu = weekdays[(date.weekday - 1) % 7];
      return '${date.day} Tháng ${date.month}  •  $tenThu';
    }
  }

  @override
  void dispose() {
    _timKiemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Tính toán Thống kê Dòng tiền thực tế tháng (Báo cáo Thu/Chi không dính nạp/rút quỹ)
    final List<GiaoDichModel> giaoDichGocThangChon = _tatCaGiaoDichGoc.where((gd) {
      final dt = gd.ngayGiaoDich;
      return dt.isAfter(_ngayBatDauChon.subtract(const Duration(seconds: 1))) &&
          dt.isBefore(_ngayKetThucChon.add(const Duration(seconds: 1)));
    }).toList();

    double tongChiThang = 0;
    int soKhoanChi = 0;
    double tongThuThang = 0;
    int soNguonThu = 0;

    for (var gd in giaoDichGocThangChon) {
      if (gd.loaiGiaoDich == 'chi_tieu') {
        tongChiThang += gd.soTien;
        soKhoanChi++;
      } else if (gd.loaiGiaoDich == 'thu_nhap') {
        tongThuThang += gd.soTien;
        soNguonThu++;
      }
    }

    final double thangDuThang = tongThuThang - tongChiThang;

    // 2. Lọc danh sách giao dịch hợp nhất thuộc khoảng thời gian chọn
    final List<GiaoDichHopNhatModel> listThangChon = _tatCaHopNhat.where((item) {
      final dt = item.thoiGian;
      return dt.isAfter(_ngayBatDauChon.subtract(const Duration(seconds: 1))) &&
          dt.isBefore(_ngayKetThucChon.add(const Duration(seconds: 1)));
    }).toList();

    // 3. Lọc theo từ khóa tìm kiếm & Chip Filter
    final List<GiaoDichHopNhatModel> listFiltered = listThangChon.where((item) {
      // Filter Chip
      if (_chipFilterChon == 'chi_tieu' && !item.isChiTieu) return false;
      if (_chipFilterChon == 'thu_nhap' && !item.isThuNhap) return false;
      if (_chipFilterChon == 'bien_dong_quy' && !item.isBienDongQuy) return false;
      if (_chipFilterChon != 'tat_ca' &&
          _chipFilterChon != 'chi_tieu' &&
          _chipFilterChon != 'thu_nhap' &&
          _chipFilterChon != 'bien_dong_quy' &&
          item.danhMucId != _chipFilterChon) {
        return false;
      }

      // Filter Từ khóa
      if (_tuKhoaTimKiem.isNotEmpty) {
        final query = _tuKhoaTimKiem.toLowerCase();
        final tieuDe = item.tieuDe.toLowerCase();
        final tenDM = item.isBienDongQuy
            ? _danhSachDanhMucNganSach.layTen(item.danhMucId).toLowerCase()
            : _danhSachDanhMuc.layTen(item.danhMucId, isThu: item.isThuNhap).toLowerCase();
        final ghiChu = item.ghiChu.toLowerCase();
        final soTienStr = item.soTien.toInt().toString();

        return tieuDe.contains(query) || tenDM.contains(query) || ghiChu.contains(query) || soTienStr.contains(query);
      }

      return true;
    }).toList();

    // 4. Gom nhóm danh sách giao dịch hợp nhất theo Ngày
    final Map<DateTime, List<GiaoDichHopNhatModel>> groupedMap = {};
    for (var item in listFiltered) {
      final dateKey = DateTime(item.thoiGian.year, item.thoiGian.month, item.thoiGian.day);
      if (!groupedMap.containsKey(dateKey)) {
        groupedMap[dateKey] = [];
      }
      groupedMap[dateKey]!.add(item);
    }

    final List<DateTime> sortedDates = groupedMap.keys.toList()
      ..sort((a, b) => b.compareTo(a));

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
          'Lịch Sử Giao Dịch',
          style: TextStyle(
            color: MauSac.chuChinh,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: GestureDetector(
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
            ),
          ),
        ],
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

                  // SECTION 1: CARD THỐNG KÊ DÒNG TIỀN THÁNG (TỔNG CHI, TỔNG THU, THẶNG DƯ)
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
                          children: [
                            const Icon(Icons.circle, color: MauSac.chuDao, size: 8),
                            const SizedBox(width: 6),
                            Text(
                              'DÒNG TIỀN $_nhanThoiGianHienThi'.toUpperCase(),
                              style: const TextStyle(
                                color: MauSac.chuPhu,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Hàng 3 Thẻ Nhỏ (Tổng chi, Tổng thu, Thặng dư)
                        Row(
                          children: [
                            // Thẻ Tổng Chi
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                decoration: BoxDecoration(
                                  color: MauSac.nenNoi,
                                  borderRadius: BoGoc.borderVua,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.arrow_downward_rounded, color: MauSac.chiTieu, size: 12),
                                        SizedBox(width: 2),
                                        Text('Tổng chi', style: TextStyle(color: MauSac.chuPhu, fontSize: 10)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      child: Text(
                                        '-${_dinhDangTienK(tongChiThang)}',
                                        style: const TextStyle(
                                          color: MauSac.chiTieu,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text('$soKhoanChi khoản', style: const TextStyle(color: MauSac.chuMo, fontSize: 9)),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Thẻ Tổng Thu
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                decoration: BoxDecoration(
                                  color: MauSac.nenNoi,
                                  borderRadius: BoGoc.borderVua,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.arrow_upward_rounded, color: MauSac.thuNhap, size: 12),
                                        SizedBox(width: 2),
                                        Text('Tổng thu', style: TextStyle(color: MauSac.chuPhu, fontSize: 10)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      child: Text(
                                        '+${_dinhDangTienK(tongThuThang, isThu: true)}',
                                        style: const TextStyle(
                                          color: MauSac.thuNhap,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text('$soNguonThu nguồn', style: const TextStyle(color: MauSac.chuMo, fontSize: 9)),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Thẻ Thặng Dư
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                decoration: BoxDecoration(
                                  color: MauSac.nenNoi,
                                  borderRadius: BoGoc.borderVua,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.pie_chart_outline_rounded, color: MauSac.phu, size: 12),
                                        SizedBox(width: 2),
                                        Text('Thặng dư', style: TextStyle(color: MauSac.chuPhu, fontSize: 10)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      child: Text(
                                        '${thangDuThang >= 0 ? "+" : ""}${_dinhDangTienK(thangDuThang)}',
                                        style: TextStyle(
                                          color: thangDuThang >= 0 ? MauSac.thuNhap : MauSac.chiTieu,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text('Cân đối', style: TextStyle(color: MauSac.chuMo, fontSize: 9)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 2: Ô TÌM KIẾM GIAO DỊCH
                  TextField(
                    controller: _timKiemController,
                    onChanged: (val) => setState(() => _tuKhoaTimKiem = val.trim()),
                    style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tìm tên, danh mục, số tiền...',
                      hintStyle: const TextStyle(color: MauSac.chuMo),
                      prefixIcon: const Icon(Icons.search_rounded, color: MauSac.chuPhu, size: 20),
                      suffixIcon: _tuKhoaTimKiem.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: MauSac.chuPhu, size: 18),
                              onPressed: () {
                                _timKiemController.clear();
                                setState(() => _tuKhoaTimKiem = '');
                              },
                            )
                          : null,
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

                  const SizedBox(height: KhoangCach.vua),

                  // SECTION 3: HÀNG CÁC CHIP LỌC THU CHI & NẠP/RÚT QUỸ
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _taoChipFilter('tat_ca', 'Tất cả'),
                        _taoChipFilter('chi_tieu', 'Chi tiêu'),
                        _taoChipFilter('thu_nhap', 'Thu nhập'),
                        _taoChipFilter('bien_dong_quy', 'Nạp / Rút quỹ'),
                        ..._danhSachDanhMuc.take(6).map((dm) {
                          return _taoChipFilter(dm.id, dm.tenDanhMuc);
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 4: DANH SÁCH GIAO DỊCH GOM NHÓM THEO NGÀY
                  if (_dangTai)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: MauSac.chuDao)))
                  else if (listThangChon.isEmpty || sortedDates.isEmpty)
                    _taoEmptyStateChuaCoGiaoDich()
                  else
                    Column(
                      children: sortedDates.map((date) {
                        final listNgay = groupedMap[date]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Nhãn Ngày (Hôm nay, Hôm qua...)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.circle, color: MauSac.chuDao, size: 6),
                                      const SizedBox(width: 6),
                                      Text(
                                        _layNhanNgayGroup(date),
                                        style: const TextStyle(
                                          color: MauSac.chuChinh,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${listNgay.length} hoạt động',
                                    style: const TextStyle(
                                      color: MauSac.chuPhu,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Danh sách thẻ giao dịch hợp nhất thuộc ngày này
                            Column(
                              children: listNgay.map((item) {
                                return _taoItemGiaoDichHopNhat(item);
                              }).toList(),
                            ),

                            const SizedBox(height: 6),
                          ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManHinhThemGiaoDich()),
          );
          if (res == true) {
            _loadDuLieu();
          }
        },
        backgroundColor: MauSac.chuDao,
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
      ),
    );
  }

  /// Dựng Item Giao dịch Hợp nhất (Thu chi hoặc Nạp/Rút quỹ)
  Widget _taoItemGiaoDichHopNhat(GiaoDichHopNhatModel item) {
    IconData iconData;
    Color iconColor;
    String tieuDeStr;
    String subTitleStr;
    String loaiBadgeText;
    Color amountColor;
    String amountPrefix;

    if (item.isBienDongQuy) {
      // Biến động nạp / rút quỹ
      iconData = _danhSachDanhMucNganSach.layIcon(item.danhMucId);
      iconColor = _danhSachDanhMucNganSach.layMauSac(item.danhMucId);
      tieuDeStr = item.tieuDe;
      final tenVi = _layTenVi(item.lichSuQuyGoc?.taiKhoanId);
      subTitleStr = '${item.ghiChu}  •  $tenVi';
      loaiBadgeText = item.isNapQuy ? 'Nạp quỹ' : 'Rút quỹ';
      amountColor = MauSac.chuDao;
      amountPrefix = item.isNapQuy ? '-' : '+';
    } else {
      // Giao dịch thu nhập / chi tiêu thực tế
      iconData = _danhSachDanhMuc.layIcon(item.danhMucId, isThu: item.isThuNhap);
      iconColor = item.isThuNhap ? MauSac.thuNhap : MauSac.phu;
      final tenDM = _danhSachDanhMuc.layTen(item.danhMucId, isThu: item.isThuNhap);
      final tenVi = _layTenVi(item.giaoDichGoc?.taiKhoanId);
      tieuDeStr = item.ghiChu.isNotEmpty ? item.ghiChu : tenDM;
      subTitleStr = '$tenDM  •  $tenVi';
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
            _loadDuLieu();
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
            // Icon đại diện
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

            // Tiêu đề + Phân loại / Ví
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
                    subTitleStr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: MauSac.chuPhu, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Số tiền + Trạng thái
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

  /// Chip lọc loại giao dịch & danh mục
  Widget _taoChipFilter(String key, String nhan) {
    final bool isSelected = _chipFilterChon == key;

    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(
          nhan,
          style: TextStyle(
            color: isSelected ? Colors.black : MauSac.chuChinh,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedColor: MauSac.chuDao,
        backgroundColor: MauSac.nenThe,
        side: BorderSide(color: isSelected ? MauSac.chuDao : MauSac.duongVienNhat),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (val) {
          if (val) setState(() => _chipFilterChon = key);
        },
      ),
    );
  }

  /// Khung hiển thị khi không có giao dịch nào trong tháng hiện tại
  Widget _taoEmptyStateChuaCoGiaoDich() {
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
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: MauSac.nenNoi,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: MauSac.chuPhu,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Chưa có giao dịch',
            style: TextStyle(
              color: MauSac.chuChinh,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Không tìm thấy khoản thu chi nào trong $_nhanThoiGianHienThi.\nHãy nhấn nút (+) bên dưới để thêm ghi chép mới!',
            textAlign: TextAlign.center,
            style: const TextStyle(color: MauSac.chuPhu, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
