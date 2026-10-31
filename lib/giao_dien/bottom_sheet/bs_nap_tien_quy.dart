import 'package:flutter/material.dart';
import '../chuan_thiet_ke/mau_sac.dart';
import '../chuan_thiet_ke/bo_goc.dart';
import '../chuan_thiet_ke/khoang_cach.dart';
import '../chuan_thiet_ke/bieu_tuong.dart';
import '../chuan_thiet_ke/dap_ung.dart';
import '../thong_bao/thong_bao_giua_man_hinh.dart';
import '../../mo_hinh/quy_tiet_kiem_model.dart';
import '../../mo_hinh/tai_khoan_ngan_hang_model.dart';
import '../../dich_vu/dich_vu_supabase.dart';

/// Bảng trượt Nạp Tiền Tích Lũy Vào Quỹ (Deposit Fund Bottom Sheet)
class BsNapTienQuy extends StatefulWidget {
  final QuyTietKiemModel quy;
  final List<TaiKhoanNganHangModel> danhSachVi;

  const BsNapTienQuy({
    super.key,
    required this.quy,
    required this.danhSachVi,
  });

  /// Hiển thị Bảng trượt Nạp Tiền
  static Future<bool?> hienThi(
    BuildContext context, {
    required QuyTietKiemModel quy,
    required List<TaiKhoanNganHangModel> danhSachVi,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BsNapTienQuy(quy: quy, danhSachVi: danhSachVi),
    );
  }

  @override
  State<BsNapTienQuy> createState() => _BsNapTienQuyState();
}

class _BsNapTienQuyState extends State<BsNapTienQuy> {
  late TaiKhoanNganHangModel? _viChon;
  late TextEditingController _ghiChuController;
  late String _soTienText;
  bool _dangXuLy = false;

  @override
  void initState() {
    super.initState();
    final listVi = widget.danhSachVi;
    if (listVi.isNotEmpty) {
      _viChon = listVi.firstWhere((v) => v.laNhanChinh, orElse: () => listVi.first);
    } else {
      _viChon = null;
    }

    final monthly = widget.quy.soTienCanNopHangThang;
    final suggestAmount = monthly > 0 ? monthly.toInt() : 2500000;
    _soTienText = suggestAmount.toString();

    final now = DateTime.now();
    _ghiChuController = TextEditingController(
      text: 'Nạp tích lũy ${widget.quy.tenQuy} T${now.month}',
    );
  }

  @override
  void dispose() {
    _ghiChuController.dispose();
    super.dispose();
  }

  double get _soTienParsed => double.tryParse(_soTienText) ?? 0.0;

