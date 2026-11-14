import 'package:flutter/material.dart';
import '../chuan_thiet_ke/mau_sac.dart';
import '../chuan_thiet_ke/bo_goc.dart';
import '../chuan_thiet_ke/khoang_cach.dart';
import '../chuan_thiet_ke/bieu_tuong.dart';
import '../chuan_thiet_ke/dap_ung.dart';

/// Bảng Trượt (Bottom Sheet) Chọn Giờ Giao Dịch Dành Riêng (Dedicated Time Picker)
/// 
/// Thiết kế chuẩn Kinetic Neo-Fintech Dark Mode:
/// - Chọn Giờ & Phút trực quan bằng nút tăng giảm hoặc mốc chọn giờ nhanh.
/// - Các chip chọn nhanh: Hiện tại, Sáng 08:00, Trưa 12:00, Tối 19:00, Đêm 22:00.
class BsChonGio extends StatefulWidget {
  /// Chuỗi thời gian mặc định ban đầu (Ví dụ: '21:30')
  final String thoiGianBanDau;

  const BsChonGio({
    super.key,
    this.thoiGianBanDau = '21:30',
  });

  /// Hàm hỗ trợ hiển thị Bottom Sheet từ bất kỳ Context nào, trả về chuỗi giờ mới chọn (Ví dụ: '20:00')
  static Future<String?> hienThi(BuildContext context, {String thoiGianBanDau = '21:30'}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BsChonGio(thoiGianBanDau: thoiGianBanDau),
    );
  }

  @override
  State<BsChonGio> createState() => _BsChonGioState();
}

class _BsChonGioState extends State<BsChonGio> {
  /// Giá trị Giờ chọn (0 -> 23)
  late int _gio;

  /// Giá trị Phút chọn (0 -> 59)
  late int _phut;

  @override
  void initState() {
    super.initState();
    _giaiMaThoiGian(widget.thoiGianBanDau);
  }

  /// Trích xuất giờ và phút từ chuỗi dạng 'HH:mm'
  void _giaiMaThoiGian(String text) {
    final parts = text.split(':');
    _gio = parts.length == 2 ? (int.tryParse(parts[0]) ?? 12) : 12;
    _phut = parts.length == 2 ? (int.tryParse(parts[1]) ?? 0) : 0;
  }

  /// Tăng 1 giờ
  void _tangGio() {
    setState(() {
      _gio = (_gio + 1) % 24;
    });
  }

  /// Giảm 1 giờ
  void _giamGio() {
    setState(() {
      _gio = (_gio - 1 + 24) % 24;
    });
  }

  /// Tăng 1 phút
  void _tangPhut() {
    setState(() {
      _phut = (_phut + 1) % 60;
    });
  }

  /// Giảm 1 phút
  void _giamPhut() {
    setState(() {
      _phut = (_phut - 1 + 60) % 60;
    });
  }

  /// Chọn mốc giờ nhanh
  void _chonMocGioNhanh(int hour, int minute) {
    setState(() {
      _gio = hour.clamp(0, 23);
      _phut = minute.clamp(0, 59);
    });
  }

  /// Khôi phục về giờ ban đầu
  void _datLai() {
    setState(() {
      _giaiMaThoiGian(widget.thoiGianBanDau);
    });
  }

  /// Định dạng chuỗi hiển thị 'HH:mm'
  String get _chuoiThoiGianFormatted =>
      '${_gio.toString().padLeft(2, '0')}:${_phut.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return DapUng.bocKhungForm(
      child: Container(
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

                // SECTION 1: HEADER TIÊU ĐỀ & NÚT X
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
                          child: const Icon(Icons.access_time_rounded, color: MauSac.chuDao, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chọn giờ',
                              style: TextStyle(
                                color: MauSac.chuChinh,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Đang chọn: $_chuoiThoiGianFormatted',
                              style: const TextStyle(color: MauSac.chuPhu, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(BieuTuong.dongX, color: MauSac.chuPhu, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: KhoangCach.lon),

                // CHIP CHỌN MỐC GIỜ NHANH (Hiện tại, 08:00, 12:00, 19:00, 22:00)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _taoChipMocGio('Hiện tại', now.hour, now.minute),
                      _taoChipMocGio('Sáng 08:00', 8, 0),
                      _taoChipMocGio('Trưa 12:00', 12, 0),
                      _taoChipMocGio('Tối 19:00', 19, 0),
                      _taoChipMocGio('Đêm 22:00', 22, 0),
                    ],
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),

                // SECTION 2: CARD BẢNG CHỌN THỜI GIAN (GIỜ : PHÚT)
                Container(
                  width: double.infinity,
                  padding: KhoangCach.lToanBoLon,
                  decoration: BoxDecoration(
                    color: MauSac.nenThe,
                    borderRadius: BoGoc.borderLon,
                    border: Border.all(color: MauSac.duongVienNhat),
                  ),
                  child: Column(
                    children: [
                      // Nhãn GIỜ & PHÚT GIAO DỊCH
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.circle, color: MauSac.chuDao, size: 8),
                          SizedBox(width: 6),
                          Text(
                            'GIỜ & PHÚT GIAO DỊCH',
                            style: TextStyle(
                              color: MauSac.chuPhu,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: KhoangCach.lon),

                      // Cụm Nút Tăng/Giảm GIỜ & PHÚT
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Cột GIỜ
                          Column(
                            children: [
                              InkWell(
                                onTap: _tangGio,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: MauSac.nenNoi,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(BieuTuong.muiTenLen,
                                      color: MauSac.chuChinh, size: 24),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _gio.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: MauSac.chuDao,
                                ),
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: _giamGio,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: MauSac.nenNoi,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(BieuTuong.muiTenXuong,
                                      color: MauSac.chuChinh, size: 24),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'GIỜ',
                                style: TextStyle(
                                  color: MauSac.chuPhu,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 24),

                          // Dấu 2 chấm
                          const Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Text(
                              ':',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: MauSac.chuDao,
                              ),
                            ),
                          ),

                          const SizedBox(width: 24),

                          // Cột PHÚT
                          Column(
                            children: [
                              InkWell(
                                onTap: _tangPhut,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: MauSac.nenNoi,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(BieuTuong.muiTenLen,
                                      color: MauSac.chuChinh, size: 24),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _phut.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: MauSac.chuDao,
                                ),
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: _giamPhut,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: MauSac.nenNoi,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(BieuTuong.muiTenXuong,
                                      color: MauSac.chuChinh, size: 24),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'PHÚT',
                                style: TextStyle(
                                  color: MauSac.chuPhu,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),

                // SECTION 3: CỤM NÚT ĐẶT LẠI VÀ XÁC NHẬN GIỜ
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _datLai,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: MauSac.nenNoi,
                            side: const BorderSide(color: MauSac.duongVienNhat),
                            shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
                          ),
                          child: const FittedBox(
                            child: Text(
                              'Đặt lại',
                              style: TextStyle(color: MauSac.chuChinh, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context, _chuoiThoiGianFormatted);
                          },
                          icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                          label: FittedBox(
                            child: Text(
                              'Xác nhận giờ ($_chuoiThoiGianFormatted)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MauSac.chuDao,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
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
      ),
    );
  }

  Widget _taoChipMocGio(String nhan, int hour, int minute) {
    final bool isSelected = _gio == hour && _phut == minute;

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
        onPressed: () => _chonMocGioNhanh(hour, minute),
      ),
    );
  }
}
