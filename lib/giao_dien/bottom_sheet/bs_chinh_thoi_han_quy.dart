import 'package:flutter/material.dart';
import '../chuan_thiet_ke/mau_sac.dart';
import '../chuan_thiet_ke/bo_goc.dart';
import '../chuan_thiet_ke/khoang_cach.dart';
import '../chuan_thiet_ke/bieu_tuong.dart';
import '../chuan_thiet_ke/dap_ung.dart';
import '../thong_bao/thong_bao_giua_man_hinh.dart';
import '../../mo_hinh/quy_tiet_kiem_model.dart';
import '../../dich_vu/dich_vu_supabase.dart';

/// Bảng trượt Chỉnh Thời Hạn / Kỳ Hạn Tích Lũy Của Quỹ (Edit Fund Deadline Bottom Sheet)
class BsChinhThoiHanQuy extends StatefulWidget {
  final QuyTietKiemModel quy;

  const BsChinhThoiHanQuy({
    super.key,
    required this.quy,
  });

  /// Hiển thị Bảng trượt Chỉnh Thời Hạn
  static Future<bool?> hienThi(
    BuildContext context, {
    required QuyTietKiemModel quy,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BsChinhThoiHanQuy(quy: quy),
    );
  }

  @override
  State<BsChinhThoiHanQuy> createState() => _BsChinhThoiHanQuyState();
}

class _BsChinhThoiHanQuyState extends State<BsChinhThoiHanQuy> {
  late int _soThangChon;
  late int _thangVeDichChon;
  late int _namVeDichChon;
  bool _dangXuLy = false;

  @override
  void initState() {
    super.initState();
    _soThangChon = widget.quy.kyHanThang > 0 ? widget.quy.kyHanThang : 14;

    final now = DateTime.now();
    final targetDate = widget.quy.ngayVeDich ?? DateTime(now.year, now.month + _soThangChon, now.day);
    _thangVeDichChon = targetDate.month;
    _namVeDichChon = targetDate.year;
  }

