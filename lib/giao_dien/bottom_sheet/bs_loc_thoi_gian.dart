import 'package:flutter/material.dart';
import '../chuan_thiet_ke/mau_sac.dart';
import '../chuan_thiet_ke/bo_goc.dart';
import '../chuan_thiet_ke/khoang_cach.dart';

/// Enum phân loại các mốc bộ lọc thời gian
enum LoaiLocThoiGian {
  thangNay,
  thangTruoc,
  baThangGanDay,
  namNay,
  tuyChon,
}

/// Bảng Trượt (Bottom Sheet) Lọc Thời Gian 3 Tab (Theo Tháng | Theo Năm | Tuỳ Chọn)
///
/// Thiết kế chuẩn Kinetic Neo-Fintech Dark Mode khớp 100% UI mockup:
/// - Tab 1 (Theo Tháng): Lưới 12 tháng 3x4 + Chuyển đổi năm.
/// - Tab 2 (Theo Năm): Chu kỳ 12 năm + Thẻ năm Hiện tại / Đang chọn.
/// - Tab 3 (Tuỳ Chọn): Từ ngày -> Đến ngày + Lịch ngày chọn dải ngày (Date Range).
class BsLocThoiGian extends StatefulWidget {
  final LoaiLocThoiGian loaiLocBanDau;
  final DateTimeRange? khoangNgayTuyChonBanDau;

  const BsLocThoiGian({
    super.key,
    this.loaiLocBanDau = LoaiLocThoiGian.thangNay,
    this.khoangNgayTuyChonBanDau,
  });

  /// Hàm hỗ trợ hiển thị Bottom Sheet từ bất kỳ Context nào
  static Future<Map<String, dynamic>?> hienThi(
      BuildContext context, {
        LoaiLocThoiGian loaiLocBanDau = LoaiLocThoiGian.thangNay,
        DateTimeRange? khoangNgayTuyChonBanDau,
      }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BsLocThoiGian(
        loaiLocBanDau: loaiLocBanDau,
        khoangNgayTuyChonBanDau: khoangNgayTuyChonBanDau,
      ),
    );
  }

  @override
  State<BsLocThoiGian> createState() => _BsLocThoiGianState();
}

class _BsLocThoiGianState extends State<BsLocThoiGian> {
  /// Mode tab đang chọn: 'thang', 'nam', 'tuy_chon'
  String _modeTab = 'thang';

  /// Tháng được chọn trong Tab Theo Tháng (1 -> 12)
  late int _thangChon;

  /// Năm được chọn trong Tab Theo Tháng
  late int _namChonThang;

  /// Năm được chọn trong Tab Theo Năm
  late int _namChonNam;

  /// Chu kỳ năm bắt đầu trong Tab Theo Năm (Ví dụ 2015)
  late int _chuKyNamBatDau;

  /// Tháng/Năm hiển thị trên bộ chọn Lịch Tab Tuỳ Chọn
  late DateTime _thangLichTuChon;

  /// Dải ngày được chọn trong Tab Tuỳ Chọn (Từ ngày -> Đến ngày)
  DateTime? _ngayBatDauTuChon;
  DateTime? _ngayKetThucTuChon;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _thangChon = now.month;
    _namChonThang = now.year;
    _namChonNam = now.year;
    _chuKyNamBatDau = now.year - 11;
    _thangLichTuChon = DateTime(now.year, now.month, 1);

