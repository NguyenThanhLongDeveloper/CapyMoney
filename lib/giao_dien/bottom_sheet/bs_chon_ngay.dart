import 'package:flutter/material.dart';
import '../chuan_thiet_ke/mau_sac.dart';
import '../chuan_thiet_ke/bo_goc.dart';
import '../chuan_thiet_ke/khoang_cach.dart';
import '../chuan_thiet_ke/dap_ung.dart';

/// Bảng Trượt (Bottom Sheet) Chọn Ngày Giao Dịch Dành Riêng (Dedicated Date Picker)
/// 
/// Thiết kế chuẩn Kinetic Neo-Fintech Dark Mode:
/// - Lịch chọn 1 ngày duy nhất (Single Date Picker).
/// - Chuyển đổi tháng/năm linh hoạt bằng mũi tên sang trái/phải.
/// - Các chip chọn nhanh: Hôm nay, Hôm qua, Đầu tháng, Cuối tháng.
class BsChonNgay extends StatefulWidget {
  final DateTime? ngayBanDau;

  const BsChonNgay({
    super.key,
    this.ngayBanDau,
  });

  /// Hàm hỗ trợ hiển thị Bottom Sheet từ bất kỳ Context nào, trả về DateTime ngày chọn
  static Future<DateTime?> hienThi(
    BuildContext context, {
    DateTime? ngayBanDau,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BsChonNgay(ngayBanDau: ngayBanDau),
    );
  }

  @override
  State<BsChonNgay> createState() => _BsChonNgayState();
}

class _BsChonNgayState extends State<BsChonNgay> {
  late DateTime _ngayChon;
  late DateTime _thangLichHienTai;

  @override
  void initState() {
    super.initState();
    final initial = widget.ngayBanDau ?? DateTime.now();
    _ngayChon = DateTime(initial.year, initial.month, initial.day);
    _thangLichHienTai = DateTime(initial.year, initial.month, 1);
  }