  String _dinhDangTien(double amount) {
    final String numStr = amount.abs().toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  /// Cập nhật thời hạn theo tháng
  void _capNhatSoThang(int months) {
    setState(() {
      _soThangChon = months.clamp(3, 36);
      final now = DateTime.now();
      final target = DateTime(now.year, now.month + _soThangChon, now.day);
      _thangVeDichChon = target.month;
      _namVeDichChon = target.year;
    });
  }

  /// Cập nhật tháng/năm dự kiến về đích
  void _capNhatThangNam(int month, int year) {
    setState(() {
      _thangVeDichChon = month;
      _namVeDichChon = year;

      final now = DateTime.now();
      final target = DateTime(year, month, now.day);
      final diffDays = target.difference(now).inDays;
      final diffMonths = (diffDays / 30).round();
      _soThangChon = diffMonths.clamp(3, 36);
    });
  }

  Future<void> _xuLyLuuThoiHan() async {
    setState(() => _dangXuLy = true);

    try {
      final now = DateTime.now();
      final ngayVeDich = DateTime(_namVeDichChon, _thangVeDichChon, now.day);

      await DichVuSupabase.client
          .from('quy_tiet_kiem')
          .update({
            'ky_han_thang': _soThangChon,
            'ngay_ve_dich': ngayVeDich.toIso8601String(),
          })
          .eq('id', widget.quy.id);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _hienThongBao('Lỗi cập nhật thời hạn: $e');
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
  }

  void _hienThongBao(String noiDung) {
    ThongBaoGiuaManHinh.hienThi(context, noiDung: noiDung, loai: LoaiThongBao.loi);
  }

  @override
  Widget build(BuildContext context) {
    final quy = widget.quy;
    final double mucNopDukien = quy.soTienConLai > 0 ? quy.soTienConLai / _soThangChon : 0.0;

    final int namDisplay = _soThangChon ~/ 12;
    final int thangDisplay = _soThangChon % 12;
    String chuoiThoiGian = '';
    if (namDisplay > 0 && thangDisplay > 0) {
      chuoiThoiGian = '$namDisplay năm $thangDisplay tháng';
    } else if (namDisplay > 0) {
      chuoiThoiGian = '$namDisplay năm';
    } else {
      chuoiThoiGian = '$thangDisplay tháng';
    }

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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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

                  // HEADER: TIÊU ĐỀ CHỈNH THỜI HẠN
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: MauSac.chuDao.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(BieuTuong.lichThang, color: MauSac.chuDao, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Chỉnh thời hạn', style: TextStyle(color: MauSac.chuChinh, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: MauSac.chuDao.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('Kỳ hạn', style: TextStyle(color: MauSac.chuDao, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('Mục tiêu: ${quy.tenQuy}', style: const TextStyle(color: MauSac.chuPhu, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(BieuTuong.xoaTron, color: MauSac.chuPhu, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 1: CARD HẠN HOÀN THÀNH MỤC TIÊU
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
                            const Text('HẠN HOÀN THÀNH MỤC TIÊU', style: TextStyle(color: MauSac.chuPhu, fontSize: 11, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: MauSac.chuDao.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(BieuTuong.dongHo, color: MauSac.chuDao, size: 12),
                                  const SizedBox(width: 4),
                                  Text('Còn $_soThangChon tháng', style: const TextStyle(color: MauSac.chuDao, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tháng $_thangVeDichChon, $_namVeDichChon',
                              style: const TextStyle(color: MauSac.chuChinh, fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                            const Icon(BieuTuong.lichSua, color: MauSac.chuPhu, size: 22),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Text('Mục tiêu: ${_dinhDangTien(quy.soTienMucTieu)} đ', style: const TextStyle(color: MauSac.chuPhu, fontSize: 12)),
                            const SizedBox(width: 12),
                            const Text('•', style: TextStyle(color: MauSac.chuPhu)),
                            const SizedBox(width: 12),
                            Text('Còn: ${_dinhDangTien(quy.soTienConLai)} đ', style: const TextStyle(color: MauSac.chuDao, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 2: CHỌN NHANH KỲ HẠN
                  const Text('Chọn nhanh kỳ hạn mục tiêu', style: TextStyle(color: MauSac.chuPhu, fontSize: 12)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _taoChipThoihan('6 tháng', 6),
                        _taoChipThoihan('1 năm', 12),
                        _taoChipThoihan('14 tháng', 14),
                        _taoChipThoihan('2 năm', 24),
                        _taoChipThoihan('3 năm', 36),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 3: CHI TIẾT THỜI GIAN DỰ KIẾN
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
                                Icon(BieuTuong.saoKe, color: MauSac.chuDao, size: 16),
                                SizedBox(width: 6),
                                Text('Chi tiết thời gian dự kiến', style: TextStyle(color: MauSac.chuChinh, fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: MauSac.nenNoi, borderRadius: BorderRadius.circular(8)),
                              child: const Text('Tùy chỉnh', style: TextStyle(color: MauSac.chuDao, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            // Ô chọn Tháng về đích
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(color: MauSac.nenNoi, borderRadius: BoGoc.borderVua, border: Border.all(color: MauSac.duongVienNhat)),
                                child: PopupMenuButton<int>(
                                  color: MauSac.nenThe,
                                  onSelected: (m) => _capNhatThangNam(m, _namVeDichChon),
                                  itemBuilder: (_) => List.generate(12, (i) => PopupMenuItem(value: i + 1, child: Text('Tháng ${i + 1}', style: const TextStyle(color: MauSac.chuChinh, fontSize: 12)))),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Tháng về đích', style: TextStyle(color: MauSac.chuPhu, fontSize: 10)),
                                          const SizedBox(height: 2),
                                          Text('Tháng $_thangVeDichChon', style: const TextStyle(color: MauSac.chuChinh, fontSize: 14, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const Icon(BieuTuong.muiTenXuong, color: MauSac.chuPhu, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Ô chọn Năm dự kiến
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(color: MauSac.nenNoi, borderRadius: BoGoc.borderVua, border: Border.all(color: MauSac.duongVienNhat)),
                                child: PopupMenuButton<int>(
                                  color: MauSac.nenThe,
                                  onSelected: (y) => _capNhatThangNam(_thangVeDichChon, y),
                                  itemBuilder: (_) => [2024, 2025, 2026, 2027, 2028, 2029, 2030].map((y) => PopupMenuItem(value: y, child: Text('$y', style: const TextStyle(color: MauSac.chuChinh, fontSize: 12)))).toList(),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Năm dự kiến', style: TextStyle(color: MauSac.chuPhu, fontSize: 10)),
                                          const SizedBox(height: 2),
                                          Text('$_namVeDichChon', style: const TextStyle(color: MauSac.chuChinh, fontSize: 14, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const Icon(BieuTuong.muiTenXuong, color: MauSac.chuPhu, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // THANH SLIDER KHOẢNG THỜI GIAN
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Khoảng thời gian:', style: TextStyle(color: MauSac.chuPhu, fontSize: 12)),
                            Text('$_soThangChon tháng ($chuoiThoiGian)', style: const TextStyle(color: MauSac.chuDao, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),

                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: MauSac.chuDao,
                            inactiveTrackColor: MauSac.nenNoi,
                            thumbColor: MauSac.chuDao,
                            overlayColor: MauSac.chuDao.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: _soThangChon.toDouble(),
                            min: 3,
                            max: 36,
                            divisions: 33,
                            onChanged: (val) => _capNhatSoThang(val.round()),
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('3 tháng', style: TextStyle(color: MauSac.chuPhu, fontSize: 10)),
                            Text('12 tháng', style: TextStyle(color: MauSac.chuPhu, fontSize: 10)),
                            Text('24 tháng', style: TextStyle(color: MauSac.chuPhu, fontSize: 10)),
                            Text('36 tháng', style: TextStyle(color: MauSac.chuPhu, fontSize: 10)),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // BANNER MỨC NẠP DỰ KIẾN
                        Container(
                          padding: KhoangCach.lToanBoChuan,
                          decoration: BoxDecoration(
                            color: MauSac.nenNoi,
                            borderRadius: BoGoc.borderVua,
                            border: Border.all(color: MauSac.duongVienNhat),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Mức nạp dự kiến:', style: TextStyle(color: MauSac.chuPhu, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text('~ ${_dinhDangTien(mucNopDukien)} đ/tháng', style: const TextStyle(color: MauSac.chuDao, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: MauSac.chuDao.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: const [
                                    Text('✔ Khả thi', style: TextStyle(color: MauSac.chuDao, fontSize: 10, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 2),
                                    Text('Đạt mục tiêu 100%', style: TextStyle(color: MauSac.chuPhu, fontSize: 9)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // HÀNG NÚT CTA "ĐÓNG" VÀ "XÁC NHẬN THỜI HẠN MỚI"
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: MauSac.nenThe,
                              side: const BorderSide(color: MauSac.duongVienNhat),
                              shape: RoundedRectangleBorder(borderRadius: BoGoc.borderTron),
                            ),
                            child: const Text('Đóng', style: TextStyle(color: MauSac.chuChinh, fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _dangXuLy ? null : _xuLyLuuThoiHan,
                            icon: const Icon(BieuTuong.dauTichTron, color: Colors.black, size: 20),
                            label: const FittedBox(
                              child: Text(
                                'Xác nhận thời hạn mới',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
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

  Widget _taoChipThoihan(String nhan, int months) {
    final bool isSelected = _soThangChon == months;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(nhan, style: TextStyle(fontSize: 12, color: isSelected ? MauSac.chuDao : MauSac.chuPhu, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: MauSac.chuDao.withValues(alpha: 0.15),
        backgroundColor: MauSac.nenNoi,
        side: BorderSide(color: isSelected ? MauSac.chuDao : MauSac.duongVienNhat),
        onSelected: (_) => _capNhatSoThang(months),
      ),
    );
  }
}