    if (widget.khoangNgayTuyChonBanDau != null) {
      _ngayBatDauTuChon = widget.khoangNgayTuyChonBanDau!.start;
      _ngayKetThucTuChon = widget.khoangNgayTuyChonBanDau!.end;
      _modeTab = 'tuy_chon';
    } else {
      _ngayBatDauTuChon = DateTime(now.year, now.month, 1);
      _ngayKetThucTuChon = DateTime(now.year, now.month, _soNgayTrongThang(now.year, now.month));
    }
  }

  int _soNgayTrongThang(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _datLai() {
    final now = DateTime.now();
    setState(() {
      _thangChon = now.month;
      _namChonThang = now.year;
      _namChonNam = now.year;
      _chuKyNamBatDau = now.year - 11;
      _thangLichTuChon = DateTime(now.year, now.month, 1);
      _ngayBatDauTuChon = DateTime(now.year, now.month, 1);
      _ngayKetThucTuChon = DateTime(now.year, now.month, _soNgayTrongThang(now.year, now.month));
    });
  }

  void _apDungBoLoc() {
    final now = DateTime.now();
    DateTime start;
    DateTime end;
    String labelText;

    if (_modeTab == 'thang') {
      start = DateTime(_namChonThang, _thangChon, 1);
      final lastDay = _soNgayTrongThang(_namChonThang, _thangChon);
      end = DateTime(_namChonThang, _thangChon, lastDay, 23, 59, 59);
      labelText = 'T$_thangChon, $_namChonThang';
    } else if (_modeTab == 'nam') {
      start = DateTime(_namChonNam, 1, 1);
      end = DateTime(_namChonNam, 12, 31, 23, 59, 59);
      labelText = 'Năm $_namChonNam';
    } else {
      start = _ngayBatDauTuChon ?? DateTime(now.year, now.month, 1);
      end = _ngayKetThucTuChon ?? DateTime(now.year, now.month, _soNgayTrongThang(now.year, now.month));
      final fmtS = '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}';
      final fmtE = '${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}';
      labelText = '$fmtS – $fmtE';
    }

    Navigator.pop(context, {
      'loaiLoc': _modeTab == 'tuy_chon' ? LoaiLocThoiGian.tuyChon : (_modeTab == 'nam' ? LoaiLocThoiGian.namNay : LoaiLocThoiGian.thangNay),
      'tenLoaiLoc': labelText,
      'ngayBatDau': start,
      'ngayKetThuc': end,
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Container(
      decoration: const BoxDecoration(
        color: MauSac.nenChinh,
        borderRadius: BoGoc.borderBottomSheet,
      ),
      child: SafeArea(
        child: Padding(
          padding: KhoangCach.lToanBoLon,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo xám Top
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MauSac.duongVien,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: KhoangCach.vua),

              // SECTION 1: HEADER LỌC THỜI GIAN
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: MauSac.chuDao.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: MauSac.chuDao.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: MauSac.chuDao, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Lọc thời gian',
                            style: TextStyle(
                              color: MauSac.chuChinh,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Chọn khoảng thời gian lọc',
                            style: TextStyle(color: MauSac.chuPhu, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close_rounded, color: MauSac.chuPhu, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: KhoangCach.lon),

              // SECTION 2: 3 TAB MODE SEGMENTED CONTROL (Theo Tháng | Theo Năm | Tuỳ chọn)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: MauSac.nenThe,
                  borderRadius: BoGoc.borderVua,
                  border: Border.all(color: MauSac.duongVienNhat),
                ),
                child: Row(
                  children: [
                    _taoTabModeItem('thang', 'Theo Tháng'),
                    _taoTabModeItem('nam', 'Theo Năm'),
                    _taoTabModeItem('tuy_chon', 'Tuỳ chọn'),
                  ],
                ),
              ),

              const SizedBox(height: KhoangCach.lon),

              // SECTION 3: NỘI DUNG TAB ĐANG CHỌN
              if (_modeTab == 'thang')
                _buildTabTheoThang(now)
              else if (_modeTab == 'nam')
                _buildTabTheoNam(now)
              else
                _buildTabTuyChon(now),

              const SizedBox(height: KhoangCach.lon),

              // SECTION 4: CỤM NÚT CTA (ĐẶT LẠI & ÁP DỤNG BỘ LỌC)
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _datLai,
                        icon: const Icon(Icons.refresh_rounded, color: MauSac.chuChinh, size: 18),
                        label: const FittedBox(
                          child: Text(
                            'Đặt lại',
                            style: TextStyle(color: MauSac.chuChinh, fontSize: 14),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: MauSac.nenNoi,
                          side: const BorderSide(color: MauSac.duongVienNhat),
                          shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _apDungBoLoc,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MauSac.chuDao,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_rounded, color: Colors.black, size: 18),
                            const SizedBox(width: 4),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _layLabelNutApDung(now),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  /// Item Tab Mode
  Widget _taoTabModeItem(String key, String nhan) {
    final bool isSelected = _modeTab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _modeTab = key),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: isSelected ? MauSac.chuDao.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? Border.all(color: MauSac.chuDao, width: 1) : null,
          ),
          child: Center(
            child: Text(
              nhan,
              style: TextStyle(
                color: isSelected ? MauSac.chuDao : MauSac.chuPhu,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Label nút Áp dụng
  String _layLabelNutApDung(DateTime now) {
    if (_modeTab == 'thang') {
      return 'Áp dụng (T$_thangChon, $_namChonThang)';
    } else if (_modeTab == 'nam') {
      return 'Áp dụng (Năm $_namChonNam)';
    } else {
      final start = _ngayBatDauTuChon ?? DateTime(now.year, now.month, 1);
      final end = _ngayKetThucTuChon ?? DateTime(now.year, now.month, _soNgayTrongThang(now.year, now.month));
      final fmtS = '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}';
      final fmtE = '${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}';
      return 'Áp dụng ($fmtS – $fmtE)';
    }
  }

  // ==========================================
  // TAB 1: THEO THÁNG (LƯỚI 12 THÁNG 3x4)
  // ==========================================
  Widget _buildTabTheoThang(DateTime now) {
    return Column(
      children: [
        // Hàng điều hướng Năm
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Năm $_namChonThang',
                  style: const TextStyle(color: MauSac.chuChinh, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (_namChonThang == now.year) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: MauSac.chuDao.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.circle, color: MauSac.chuDao, size: 6),
                        SizedBox(width: 4),
                        Text('Năm nay', style: TextStyle(color: MauSac.chuDao, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: MauSac.chuPhu, size: 22),
                  onPressed: () => setState(() => _namChonThang--),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: MauSac.chuPhu, size: 22),
                  onPressed: () => setState(() => _namChonThang++),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: KhoangCach.lon),

        // Lưới 12 Tháng 3x4
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            final int monthVal = index + 1;
            final bool isSelected = _thangChon == monthVal;

            return GestureDetector(
              onTap: () => setState(() => _thangChon = monthVal),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? MauSac.chuDao.withValues(alpha: 0.2) : MauSac.nenThe,
                  borderRadius: BoGoc.borderVua,
                  border: Border.all(
                    color: isSelected ? MauSac.chuDao : MauSac.duongVienNhat,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Thg $monthVal',
                      style: TextStyle(
                        color: isSelected ? MauSac.chuDao : MauSac.chuChinh,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.circle, color: MauSac.chuDao, size: 6),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: THEO NĂM (CHU KỲ 12 NĂM)
  // ==========================================
  Widget _buildTabTheoNam(DateTime now) {
    final int chuKyKetThuc = _chuKyNamBatDau + 11;

    return Column(
      children: [
        // Hàng điều hướng Chu kỳ 12 năm
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, color: MauSac.chuPhu, size: 22),
              onPressed: () => setState(() => _chuKyNamBatDau -= 12),
            ),
            Row(
              children: [
                const Icon(Icons.circle, color: MauSac.chuDao, size: 8),
                const SizedBox(width: 6),
                Text(
                  'Chu kỳ 12 năm: $_chuKyNamBatDau – $chuKyKetThuc',
                  style: const TextStyle(color: MauSac.chuChinh, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, color: MauSac.chuPhu, size: 22),
              onPressed: () => setState(() => _chuKyNamBatDau += 12),
            ),
          ],
        ),

        const SizedBox(height: KhoangCach.lon),

        // Lưới 12 Năm 3x4
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            final int yearVal = _chuKyNamBatDau + index;
            final bool isSelected = _namChonNam == yearVal;
            final bool isCurrentYear = yearVal == now.year;

            return GestureDetector(
              onTap: () => setState(() => _namChonNam = yearVal),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? MauSac.chuDao.withValues(alpha: 0.2) : MauSac.nenThe,
                  borderRadius: BoGoc.borderVua,
                  border: Border.all(
                    color: isSelected ? MauSac.chuDao : MauSac.duongVienNhat,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isCurrentYear)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: MauSac.chuDao,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'HIỆN TẠI',
                          style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      '$yearVal',
                      style: TextStyle(
                        color: isSelected ? MauSac.chuDao : MauSac.chuChinh,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSelected ? '✔ Đang chọn' : '12 tháng',
                      style: TextStyle(
                        color: isSelected ? MauSac.chuDao : MauSac.chuPhu,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: TUỲ CHỌN (DẢI NGÀY + BẢNG LỊCH)
  // ==========================================
  Widget _buildTabTuyChon(DateTime now) {
    final fmtStart = _ngayBatDauTuChon != null
        ? '${_ngayBatDauTuChon!.day.toString().padLeft(2, '0')}/${_ngayBatDauTuChon!.month.toString().padLeft(2, '0')}/${_ngayBatDauTuChon!.year}'
        : '01/10/2026';

    final fmtEnd = _ngayKetThucTuChon != null
        ? '${_ngayKetThucTuChon!.day.toString().padLeft(2, '0')}/${_ngayKetThucTuChon!.month.toString().padLeft(2, '0')}/${_ngayKetThucTuChon!.year}'
        : '31/10/2026';

    final int soNgayMax = _soNgayTrongThang(_thangLichTuChon.year, _thangLichTuChon.month);
    final firstDayWeekday = DateTime(_thangLichTuChon.year, _thangLichTuChon.month, 1).weekday; // 1: T2 -> 7: CN

    return Column(
      children: [
        // Hàng 2 Thẻ Từ Ngày -> Đến Ngày
        Row(
          children: [
            // Từ ngày
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: MauSac.nenThe,
                  borderRadius: BoGoc.borderVua,
                  border: Border.all(color: MauSac.duongVienNhat),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Từ ngày', style: TextStyle(color: MauSac.chuPhu, fontSize: 10)),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FittedBox(
                          child: Text(
                            fmtStart,
                            style: const TextStyle(color: MauSac.chuDao, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(Icons.calendar_month_rounded, color: MauSac.chuPhu, size: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Mũi tên
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward_rounded, color: MauSac.chuDao, size: 18),
            ),

            // Đến ngày
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: MauSac.nenThe,
                  borderRadius: BoGoc.borderVua,
                  border: Border.all(color: MauSac.duongVienNhat),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Đến ngày', style: TextStyle(color: MauSac.chuPhu, fontSize: 10)),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FittedBox(
                          child: Text(
                            fmtEnd,
                            style: const TextStyle(color: MauSac.chuDao, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(Icons.calendar_month_rounded, color: MauSac.chuPhu, size: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: KhoangCach.lon),

        // Header Tháng Lịch + Nút điều hướng
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Tháng ${_thangLichTuChon.month}, ${_thangLichTuChon.year}',
                  style: const TextStyle(color: MauSac.chuChinh, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: MauSac.chuDao.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$soNgayMax ngày', style: const TextStyle(color: MauSac.chuDao, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: MauSac.chuPhu, size: 20),
                  onPressed: () {
                    setState(() {
                      _thangLichTuChon = DateTime(_thangLichTuChon.year, _thangLichTuChon.month - 1, 1);
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: MauSac.chuPhu, size: 20),
                  onPressed: () {
                    setState(() {
                      _thangLichTuChon = DateTime(_thangLichTuChon.year, _thangLichTuChon.month + 1, 1);
                    });
                  },
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: KhoangCach.nho),

        // Lưới Bảng Lịch Ngày (T2 -> CN)
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MauSac.nenThe,
            borderRadius: BoGoc.borderVua,
            border: Border.all(color: MauSac.duongVienNhat),
          ),
          child: Column(
            children: [
              // Hàng Thứ: T2, T3... CN
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Text('T2', style: TextStyle(color: MauSac.chuPhu, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('T3', style: TextStyle(color: MauSac.chuPhu, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('T4', style: TextStyle(color: MauSac.chuPhu, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('T5', style: TextStyle(color: MauSac.chuPhu, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('T6', style: TextStyle(color: MauSac.chuPhu, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('T7', style: TextStyle(color: MauSac.chuPhu, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('CN', style: TextStyle(color: MauSac.chuPhu, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),

              const SizedBox(height: 8),

              // Ô Lưới Ngày trong Tháng
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1.2,
                ),
                itemCount: 35,
                itemBuilder: (context, index) {
                  final int dayVal = index - (firstDayWeekday - 2);
                  if (dayVal < 1 || dayVal > soNgayMax) {
                    return const SizedBox();
                  }

                  final currDate = DateTime(_thangLichTuChon.year, _thangLichTuChon.month, dayVal);
                  final bool isStart = _ngayBatDauTuChon != null &&
                      currDate.year == _ngayBatDauTuChon!.year &&
                      currDate.month == _ngayBatDauTuChon!.month &&
                      currDate.day == _ngayBatDauTuChon!.day;

                  final bool isEnd = _ngayKetThucTuChon != null &&
                      currDate.year == _ngayKetThucTuChon!.year &&
                      currDate.month == _ngayKetThucTuChon!.month &&
                      currDate.day == _ngayKetThucTuChon!.day;

                  final bool isInRange = _ngayBatDauTuChon != null &&
                      _ngayKetThucTuChon != null &&
                      currDate.isAfter(_ngayBatDauTuChon!) &&
                      currDate.isBefore(_ngayKetThucTuChon!);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_ngayBatDauTuChon == null || (_ngayBatDauTuChon != null && _ngayKetThucTuChon != null)) {
                          _ngayBatDauTuChon = currDate;
                          _ngayKetThucTuChon = null;
                        } else if (currDate.isBefore(_ngayBatDauTuChon!)) {
                          _ngayBatDauTuChon = currDate;
                        } else {
                          _ngayKetThucTuChon = currDate;
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: (isStart || isEnd)
                            ? MauSac.chuDao
                            : (isInRange ? MauSac.chuDao.withValues(alpha: 0.25) : Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          dayVal.toString().padLeft(2, '0'),
                          style: TextStyle(
                            color: (isStart || isEnd)
                                ? Colors.black
                                : (isInRange ? MauSac.chuDao : MauSac.chuChinh),
                            fontSize: 12,
                            fontWeight: (isStart || isEnd || isInRange) ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