  String _dinhDangTien(double amount) {
    final String numStr = amount.abs().toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  /// Chuyển đổi số tiền thành chữ Tiếng Việt
  String _chuyenSoThanhChu(double amount) {
    final int val = amount.toInt();
    if (val == 2500000) return 'Hai triệu năm trăm nghìn đồng';
    if (val == 1000000) return 'Một triệu đồng chẵn';
    if (val == 5000000) return 'Năm triệu đồng chẵn';
    if (val == 10000000) return 'Mười triệu đồng chẵn';
    return '${_dinhDangTien(amount)} đồng';
  }

  /// Nạp phím Numpad (0..9, 000, ⌫)
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

  Future<void> _xuLyNapTien() async {
    final double amount = _soTienParsed;
    if (amount <= 0) {
      _hienThongBao('Vui lòng nhập số tiền nạp lớn hơn 0 đ');
      return;
    }

    if (_viChon == null) {
      _hienThongBao('Vui lòng chọn ví nguồn trích tiền');
      return;
    }

    if (_viChon!.soDu < amount) {
      _hienThongBao(
        'Số dư ví ${_viChon!.tenNganHang} không đủ! '
        '(Dư: ${_dinhDangTien(_viChon!.soDu)} đ, Cần: ${_dinhDangTien(amount)} đ)',
      );
      return;
    }

    setState(() => _dangXuLy = true);

    try {
      final success = await DichVuSupabase.capNhatSoDuQuy(
        quyId: widget.quy.id,
        soTienThayDoi: amount,
        loaiThaoTac: 'nap_tien',
        lyDo: _ghiChuController.text.trim(),
        taiKhoanId: _viChon!.id,
      );

      if (success) {
        // Trừ tiền khỏi tài khoản ví ngân hàng
        final double soDuSau = _viChon!.soDu - amount;
        await DichVuSupabase.client
            .from('tai_khoan_ngan_hang')
            .update({'so_du': soDuSau})
            .eq('id', _viChon!.id);

        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        if (mounted) _hienThongBao('Không thể nạp tiền. Vui lòng thử lại!');
      }
    } catch (e) {
      if (mounted) _hienThongBao('Lỗi nạp tiền: $e');
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
    final double soDuVi = _viChon?.soDu ?? 0.0;
    final bool duSoDu = soDuVi >= amount && amount > 0;

    final double soTienSauNap = quy.soTienHienCo + amount;
    final double phanTramSauNap = quy.soTienMucTieu > 0 ? (soTienSauNap / quy.soTienMucTieu) * 100 : 0;
    final now = DateTime.now();

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
                  // Thanh Trượt Nhỏ Cân Bằng Trên Đầu
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

                  // HEADER: TIÊU ĐỀ NẠP TIỀN
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: MauSac.chuDao.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(BieuTuong.napTien, color: MauSac.chuDao, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Nạp tiền tích lũy', style: TextStyle(color: MauSac.chuChinh, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: MauSac.chuDao.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('Tháng ${now.month}/${now.year}', style: const TextStyle(color: MauSac.chuDao, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('Áp dụng cho: ${quy.tenQuy}', style: const TextStyle(color: MauSac.chuPhu, fontSize: 12)),
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

                  // SECTION 1: CARD ĐÃ TÍCH LŨY
                  Container(
                    width: double.infinity,
                    padding: KhoangCach.lToanBoChuan,
                    decoration: BoxDecoration(
                      color: MauSac.nenThe,
                      borderRadius: BoGoc.borderVua,
                      border: Border.all(color: MauSac.duongVienNhat),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ĐÃ TÍCH LŨY', style: TextStyle(color: MauSac.chuPhu, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(text: '${_dinhDangTien(quy.soTienHienCo)} đ ', style: const TextStyle(color: MauSac.chuChinh, fontSize: 16, fontWeight: FontWeight.bold)),
                                  TextSpan(text: '/ ${_dinhDangTien(quy.soTienMucTieu)}', style: const TextStyle(color: MauSac.chuPhu, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: MauSac.chuDao.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${quy.phanTramHoanThanh.toStringAsFixed(0)}% Hoàn thành', style: const TextStyle(color: MauSac.chuDao, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 4),
                            Text('Còn thiếu: ${_dinhDangTien(quy.soTienConLai)} đ', style: const TextStyle(color: MauSac.chuPhu, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 2: NGỦON TRÍCH TIỀN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nguồn trích tiền', style: TextStyle(color: MauSac.chuPhu, fontSize: 12)),
                      _viChon != null
                          ? PopupMenuButton<TaiKhoanNganHangModel>(
                              color: MauSac.nenThe,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BoGoc.borderVua,
                                side: BorderSide(color: MauSac.duongVienNhat),
                              ),
                              onSelected: (v) => setState(() => _viChon = v),
                              itemBuilder: (_) {
                                return widget.danhSachVi.map((v) {
                                  return PopupMenuItem(
                                    value: v,
                                    child: Text('${v.tenNganHang} (${_dinhDangTien(v.soDu)} đ)', style: const TextStyle(color: MauSac.chuChinh, fontSize: 12)),
                                  );
                                }).toList();
                              },
                              child: const Text('Đổi nguồn', style: TextStyle(color: MauSac.chuDao, fontSize: 12, fontWeight: FontWeight.bold)),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),

                  const SizedBox(height: 6),

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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(8)),
                          child: const Text('VCB', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_viChon != null ? _viChon!.tenNganHang : 'Chưa liên kết ví', style: const TextStyle(color: MauSac.chuChinh, fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('Số dư khả dụng: ${_dinhDangTien(soDuVi)} đ', style: const TextStyle(color: MauSac.chuDao, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const Icon(BieuTuong.muiTenXuong, color: MauSac.chuPhu, size: 18),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 3: GHI CHÚ NẠP TIỀN
                  const Text('Ghi chú nạp tiền', style: TextStyle(color: MauSac.chuPhu, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _ghiChuController,
                    style: const TextStyle(color: MauSac.chuChinh, fontSize: 13),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(BieuTuong.ghiChuSua, color: MauSac.chuPhu, size: 18),
                      filled: true,
                      fillColor: MauSac.nenThe,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                      enabledBorder: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                      focusedBorder: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.chuDao)),
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 4: SỐ TIỀN NẠP CARD
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
                            const Text('Số tiền nạp', style: TextStyle(color: MauSac.chuPhu, fontSize: 11, fontWeight: FontWeight.bold)),
                            Text('Định kỳ: ${_dinhDangTien(quy.soTienCanNopHangThang)} đ/tháng', style: const TextStyle(color: MauSac.chuPhu, fontSize: 11)),
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
                          children: [
                            const Icon(BieuTuong.setPhatSang, color: MauSac.chuDao, size: 12),
                            const SizedBox(width: 4),
                            Text(_chuyenSoThanhChu(amount), style: const TextStyle(color: MauSac.chuDao, fontSize: 11)),
                          ],
                        ),

                        const Divider(color: MauSac.duongVienNhat, height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('💳 Số dư nguồn trích: ${_dinhDangTien(soDuVi)} đ', style: const TextStyle(color: MauSac.chuPhu, fontSize: 11)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: duSoDu ? MauSac.chuDao.withValues(alpha: 0.2) : MauSac.chiTieu.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                duSoDu ? '✔ Đủ số dư' : '⚠ Không đủ số dư',
                                style: TextStyle(color: duSoDu ? MauSac.chuDao : MauSac.chiTieu, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // HÀNG CHIP SỐ TIỀN CỘNG NHANH
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _taoChipNapQuick('+2.5M (Mặc định)', 2500000),
                        _taoChipNapQuick('+1.0M', 1000000),
                        _taoChipNapQuick('+5.0M', 5000000),
                        _taoChipNapQuick('Tất cả thiếu', quy.soTienConLai),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // BÀN PHÍM NUMPAD 3x4
                  _taoBangNumpad(),

                  const SizedBox(height: KhoangCach.lon),

                  // FOOTER tiến độ sau khi nạp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tiến độ sau khi nạp:', style: TextStyle(color: MauSac.chuPhu, fontSize: 12)),
                      Text(
                        '${_dinhDangTien(soTienSauNap)} đ (${phanTramSauNap.toStringAsFixed(1)}%)',
                        style: const TextStyle(color: MauSac.chuDao, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // NÚT CTA XÁC NHẬN NẠP
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _dangXuLy ? null : _xuLyNapTien,
                      icon: const Icon(BieuTuong.dauTichTron, color: Colors.black, size: 20),
                      label: FittedBox(
                        child: Text(
                          'Xác nhận nạp ${_dinhDangTien(amount)} đ',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
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

  Widget _taoChipNapQuick(String nhan, double val) {
    final bool isSelected = _soTienParsed.toInt() == val.toInt();
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(nhan, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
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
