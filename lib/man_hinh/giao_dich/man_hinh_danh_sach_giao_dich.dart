import 'package:flutter/material.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/dap_ung.dart';
import '../../giao_dien/bottom_sheet/bs_loc_thoi_gian.dart';
import '../../mo_hinh/giao_dich_model.dart';
import '../../mo_hinh/danh_muc_model.dart';
import '../../mo_hinh/tai_khoan_ngan_hang_model.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import 'man_hinh_them_giao_dich.dart';

/// Màn Hình Lịch Sử Tất Cả Giao Dịch (Transaction History Screen)
/// 
/// Thiết kế chuẩn Kinetic Neo-Fintech Dark Mode khớp 100% UI mockup:
/// Thẻ Dòng tiền tháng (Tổng chi, Tổng thu, Thặng dư), Ô tìm kiếm, Chip lọc danh mục,
/// Gom nhóm danh sách giao dịch theo Ngày (Hôm nay, Hôm qua, 23 Tháng 10...) và Thống kê tổng ngày.
class ManHinhDanhSachGiaoDich extends StatefulWidget {
  const ManHinhDanhSachGiaoDich({super.key});

  @override
  State<ManHinhDanhSachGiaoDich> createState() => _ManHinhDanhSachGiaoDichState();
}

class _ManHinhDanhSachGiaoDichState extends State<ManHinhDanhSachGiaoDich> {
  /// Ngày bắt đầu và kết thúc lọc
  late DateTime _ngayBatDauChon;
  late DateTime _ngayKetThucChon;

  /// Nhãn thời gian hiển thị (Mặc định 'T10, 2026')
  late String _nhanThoiGianHienThi;

  /// Bộ điều khiển ô tìm kiếm
  final _timKiemController = TextEditingController();

  /// Từ khóa tìm kiếm hiện tại
  String _tuKhoaTimKiem = '';

  /// Chip lọc loại giao dịch đang chọn: 'tat_ca', 'chi_tieu', 'thu_nhap' hoặc ID danh mục
  String _chipFilterChon = 'tat_ca';

  /// Trạng thái đang tải từ CSDL
  bool _dangTai = true;

  /// Danh sách toàn bộ giao dịch từ CSDL
  List<GiaoDichModel> _tatCaGiaoDich = [];

  /// Danh sách danh mục từ CSDL
  List<DanhMucModel> _danhSachDanhMuc = [];

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
      final viList = await DichVuSupabase.layDanhSachTaiKhoan();

