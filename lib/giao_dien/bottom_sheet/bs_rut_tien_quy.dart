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

/// Bảng trượt Rút Quỹ Tích Lũy Khỏi Mục Tiêu (Withdraw Fund Bottom Sheet)
class BsRutTienQuy extends StatefulWidget {
  final QuyTietKiemModel quy;
  final List<TaiKhoanNganHangModel> danhSachVi;

  const BsRutTienQuy({
    super.key,
    required this.quy,
    required this.danhSachVi,
  });

  /// Hiển thị Bảng trượt Rút Quỹ
  static Future<bool?> hienThi(
    BuildContext context, {
    required QuyTietKiemModel quy,
    required List<TaiKhoanNganHangModel> danhSachVi,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BsRutTienQuy(quy: quy, danhSachVi: danhSachVi),
    );
  }

  @override
  State<BsRutTienQuy> createState() => _BsRutTienQuyState();
}

class _BsRutTienQuyState extends State<BsRutTienQuy> {
  late TaiKhoanNganHangModel? _viChon;
  late String _soTienText;
  String _lyDoChon = 'Chi tiêu khẩn cấp';
  bool _dangXuLy = false;

  final List<String> _danhSachLyDo = const [
    'Chi tiêu khẩn cấp',
    'Sửa chữa xe/nhà',
    'Y tế / Thuốc',
    'Lý do khác',
  ];

  @override
  void initState() {
    super.initState();
    final listVi = widget.danhSachVi;
    if (listVi.isNotEmpty) {
      _viChon = listVi.firstWhere((v) => v.laNhanChinh, orElse: () => listVi.first);
    } else {
      _viChon = null;
    }

    final int defaultAmount = widget.quy.soTienHienCo >= 5000000 ? 5000000 : widget.quy.soTienHienCo.toInt();
    _soTienText = defaultAmount.toString();
  }

  double get _soTienParsed => double.tryParse(_soTienText) ?? 0.0;

