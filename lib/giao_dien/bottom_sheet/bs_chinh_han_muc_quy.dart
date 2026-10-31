import 'package:flutter/material.dart';
import '../chuan_thiet_ke/mau_sac.dart';
import '../chuan_thiet_ke/bo_goc.dart';
import '../chuan_thiet_ke/khoang_cach.dart';
import '../chuan_thiet_ke/bieu_tuong.dart';
import '../chuan_thiet_ke/dap_ung.dart';
import '../thong_bao/thong_bao_giua_man_hinh.dart';
import '../../mo_hinh/quy_tiet_kiem_model.dart';
import '../../dich_vu/dich_vu_supabase.dart';

/// Bảng trượt Chỉnh Hạn Mức Tích Lũy Của Quỹ (Edit Fund Target Amount Bottom Sheet)
class BsChinhHanMucQuy extends StatefulWidget {
  final QuyTietKiemModel quy;

  const BsChinhHanMucQuy({
    super.key,
    required this.quy,
  });

  /// Hiển thị Bảng trượt Chỉnh Hạn Mức
  static Future<bool?> hienThi(
    BuildContext context, {
    required QuyTietKiemModel quy,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BsChinhHanMucQuy(quy: quy),
    );
  }

  @override
  State<BsChinhHanMucQuy> createState() => _BsChinhHanMucQuyState();
}

class _BsChinhHanMucQuyState extends State<BsChinhHanMucQuy> {
  late String _soTienText;
  bool _dangXuLy = false;

  @override
  void initState() {
    super.initState();
    _soTienText = widget.quy.soTienMucTieu.toInt().toString();
  }

  double get _soTienParsed => double.tryParse(_soTienText) ?? 0.0;

  String _dinhDangTien(double amount) {
    final String numStr = amount.abs().toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  String _chuyenSoThanhChu(double amount) {
    final int val = amount.toInt();
    if (val == 120000000) return 'Một trăm hai mươi triệu đồng';
    if (val == 100000000) return 'Một trăm triệu đồng chẵn';
    if (val == 150000000) return 'Một trăm năm mươi triệu đồng';
    return '${_dinhDangTien(amount)} đồng';
  }

  void _nhapPhimNumpad(String key) {
    setState(() {
      if (key == 'xoa') {
        if (_soTienText.length > 1) {
          _soTienText = _soTienText.substring(0, _soTienText.length - 1);
        } else {
          _soTienText = '0';
        }
      } else if (key == '000') {
        if (_soTienText != '0' && _soTienText.length <= 11) {
          _soTienText += '000';
        }
      } else {
        if (_soTienText == '0') {
          _soTienText = key;
        } else if (_soTienText.length <= 12) {
          _soTienText += key;
        }
      }
    });
  }

  Future<void> _xuLyLuuHanMuc() async {
    final double amount = _soTienParsed;
    if (amount <= 0) {
      _hienThongBao('Số tiền hạn mức mục tiêu phải lớn hơn 0 đ');
      return;
    }

    if (amount < widget.quy.soTienHienCo) {
      _hienThongBao('Hạn mức mục tiêu mới không được nhỏ hơn số tiền hiện có (${_dinhDangTien(widget.quy.soTienHienCo)} đ)!');
      return;
    }

    setState(() => _dangXuLy = true);

    try {
      await DichVuSupabase.client
          .from('quy_tiet_kiem')
          .update({'so_tien_muc_tieu': amount})
          .eq('id', widget.quy.id);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _hienThongBao('Lỗi cập nhật hạn mức: $e');
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
    final double amount = _soTienParsed;

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

                  // HEADER: TIÊU ĐỀ CHỈNH HẠN MỨC
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: MauSac.chuDao.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(BieuTuong.nganSach, color: MauSac.chuDao, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Chỉnh Hạn Mức Tích Lũy', style: TextStyle(color: MauSac.chuChinh, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: MauSac.chuDao.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('Hạn mức', style: TextStyle(color: MauSac.chuDao, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('Áp dụng cho ${quy.tenQuy}', style: const TextStyle(color: MauSac.chuPhu, fontSize: 12)),
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

                  // SECTION 1: CARD TỔNG HẠN MỨC MỚI
                  Container(
                    width: double.infinity,
                    padding: KhoangCach.lToanBoLon,
                    decoration: BoxDecoration(
                      color: MauSac.nenThe,
                      borderRadius: BoGoc.borderLon,
                      border: Border.all(color: MauSac.chuDao, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TỔNG HẠN MỨC MỚI', style: TextStyle(color: MauSac.chuPhu, fontSize: 11, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: MauSac.chuDao.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('✔ Hạn mức tích lũy mục tiêu', style: TextStyle(color: MauSac.chuDao, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(_dinhDangTien(amount), style: const TextStyle(color: MauSac.chuDao, fontSize: 32, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            const Text('VNĐ', style: TextStyle(color: MauSac.chuDao, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_chuyenSoThanhChu(amount), style: const TextStyle(color: MauSac.chuPhu, fontSize: 11)),
                            Text('Hạn mức cũ: ${_dinhDangTien(quy.soTienMucTieu)} đ', style: const TextStyle(color: MauSac.chuPhu, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // HÀNG CHIP HẠN MỨC GỢI Ý
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _taoChipHanMuc('100.000.000 đ', 100000000),
                        _taoChipHanMuc('120.000.000 đ', 120000000),
                        _taoChipHanMuc('150.000.000 đ', 150000000),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // BÀN PHÍM NUMPAD 3x4
                  _taoBangNumpad(),

                  const SizedBox(height: KhoangCach.lon),

                  // NÚT CTA LƯU HẠN MỨC MỚI
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _dangXuLy ? null : _xuLyLuuHanMuc,
                      icon: const Icon(BieuTuong.dauTichTron, color: Colors.black, size: 20),
                      label: const FittedBox(
                        child: Text(
                          'Lưu hạn mức mới',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
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

  Widget _taoChipHanMuc(String nhan, double val) {
    final bool isSelected = _soTienParsed.toInt() == val.toInt();
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(nhan, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        backgroundColor: isSelected ? MauSac.chuDao.withValues(alpha: 0.2) : MauSac.nenNoi,
        labelStyle: TextStyle(color: isSelected ? MauSac.chuDao : MauSac.chuPhu),
        side: BorderSide(color: isSelected ? MauSac.chuDao : MauSac.duongVienNhat),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: () => setState(() => _soTienText = val.toInt().toString()),
      ),
    );
  }

  Widget _taoBangNumpad() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: MauSac.nenThe,
        borderRadius: BoGoc.borderVua,
        border: Border.all(color: MauSac.duongVienNhat),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _taoNutNumpad('1'),
              _taoNutNumpad('2'),
              _taoNutNumpad('3'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _taoNutNumpad('4'),
              _taoNutNumpad('5'),
              _taoNutNumpad('6'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _taoNutNumpad('7'),
              _taoNutNumpad('8'),
              _taoNutNumpad('9'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _taoNutNumpad('000'),
              _taoNutNumpad('0'),
              _taoNutNumpad('xoa', isIcon: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _taoNutNumpad(String val, {bool isIcon = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 48,
        child: ElevatedButton(
          onPressed: () => _nhapPhimNumpad(val),
          style: ElevatedButton.styleFrom(
            backgroundColor: MauSac.nenNoi,
            foregroundColor: MauSac.chuChinh,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.zero,
          ),
          child: isIcon
              ? const Icon(BieuTuong.xoaLui, color: MauSac.chuPhu, size: 20)
              : Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MauSac.chuChinh)),
        ),
      ),
    );
  }
}