  /// Tính số ngày trong tháng
  int _soNgayTrongThang(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Lùi 1 tháng
  void _luiThang() {
    setState(() {
      _thangLichHienTai = DateTime(_thangLichHienTai.year, _thangLichHienTai.month - 1, 1);
    });
  }

  /// Tiến 1 tháng
  void _tienThang() {
    setState(() {
      _thangLichHienTai = DateTime(_thangLichHienTai.year, _thangLichHienTai.month + 1, 1);
    });
  }

  /// Chọn nhanh mốc ngày
  void _chonNhanhNgay(DateTime target) {
    setState(() {
      _ngayChon = DateTime(target.year, target.month, target.day);
      _thangLichHienTai = DateTime(target.year, target.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final int soNgayMax = _soNgayTrongThang(_thangLichHienTai.year, _thangLichHienTai.month);
    final int firstDayWeekday = DateTime(_thangLichHienTai.year, _thangLichHienTai.month, 1).weekday; // 1: T2 -> 7: CN

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: MauSac.nenChinh,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: DapUng.bocKhungForm(
            child: SingleChildScrollView(
              padding: KhoangCach.lToanBoLon,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thanh Trượt Nhỏ
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: MauSac.duongVienNhat,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // HEADER: TIÊU ĐỀ & ĐÓNG
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: MauSac.chuDao.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.calendar_month_rounded, color: MauSac.chuDao, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chọn ngày giao dịch',
                                style: TextStyle(
                                  color: MauSac.chuChinh,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_ngayChon.day} Tháng ${_ngayChon.month}, ${_ngayChon.year}',
                                style: const TextStyle(color: MauSac.chuPhu, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: MauSac.chuPhu, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // CHIP CHỌN NHANH (Hôm nay, Hôm qua, Đầu tháng, Cuối tháng)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _taoChipChonNhanh('Hôm nay', today),
                        _taoChipChonNhanh('Hôm qua', yesterday),
                        _taoChipChonNhanh('Đầu tháng', DateTime(now.year, now.month, 1)),
                        _taoChipChonNhanh('Cuối tháng', DateTime(now.year, now.month, _soNgayTrongThang(now.year, now.month))),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // THẺ LỊCH NGÀY CHỌN Single Date
                  Container(
                    width: double.infinity,
                    padding: KhoangCach.lToanBoChuan,
                    decoration: BoxDecoration(
                      color: MauSac.nenThe,
                      borderRadius: BoGoc.borderLon,
                      border: Border.all(color: MauSac.duongVienNhat),
                    ),
                    child: Column(
                      children: [
                        // Hàng chuyển đổi Tháng / Năm
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded, color: MauSac.chuChinh, size: 24),
                              onPressed: _luiThang,
                            ),
                            Text(
                              'Tháng ${_thangLichHienTai.month}, ${_thangLichHienTai.year}',
                              style: const TextStyle(
                                color: MauSac.chuChinh,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded, color: MauSac.chuChinh, size: 24),
                              onPressed: _tienThang,
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Hàng Thứ trong tuần (T2 -> CN)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            _HeaderThu('T2'),
                            _HeaderThu('T3'),
                            _HeaderThu('T4'),
                            _HeaderThu('T5'),
                            _HeaderThu('T6'),
                            _HeaderThu('T7'),
                            _HeaderThu('CN'),
                          ],
                        ),

                        const Divider(color: MauSac.duongVienNhat, height: 16),

                        // Lưới các Ngày trong tháng (7 cột)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: (firstDayWeekday - 1) + soNgayMax,
                          itemBuilder: (context, index) {
                            if (index < firstDayWeekday - 1) {
                              return const SizedBox.shrink();
                            }

                            final dayNum = index - (firstDayWeekday - 1) + 1;
                            final currentTarget = DateTime(_thangLichHienTai.year, _thangLichHienTai.month, dayNum);

                            final bool isSelected = currentTarget.year == _ngayChon.year &&
                                currentTarget.month == _ngayChon.month &&
                                currentTarget.day == _ngayChon.day;

                            final bool isToday = currentTarget.year == today.year &&
                                currentTarget.month == today.month &&
                                currentTarget.day == today.day;

                            return GestureDetector(
                              onTap: () => setState(() => _ngayChon = currentTarget),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? MauSac.chuDao
                                      : (isToday ? MauSac.chuDao.withValues(alpha: 0.15) : Colors.transparent),
                                  shape: BoxShape.circle,
                                  border: isToday && !isSelected
                                      ? Border.all(color: MauSac.chuDao, width: 1.5)
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '$dayNum',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : (isToday ? MauSac.chuDao : MauSac.chuChinh),
                                      fontSize: 13,
                                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
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

                  const SizedBox(height: KhoangCach.lon),

                  // NÚT CTA HỦY HOẶC XÁC NHẬN NGÀY
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: MauSac.nenThe,
                              side: const BorderSide(color: MauSac.duongVienNhat),
                              shape: RoundedRectangleBorder(borderRadius: BoGoc.borderTron),
                            ),
                            child: const Text('Hủy', style: TextStyle(color: MauSac.chuChinh, fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context, _ngayChon),
                            icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                            label: const FittedBox(
                              child: Text(
                                'Xác nhận ngày',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MauSac.chuDao,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BoGoc.borderTron),
                            ),
                          ),
                        ),
                      ),
                    ],
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

  Widget _taoChipChonNhanh(String nhan, DateTime target) {
    final bool isSelected = _ngayChon.year == target.year &&
        _ngayChon.month == target.month &&
        _ngayChon.day == target.day;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          nhan,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? MauSac.chuDao : MauSac.chuPhu,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        backgroundColor: isSelected ? MauSac.chuDao.withValues(alpha: 0.15) : MauSac.nenThe,
        side: BorderSide(color: isSelected ? MauSac.chuDao : MauSac.duongVienNhat),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => _chonNhanhNgay(target),
      ),
    );
  }
}

class _HeaderThu extends StatelessWidget {
  final String thuText;
  const _HeaderThu(this.thuText);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        thuText,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: MauSac.chuPhu,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
