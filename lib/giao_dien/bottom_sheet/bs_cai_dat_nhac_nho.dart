import 'package:flutter/material.dart';
import '../chuan_thiet_ke/mau_sac.dart';
import '../chuan_thiet_ke/bo_goc.dart';
import '../chuan_thiet_ke/khoang_cach.dart';
import '../chuan_thiet_ke/bieu_tuong.dart';
import '../chuan_thiet_ke/dap_ung.dart';

/// Bảng Trượt (Bottom Sheet) Cài Đặt Thời Gian Nhắc Nhở Ghi Chép
/// 
/// Thiết kế chuẩn Kinetic Neo-Fintech hỗ trợ chọn giờ/phút bằng nút bấm tăng giảm và lưu cài đặt.
class BsCaiDatNhacNho extends StatefulWidget {
  /// Chuỗi thời gian mặc định ban đầu (Ví dụ: '21:30')
  final String thoiGianBanDau;

  const BsCaiDatNhacNho({
    super.key,
    this.thoiGianBanDau = '21:30',
  });

  /// Hàm hỗ trợ hiển thị Bottom Sheet từ bất kỳ Context nào, trả về chuỗi giờ mới chọn (Ví dụ: '20:00')
  static Future<String?> hienThi(BuildContext context, {String thoiGianBanDau = '21:30'}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BsCaiDatNhacNho(thoiGianBanDau: thoiGianBanDau),
    );
  }

  @override
  State<BsCaiDatNhacNho> createState() => _BsCaiDatNhacNhoState();
}

class _BsCaiDatNhacNhoState extends State<BsCaiDatNhacNho> {
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
    _gio = parts.length == 2 ? (int.tryParse(parts[0]) ?? 21) : 21;
    _phut = parts.length == 2 ? (int.tryParse(parts[1]) ?? 30) : 30;
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
                    const Text(
                      'Cài đặt nhắc nhở',
                      style: TextStyle(
                        color: MauSac.chuChinh,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                    // Nhãn THỜI GIAN NHẮC NHỞ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.circle, color: MauSac.chuDao, size: 8),
                        SizedBox(width: 6),
                        Text(
                          'THỜI GIAN NHẮC NHỞ',
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

              const SizedBox(height: KhoangCach.vua),

              // SECTION 3: CARD THÔNG BÁO TỰ ĐỘNG
              Container(
                width: double.infinity,
                padding: KhoangCach.lToanBoChuan,
                decoration: BoxDecoration(
                  color: MauSac.nenThe,
                  borderRadius: BoGoc.borderVua,
                  border: Border.all(color: MauSac.duongVienNhat),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: MauSac.nenNoi,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(BieuTuong.thongBaoChuong,
                          color: MauSac.canhBao, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông báo nhắc nhở tự động',
                            style: TextStyle(
                              color: MauSac.chuChinh,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Phát thông báo ghi chép giao dịch lúc $_chuoiThoiGianFormatted hàng ngày',
                            style: const TextStyle(color: MauSac.chuPhu, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KhoangCach.lon),

              // SECTION 4: CỤM NÚT ĐẶT LẠI VÀ LƯU CÀI ĐẶT
              Row(
                children: [
                  Expanded(
                    flex: 2,
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
                          Navigator.pop(context, _chuoiThoiGianFormatted);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MauSac.chuDao,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(BieuTuong.dauTichTron, color: Colors.black, size: 18),
                            const SizedBox(width: 6),
                            FittedBox(
                              child: Text(
                                'Lưu cài đặt ($_chuoiThoiGianFormatted)',
                                style: const TextStyle(
                                  fontSize: 13,
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
    ));
  }
}