      if (mounted) {
        setState(() {
          _tatCaGiaoDich = giaoDichList;
          _danhSachDanhMuc = danhMucList;
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

  /// Định dạng tiền VND dạng đầy đủ (ví dụ: 18.450.000 đ)
  String _dinhDangTien(double amount) {
    final String numStr = amount.abs().toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formatted = numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return '$formatted đ';
  }

  /// Định dạng tiền VND thu gọn (ví dụ: -18.450k, +40.000k)
  String _dinhDangTienK(double amount, {bool isThu = false}) {
    final double absVal = amount.abs();
    final String numStr = (absVal / 1000).toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formatted = numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    final prefix = isThu ? '+' : (amount < 0 ? '-' : '');
    return '$prefix${formatted}k';
  }

  /// Lấy tên danh mục từ ID
  String _layTenDanhMuc(String? danhMucId, bool isThu) {
    if (danhMucId != null && danhMucId.isNotEmpty) {
      final dmList = _danhSachDanhMuc.where((d) => d.id == danhMucId).toList();
      if (dmList.isNotEmpty) return dmList.first.tenDanhMuc;
    }
    return isThu ? 'Thu nhập' : 'Chi tiêu';
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
    return 'VCB •• 4289';
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
    // 1. Lọc danh sách giao dịch thuộc KHOẢNG THỜI GIAN ĐƯỢC CHỌN
    final List<GiaoDichModel> giaoDichThangChon = _tatCaGiaoDich.where((gd) {
      final dt = gd.ngayGiaoDich;
      return dt.isAfter(_ngayBatDauChon.subtract(const Duration(seconds: 1))) &&
          dt.isBefore(_ngayKetThucChon.add(const Duration(seconds: 1)));
    }).toList();

    // 2. Tính toán Thống kê Dòng tiền tháng
    double tongChiThang = 0;
    int soKhoanChi = 0;
    double tongThuThang = 0;
    int soNguonThu = 0;

    for (var gd in giaoDichThangChon) {
      if (gd.loaiGiaoDich == 'chi_tieu') {
        tongChiThang += gd.soTien;
        soKhoanChi++;
      } else if (gd.loaiGiaoDich == 'thu_nhap') {
        tongThuThang += gd.soTien;
        soNguonThu++;
      }
    }

    final double thangDuThang = tongThuThang - tongChiThang;

    // 3. Lọc theo từ khóa tìm kiếm & Chip Filter
    final List<GiaoDichModel> listFiltered = giaoDichThangChon.where((gd) {
      // Filter Chip
      if (_chipFilterChon == 'chi_tieu' && gd.loaiGiaoDich != 'chi_tieu') return false;
      if (_chipFilterChon == 'thu_nhap' && gd.loaiGiaoDich != 'thu_nhap') return false;
      if (_chipFilterChon != 'tat_ca' &&
          _chipFilterChon != 'chi_tieu' &&
          _chipFilterChon != 'thu_nhap' &&
          gd.danhMucId != _chipFilterChon) {
        return false;
      }

      // Filter Từ khóa
      if (_tuKhoaTimKiem.isNotEmpty) {
        final query = _tuKhoaTimKiem.toLowerCase();
        final tenDM = _layTenDanhMuc(gd.danhMucId, gd.loaiGiaoDich == 'thu_nhap').toLowerCase();
        final ghiChu = (gd.ghiChu ?? '').toLowerCase();
        final soTienStr = gd.soTien.toInt().toString();

        return tenDM.contains(query) || ghiChu.contains(query) || soTienStr.contains(query);
      }

      return true;
    }).toList();

    // 4. Gom nhóm danh sách giao dịch theo Ngày
    final Map<DateTime, List<GiaoDichModel>> groupedMap = {};
    for (var gd in listFiltered) {
      final dateKey = DateTime(gd.ngayGiaoDich.year, gd.ngayGiaoDich.month, gd.ngayGiaoDich.day);
      if (!groupedMap.containsKey(dateKey)) {
        groupedMap[dateKey] = [];
      }
      groupedMap[dateKey]!.add(gd);
    }

    final List<DateTime> sortedDates = groupedMap.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: MauSac.nenChinh,
      appBar: AppBar(
        backgroundColor: MauSac.nenChinh,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: MauSac.chuChinh, size: 28),
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
        centerTitle: true,
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

                  // SECTION 1: HEADER "Giao dịch" + CỤM T10, 2026
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Giao dịch',
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
                              const Icon(Icons.calendar_month_rounded, color: MauSac.chuDao, size: 14),
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

                  // SECTION 2: CARD THỐNG KÊ DÒNG TIỀN THÁNG (TỔNG CHI, TỔNG THU, THẶNG DƯ)
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

                  // SECTION 3: Ô TÌM KIẾM GIAO DỊCH
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

                  // SECTION 4: HÀNG CÁC CHIP LỌC THU CHI & DANH MỤC
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _taoChipFilter('tat_ca', 'Tất cả'),
                        _taoChipFilter('chi_tieu', 'Chi tiêu'),
                        _taoChipFilter('thu_nhap', 'Thu nhập'),
                        ..._danhSachDanhMuc.take(6).map((dm) {
                          return _taoChipFilter(dm.id, '🍴 ${dm.tenDanhMuc}');
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 5: DANH SÁCH GIAO DỊCH GOM NHÓM THEO NGÀY
                  if (_dangTai)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: MauSac.chuDao)))
                  else if (giaoDichThangChon.isEmpty || sortedDates.isEmpty)
                    _taoEmptyStateChuaCoGiaoDich()
                  else
                    Column(
                      children: sortedDates.map((date) {
                        final listNgay = groupedMap[date]!;
                        // Tính tổng thu chi ngày đó
                        double tongNgay = 0;
                        for (var gd in listNgay) {
                          if (gd.loaiGiaoDich == 'thu_nhap') {
                            tongNgay += gd.soTien;
                          } else {
                            tongNgay -= gd.soTien;
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Nhãn Ngày (Hôm nay, Hôm qua...) + Tổng Tiền Ngày
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
                                    '${tongNgay >= 0 ? "+" : ""}${_dinhDangTien(tongNgay)}',
                                    style: TextStyle(
                                      color: tongNgay >= 0 ? MauSac.thuNhap : MauSac.chuPhu,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Danh sách thẻ giao dịch thuộc ngày này
                            Column(
                              children: listNgay.map((gd) {
                                final isThu = gd.loaiGiaoDich == 'thu_nhap';
                                final tenDM = _layTenDanhMuc(gd.danhMucId, isThu);
                                final tenVi = _layTenVi(gd.taiKhoanId);

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
                                      // Icon đại diện
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: MauSac.nenNoi,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          isThu ? Icons.account_balance_rounded : Icons.shopping_cart_rounded,
                                          color: isThu ? MauSac.thuNhap : MauSac.phu,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Tên tiêu đề + Diễn giải / Ví
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              gd.ghiChu != null && gd.ghiChu!.trim().isNotEmpty
                                                  ? gd.ghiChu!
                                                  : tenDM,
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
                                              '$tenDM  •  $tenVi',
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
                                            '${isThu ? "+" : "-"}${_dinhDangTien(gd.soTien)}',
                                            style: TextStyle(
                                              color: isThu ? MauSac.thuNhap : MauSac.chuChinh,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.check_circle_outline_rounded,
                                                  color: MauSac.chuPhu, size: 10),
                                              const SizedBox(width: 2),
                                              Text(
                                                isThu ? 'Đã nhận' : 'Đã trừ',
                                                style: const TextStyle(color: MauSac.chuPhu, fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
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
