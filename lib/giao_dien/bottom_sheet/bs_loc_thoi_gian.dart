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

/// Bảng Trượt (Bottom Sheet) Lọc Thời Gian Giao Dịch & Báo Cáo Tài Chính
/// 
/// Thiết kế chuẩn Kinetic Neo-Fintech hỗ trợ chọn nhanh các mốc thời gian hoặc tùy chọn khoảng ngày bắt đầu - kết thúc.
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
  late LoaiLocThoiGian _loaiLocChon;
  DateTime? _ngayBatDau;
  DateTime? _ngayKetThuc;

  @override
  void initState() {
    super.initState();
    _loaiLocChon = widget.loaiLocBanDau;
    if (widget.khoangNgayTuyChonBanDau != null) {
      _ngayBatDau = widget.khoangNgayTuyChonBanDau!.start;
      _ngayKetThuc = widget.khoangNgayTuyChonBanDau!.end;
    } else {
      final now = DateTime.now();
      _ngayBatDau = DateTime(now.year, now.month, 1);
      _ngayKetThuc = now;
    }
  }

  /// Mở DateRangePicker chọn khoảng ngày tùy chỉnh
  Future<void> _chonKhoangNgay() async {
    final now = DateTime.now();
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _ngayBatDau ?? DateTime(now.year, now.month, 1),
        end: _ngayKetThuc ?? now,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: MauSac.chuDao,
              onPrimary: Colors.black,
              surface: MauSac.nenThe,
              onSurface: MauSac.chuChinh,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: MauSac.nenThe),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      setState(() {
        _ngayBatDau = range.start;
        _ngayKetThuc = range.end;
        _loaiLocChon = LoaiLocThoiGian.tuyChon;
      });
    }
  }

  String _layTenLoaiLoc(LoaiLocThoiGian loai) {
    switch (loai) {
      case LoaiLocThoiGian.thangNay:
        return 'Tháng này';
      case LoaiLocThoiGian.thangTruoc:
        return 'Tháng trước';
      case LoaiLocThoiGian.baThangGanDay:
        return '3 tháng gần đây';
      case LoaiLocThoiGian.namNay:
        return 'Năm nay';
      case LoaiLocThoiGian.tuyChon:
        return 'Tùy chọn khoảng ngày';
    }
  }

  String _dinhDangNgay(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
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
              // Thanh kéo xám Top chỉ dẫn vuốt xuống
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

              // HEADER TIÊU ĐỀ & NÚT X
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lọc thời gian',
                    style: TextStyle(
                      color: MauSac.chuChinh,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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

              // DANH SÁCH CÁC TÙY CHỌN LỌC THỜI GIAN
              Container(
                decoration: BoxDecoration(
                  color: MauSac.nenThe,
                  borderRadius: BoGoc.borderVua,
                  border: Border.all(color: MauSac.duongVienNhat),
                ),
                child: Column(
                  children: [
                    _taoItemOption(
                      loai: LoaiLocThoiGian.thangNay,
                      icon: Icons.calendar_today_rounded,
                      tieuDe: 'Tháng này',
                      moTa: 'Giao dịch trong tháng hiện tại',
                    ),
                    const Divider(color: MauSac.duongVienNhat, height: 1),
                    _taoItemOption(
                      loai: LoaiLocThoiGian.thangTruoc,
                      icon: Icons.history_toggle_off_rounded,
                      tieuDe: 'Tháng trước',
                      moTa: 'Giao dịch trong tháng vừa qua',
                    ),
                    const Divider(color: MauSac.duongVienNhat, height: 1),
                    _taoItemOption(
                      loai: LoaiLocThoiGian.baThangGanDay,
                      icon: Icons.date_range_rounded,
                      tieuDe: '3 tháng gần đây',
                      moTa: 'Tất cả biến động trong 90 ngày',
                    ),
                    const Divider(color: MauSac.duongVienNhat, height: 1),
                    _taoItemOption(
                      loai: LoaiLocThoiGian.namNay,
                      icon: Icons.calendar_month_rounded,
                      tieuDe: 'Năm nay',
                      moTa: 'Toàn bộ giao dịch năm hiện tại',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KhoangCach.vua),

              // CARD TÙY CHỌN KHOẢNG NGÀY BẮT ĐẦU -> KẾT THÚC
              GestureDetector(
                onTap: _chonKhoangNgay,
                child: Container(
                  padding: KhoangCach.lToanBoChuan,
                  decoration: BoxDecoration(
                    color: MauSac.nenThe,
                    borderRadius: BoGoc.borderVua,
                    border: Border.all(
                      color: _loaiLocChon == LoaiLocThoiGian.tuyChon
                          ? MauSac.chuDao
                          : MauSac.duongVienNhat,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MauSac.nenNoi,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_calendar_rounded,
                            color: MauSac.chuDao, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tùy chọn khoảng ngày',
                              style: TextStyle(
                                color: MauSac.chuChinh,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _ngayBatDau != null && _ngayKetThuc != null
                                  ? '${_dinhDangNgay(_ngayBatDau!)}  ➔  ${_dinhDangNgay(_ngayKetThuc!)}'
                                  : 'Chạm để chọn Từ ngày đến Đến ngày',
                              style: const TextStyle(color: MauSac.chuPhu, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: MauSac.chuPhu, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: KhoangCach.lon),

              // CỤM NÚT CTA THIẾT LẬP LẠI VÀ ÁP DỤNG
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _loaiLocChon = LoaiLocThoiGian.thangNay;
                            final now = DateTime.now();
                            _ngayBatDau = DateTime(now.year, now.month, 1);
                            _ngayKetThuc = now;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: MauSac.nenNoi,
                          side: const BorderSide(color: MauSac.duongVienNhat),
                          shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
                        ),
                        child: const FittedBox(
                          child: Text(
                            'Đặt lại',
                            style: TextStyle(color: MauSac.chuChinh, fontSize: 14),
                          ),
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
                        onPressed: () {
                          Navigator.pop(context, {
                            'loaiLoc': _loaiLocChon,
                            'tenLoaiLoc': _layTenLoaiLoc(_loaiLocChon),
                            'ngayBatDau': _ngayBatDau,
                            'ngayKetThuc': _ngayKetThuc,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MauSac.chuDao,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle_rounded, color: Colors.black, size: 18),
                            SizedBox(width: 6),
                            FittedBox(
                              child: Text(
                                'Áp dụng bộ lọc',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
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

  Widget _taoItemOption({
    required LoaiLocThoiGian loai,
    required IconData icon,
    required String tieuDe,
    required String moTa,
  }) {
    final bool isSelected = _loaiLocChon == loai;

    return ListTile(
      onTap: () => setState(() => _loaiLocChon = loai),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: MauSac.nenNoi,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isSelected ? MauSac.chuDao : MauSac.chuPhu, size: 20),
      ),
      title: Text(
        tieuDe,
        style: TextStyle(
          color: isSelected ? MauSac.chuDao : MauSac.chuChinh,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        moTa,
        style: const TextStyle(color: MauSac.chuPhu, fontSize: 11),
      ),
      trailing: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isSelected ? MauSac.chuDao : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? MauSac.chuDao : MauSac.chuPhu,
            width: 2,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check_rounded, color: Colors.black, size: 12)
            : null,
      ),
    );
  }
}