  String _dinhDangTien(double amount) {
    final String numStr = amount.abs().toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  String _chuyenSoThanhChu(double amount) {
    final int val = amount.toInt();
    if (val == 5000000) return 'Năm triệu đồng chẵn';
    if (val == 2000000) return 'Hai triệu đồng chẵn';
    if (val == 10000000) return 'Mười triệu đồng chẵn';
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

  Future<void> _xuLyRutTien() async {
    final double amount = _soTienParsed;
    if (amount <= 0) {
      _hienThongBao('Vui lòng nhập số tiền rút lớn hơn 0 đ');
      return;
    }

    if (amount > widget.quy.soTienHienCo) {
      _hienThongBao('Số tiền rút không được vượt quá số dư hiện có trong quỹ!');
      return;
    }

    if (_viChon == null) {
      _hienThongBao('Vui lòng chọn tài khoản ví nhận tiền');
      return;
    }

    setState(() => _dangXuLy = true);

    try {
      final success = await DichVuSupabase.capNhatSoDuQuy(
        quyId: widget.quy.id,
        soTienThayDoi: -amount,
        loaiThaoTac: 'rut_tien',
        lyDo: 'Rút quỹ: $_lyDoChon',
        taiKhoanId: _viChon!.id,
      );

      if (success) {
        // Cộng tiền lại vào ví nhận
        final double soDuSau = _viChon!.soDu + amount;
        await DichVuSupabase.client
            .from('tai_khoan_ngan_hang')
            .update({'so_du': soDuSau})
            .eq('id', _viChon!.id);

        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        if (mounted) _hienThongBao('Không thể rút quỹ. Vui lòng thử lại!');
      }
    } catch (e) {
      if (mounted) _hienThongBao('Lỗi rút quỹ: $e');
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
    final bool trongGioiHan = amount > 0 && amount <= quy.soTienHienCo;

    final double soTienSauRut = (quy.soTienHienCo - amount).clamp(0, double.infinity);
    final double phanTramSauRut = quy.soTienMucTieu > 0 ? (soTienSauRut / quy.soTienMucTieu) * 100 : 0;

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

                  // HEADER: TIÊU ĐỀ RÚT QUỸ
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: MauSac.chiTieu.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(BieuTuong.rutTien, color: MauSac.chiTieu, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Rút quỹ tích lũy', style: TextStyle(color: MauSac.chuChinh, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: MauSac.chiTieu.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('Chi tiêu khẩn cấp', style: TextStyle(color: MauSac.chiTieu, fontSize: 10, fontWeight: FontWeight.bold)),
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

                  // SECTION 1: SỐ DƯ QUỸ HIỆN CÓ
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
                            const Text('SỐ DƯ QUỸ HIỆN CÓ', style: TextStyle(color: MauSac.chuPhu, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('${_dinhDangTien(quy.soTienHienCo)} đ', style: const TextStyle(color: MauSac.chuChinh, fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: MauSac.chiTieu.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: const [
                              Text('Tối đa có thể rút', style: TextStyle(color: MauSac.chiTieu, fontSize: 10, fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('100% số dư thực tế', style: TextStyle(color: MauSac.chuPhu, fontSize: 9)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 2: CHUYỂN VỀ TÀI KHOẢN / VÍ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Chuyển về tài khoản / Ví', style: TextStyle(color: MauSac.chuPhu, fontSize: 12)),
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
                              child: const Text('Chọn ví khác', style: TextStyle(color: MauSac.chuDao, fontSize: 12, fontWeight: FontWeight.bold)),
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
                              Text(_viChon != null ? '${_viChon!.tenNganHang} (${_viChon!.soTaiKhoan})' : 'Chưa liên kết ví', style: const TextStyle(color: MauSac.chuChinh, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              const Text('Nhận ngay tức thì • Miễn phí giao dịch', style: TextStyle(color: MauSac.chuPhu, fontSize: 10)),
                            ],
                          ),
                        ),
                        const Icon(BieuTuong.muiTenXuong, color: MauSac.chuPhu, size: 18),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 3: LÝ DO RÚT QUỸ
                  const Text('Lý do rút quỹ', style: TextStyle(color: MauSac.chuPhu, fontSize: 12)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _danhSachLyDo.map((ld) {
                        final bool isSelected = _lyDoChon == ld;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(ld, style: TextStyle(fontSize: 11, color: isSelected ? MauSac.chuDao : MauSac.chuPhu, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            selected: isSelected,
                            selectedColor: MauSac.chuDao.withValues(alpha: 0.15),
                            backgroundColor: MauSac.nenNoi,
                            side: BorderSide(color: isSelected ? MauSac.chuDao : MauSac.duongVienNhat),
                            onSelected: (_) => setState(() => _lyDoChon = ld),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 4: SỐ TIỀN MUỐN RÚT CARD
                  Container(
                    width: double.infinity,
                    padding: KhoangCach.lToanBoLon,
                    decoration: BoxDecoration(
                      color: MauSac.nenThe,
                      borderRadius: BoGoc.borderLon,
                      border: Border.all(color: MauSac.chiTieu, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('SỐ TIỀN MUỐN RÚT', style: TextStyle(color: MauSac.chuPhu, fontSize: 11, fontWeight: FontWeight.bold)),
                            GestureDetector(
                              onTap: () => setState(() => _soTienText = quy.soTienHienCo.toInt().toString()),
                              child: Text('Rút toàn bộ (${_dinhDangTien(quy.soTienHienCo)})', style: const TextStyle(color: MauSac.chiTieu, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(_dinhDangTien(amount), style: const TextStyle(color: MauSac.chiTieu, fontSize: 32, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            const Text('VNĐ', style: TextStyle(color: MauSac.chiTieu, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            const Icon(BieuTuong.setPhatSang, color: MauSac.chiTieu, size: 12),
                            const SizedBox(width: 4),
                            Text(_chuyenSoThanhChu(amount), style: const TextStyle(color: MauSac.chiTieu, fontSize: 11)),
                          ],
                        ),

                        const Divider(color: MauSac.duongVienNhat, height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Giới hạn tối đa: ${_dinhDangTien(quy.soTienHienCo)} đ', style: const TextStyle(color: MauSac.chuPhu, fontSize: 11)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: trongGioiHan ? MauSac.chuDao.withValues(alpha: 0.2) : MauSac.chiTieu.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                trongGioiHan ? '✔ Trong giới hạn' : '⚠ Vượt quá số dư',
                                style: TextStyle(color: trongGioiHan ? MauSac.chuDao : MauSac.chiTieu, fontSize: 10, fontWeight: FontWeight.bold),
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
                        _taoChipRutQuick('2.000.000', 2000000),
                        _taoChipRutQuick('5.000.000', 5000000),
                        _taoChipRutQuick('10.000.000', 10000000),
                        _taoChipRutQuick('Tất cả', quy.soTienHienCo),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // BÀN PHÍM NUMPAD 3x4
                  _taoBangNumpad(),

                  const SizedBox(height: KhoangCach.lon),

                  // WARNING BANNER CẢNH BÁO GIẢM TIẾN ĐỘ
                  Container(
                    padding: KhoangCach.lToanBoChuan,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E1A11),
                      borderRadius: BoGoc.borderVua,
                      border: Border.all(color: const Color(0xFFFB923C).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(BieuTuong.canhBao, color: Color(0xFFFB923C), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Rút tiền sẽ làm giảm tiến độ mục tiêu xuống ${_dinhDangTien(soTienSauRut)} đ (${phanTramSauRut.toStringAsFixed(0)}%). Bạn sẽ cần thêm khoảng 2 tháng tích lũy để bù đắp số tiền này.',
                            style: const TextStyle(color: Color(0xFFFDBA74), fontSize: 11, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // NÚT CTA XÁC NHẬN RÚT
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _dangXuLy ? null : _xuLyRutTien,
                      icon: const Icon(BieuTuong.rutTien, color: Colors.white, size: 20),
                      label: FittedBox(
                        child: Text(
                          'Xác nhận rút ${_dinhDangTien(amount)} đ',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MauSac.chiTieu,
                        foregroundColor: Colors.white,
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

  Widget _taoChipRutQuick(String nhan, double val) {
    final bool isSelected = _soTienParsed.toInt() == val.toInt();
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(nhan, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        backgroundColor: isSelected ? MauSac.chiTieu.withValues(alpha: 0.2) : MauSac.nenNoi,
        labelStyle: TextStyle(color: isSelected ? MauSac.chiTieu : MauSac.chuPhu),
        side: BorderSide(color: isSelected ? MauSac.chiTieu : MauSac.duongVienNhat),
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
