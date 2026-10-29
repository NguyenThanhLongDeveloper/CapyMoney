import 'package:flutter/material.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../../giao_dien/chuan_thiet_ke/hinh_anh.dart';
import '../../giao_dien/chuan_thiet_ke/dap_ung.dart';
import '../../giao_dien/thong_bao/thong_bao_giua_man_hinh.dart';
import '../../mo_hinh/quy_tiet_kiem_model.dart';
import '../../dich_vu/dich_vu_supabase.dart';

/// Tab 2: Màn Hình Ngân Sách & Mục Tiêu Tiết Kiệm (Savings & Goals Screen)
/// 
/// Thiết kế chuẩn Kinetic Neo-Fintech Dark Mode khớp 100% UI mockup:
/// Thẻ Tổng tiền tiết kiệm & tích lũy + Tiến độ tổng, Danh sách các Khoản tiết kiệm mục tiêu
/// (Quỹ khẩn cấp, Du lịch Nhật Bản 2026...), 4 nút thao tác nhanh (Nạp tiền, Rút quỹ, Chỉnh hạn, Chỉnh thời),
/// và Nút Tạo khoản tiết kiệm / Mục tiêu mới.
class TabNganSach extends StatefulWidget {
  const TabNganSach({super.key});

  @override
  State<TabNganSach> createState() => _TabNganSachState();
}

class _TabNganSachState extends State<TabNganSach> {
  /// Cờ ẩn/hiện số tiền tích lũy
  bool _anSoTien = false;

  /// Trạng thái đang tải CSDL
  bool _dangTai = true;

  /// Danh sách các quỹ tiết kiệm mục tiêu từ Supabase
  List<QuyTietKiemModel> _danhSachQuy = [];

  @override
  void initState() {
    super.initState();
    _loadDuLieu();
  }

  /// Nạp danh sách quỹ tiết kiệm từ CSDL Supabase
  Future<void> _loadDuLieu() async {
    setState(() => _dangTai = true);
    try {
      final listQuy = await DichVuSupabase.layDanhSachQuy();
      if (mounted) {
        setState(() {
          _danhSachQuy = listQuy;
          _dangTai = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi nạp danh sách Quỹ tiết kiệm: $e');
      if (mounted) setState(() => _dangTai = false);
    }
  }

  /// Định dạng tiền VND đầy đủ (ví dụ: 111.000.000 đ)
  String _dinhDangTien(double amount) {
    if (_anSoTien) return '•••••••• đ';
    final String numStr = amount.abs().toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formatted = numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return '$formatted đ';
  }

  /// Mở Hộp thoại Nạp tiền vào quỹ
  Future<void> _moHopThoaiNapTien(QuyTietKiemModel quy) async {
    final controller = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: MauSac.nenThe,
          shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
          title: Row(
            children: const [
              Icon(BieuTuong.napTien, color: MauSac.chuDao, size: 22),
              SizedBox(width: 8),
              Text('Nạp tiền vào quỹ', style: TextStyle(color: MauSac.chuChinh, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mục tiêu: ${quy.tenQuy}', style: const TextStyle(color: MauSac.chuPhu, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Nhập số tiền nạp (VND)...',
                  hintStyle: const TextStyle(color: MauSac.chuMo),
                  filled: true,
                  fillColor: MauSac.nenNoi,
                  border: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Hủy', style: TextStyle(color: MauSac.chuPhu)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: MauSac.chuDao,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BoGoc.borderNho),
              ),
              child: const Text('Xác nhận nạp', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final soTienNap = double.tryParse(controller.text.trim()) ?? 0.0;
      if (soTienNap <= 0) {
        _hienThongBao('Vui lòng nhập số tiền nạp hợp lệ!');
        return;
      }

      final success = await DichVuSupabase.capNhatSoDuQuy(
        quyId: quy.id,
        soTienThayDoi: soTienNap,
        loaiThaoTac: 'nap_tien',
        lyDo: 'Nạp tiền vào quỹ ${quy.tenQuy}',
      );

      if (success) {
        _hienThongBao('Đã nạp ${_dinhDangTien(soTienNap)} vào ${quy.tenQuy}!', loai: LoaiThongBao.thanhCong);
        _loadDuLieu();
      }
    }
  }

  /// Mở Hộp thoại Rút tiền khỏi quỹ
  Future<void> _moHopThoaiRutTien(QuyTietKiemModel quy) async {
    final controller = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: MauSac.nenThe,
          shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
          title: Row(
            children: const [
              Icon(BieuTuong.rutTien, color: MauSac.chiTieu, size: 22),
              SizedBox(width: 8),
              Text('Rút tiền khỏi quỹ', style: TextStyle(color: MauSac.chuChinh, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mục tiêu: ${quy.tenQuy} (Khả dụng: ${_dinhDangTien(quy.soTienHienCo)})',
                  style: const TextStyle(color: MauSac.chuPhu, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Nhập số tiền rút (VND)...',
                  hintStyle: const TextStyle(color: MauSac.chuMo),
                  filled: true,
                  fillColor: MauSac.nenNoi,
                  border: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Hủy', style: TextStyle(color: MauSac.chuPhu)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: MauSac.chiTieu,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BoGoc.borderNho),
              ),
              child: const Text('Xác nhận rút', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final soTienRut = double.tryParse(controller.text.trim()) ?? 0.0;
      if (soTienRut <= 0 || soTienRut > quy.soTienHienCo) {
        _hienThongBao('Số tiền rút không hợp lệ hoặc vượt quá số dư quỹ!');
        return;
      }

      final success = await DichVuSupabase.capNhatSoDuQuy(
        quyId: quy.id,
        soTienThayDoi: -soTienRut,
        loaiThaoTac: 'rut_tien',
        lyDo: 'Rút tiền khỏi quỹ ${quy.tenQuy}',
      );

      if (success) {
        _hienThongBao('Đã rút ${_dinhDangTien(soTienRut)} khỏi ${quy.tenQuy}!', loai: LoaiThongBao.thanhCong);
        _loadDuLieu();
      }
    }
  }

  /// Mở Hộp thoại Tạo mục tiêu mới
  Future<void> _moHopThoaiTaoMucTieuMoi() async {
    final tenCtrl = TextEditingController();
    final mucTieuCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: MauSac.nenThe,
          shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
          title: Row(
            children: const [
              Icon(BieuTuong.themGiaoDich, color: MauSac.chuDao, size: 22),
              SizedBox(width: 8),
              Text('Tạo mục tiêu mới', style: TextStyle(color: MauSac.chuChinh, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: tenCtrl,
                style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Tên mục tiêu / quỹ (VD: Mua xe, Đổi iPhone)',
                  labelStyle: const TextStyle(color: MauSac.chuPhu),
                  filled: true,
                  fillColor: MauSac.nenNoi,
                  border: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mucTieuCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Số tiền mục tiêu (VND)',
                  labelStyle: const TextStyle(color: MauSac.chuPhu),
                  filled: true,
                  fillColor: MauSac.nenNoi,
                  border: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Hủy', style: TextStyle(color: MauSac.chuPhu)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: MauSac.chuDao,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BoGoc.borderNho),
              ),
              child: const Text('Tạo mục tiêu', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final user = DichVuSupabase.nguoiDungHienTai;
      final tenQuy = tenCtrl.text.trim();
      final mucTieu = double.tryParse(mucTieuCtrl.text.trim()) ?? 0.0;

      if (user == null || tenQuy.isEmpty || mucTieu <= 0) {
        _hienThongBao('Vui lòng nhập đầy đủ tên và số tiền mục tiêu hợp lệ!');
        return;
      }

      final quyMoi = QuyTietKiemModel(
        id: '',
        nguoiDungId: user.id,
        tenQuy: tenQuy,
        soTienMucTieu: mucTieu,
        soTienHienCo: 0.0,
        bieuTuong: 'khienBaoMat',
      );

      await DichVuSupabase.taoQuyMoi(quyMoi);
      _hienThongBao('Tạo mục tiêu "$tenQuy" thành công!', loai: LoaiThongBao.thanhCong);
      _loadDuLieu();
    }
  }

  void _hienThongBao(String noiDung, {LoaiThongBao loai = LoaiThongBao.loi}) {
    ThongBaoGiuaManHinh.hienThi(
      context,
      noiDung: noiDung,
      loai: loai,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nếu CSDL rỗng -> Tạo danh sách mục tiêu mẫu hiển thị chuẩn mockup UI
    final List<QuyTietKiemModel> listHienThi = _danhSachQuy.isNotEmpty
        ? _danhSachQuy
        : [
            QuyTietKiemModel(
              id: 'quy_1',
              nguoiDungId: 'demo',
              tenQuy: 'Quỹ khẩn cấp',
              bieuTuong: 'khienBaoMat',
              soTienHienCo: 65000000,
              soTienMucTieu: 100000000,
            ),
            QuyTietKiemModel(
              id: 'quy_2',
              nguoiDungId: 'demo',
              tenQuy: 'Du lịch Nhật Bản 2026',
              bieuTuong: 'mayBay',
              soTienHienCo: 18000000,
              soTienMucTieu: 30000000,
            ),
          ];

    // Tính toán số liệu tổng tiến độ
    double tongHienCo = 0;
    double tongMucTieu = 0;
    for (var q in listHienThi) {
      tongHienCo += q.soTienHienCo;
      tongMucTieu += q.soTienMucTieu;
    }

    final double phanTramTong = tongMucTieu > 0 ? (tongHienCo / tongMucTieu) * 100 : 0;
    final double tongConThieu = tongMucTieu > tongHienCo ? tongMucTieu - tongHienCo : 0;

    return Scaffold(
      backgroundColor: MauSac.nenChinh,
      appBar: AppBar(
        backgroundColor: MauSac.nenChinh,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: MauSac.nenNoi,
              child: ClipOval(
                child: Image.asset(
                  HinhAnh.logoCapy,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    BieuTuong.capybaraThantai,
                    size: 22,
                    color: MauSac.canhBao,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Capy Money',
                  style: TextStyle(
                    color: MauSac.chuChinh,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Ngân sách',
                  style: TextStyle(
                    color: MauSac.chuPhu,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
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

                  // SECTION 1: CARD TỔNG TIỀN TIẾT KIỆM & TÍCH LŨY
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
                                Icon(BieuTuong.chamTron, color: MauSac.chuDao, size: 8),
                                SizedBox(width: 6),
                                Text(
                                  'TỔNG TIỀN TIẾT KIỆM & TÍCH LŨY',
                                  style: TextStyle(
                                    color: MauSac.chuPhu,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: MauSac.chuDao.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${phanTramTong.toStringAsFixed(0)}% tổng mục tiêu',
                                style: const TextStyle(
                                  color: MauSac.chuDao,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Chuỗi Tổng tiền cỡ lớn + 👁 Ẩn/Hiện
                        Row(
                          children: [
                            Expanded(
                              child: FittedBox(
                                alignment: Alignment.centerLeft,
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _dinhDangTien(tongHienCo),
                                  style: const TextStyle(
                                    color: MauSac.chuChinh,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                _anSoTien ? BieuTuong.matAn : BieuTuong.matXem,
                                color: MauSac.chuPhu,
                                size: 22,
                              ),
                              onPressed: () => setState(() => _anSoTien = !_anSoTien),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Subtitle tháng này & còn thiếu
                        Row(
                          children: [
                            Text(
                              '↑ Tháng này: +7.200.000 đ',
                              style: const TextStyle(color: MauSac.thuNhap, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Còn cần: ${_dinhDangTien(tongConThieu)}',
                              style: const TextStyle(color: MauSac.chuPhu, fontSize: 12),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Thanh tiến độ tổng
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tổng tiến độ (${listHienThi.length} mục tiêu)',
                              style: const TextStyle(color: MauSac.chuPhu, fontSize: 11),
                            ),
                            Text(
                              '${_dinhDangTien(tongHienCo)} / ${_dinhDangTien(tongMucTieu)}',
                              style: const TextStyle(color: MauSac.chuDao, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (phanTramTong / 100).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: MauSac.nenNoi,
                            color: MauSac.chuDao,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 2: DANH SÁCH KHOẢN TIẾT KIỆM MỤC TIÊU
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Khoản tiết kiệm mục tiêu',
                        style: TextStyle(
                          color: MauSac.chuChinh,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: MauSac.nenNoi,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: MauSac.duongVienNhat),
                        ),
                        child: Text(
                          '${listHienThi.length} mục tiêu',
                          style: const TextStyle(color: MauSac.chuPhu, fontSize: 11),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // LƯỚI / DANH SÁCH THẺ MỤC TIÊU TIẾT KIỆM
                  if (_dangTai)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: MauSac.chuDao)))
                  else
                    Column(
                      children: listHienThi.map((quy) {
                        final isKhanCap = quy.tenQuy.toLowerCase().contains('khẩn cấp') || quy.tenQuy.toLowerCase().contains('dự phòng');
                        final Color themeColor = isKhanCap ? MauSac.chuDao : const Color(0xFF38BDF8);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: KhoangCach.lToanBoLon,
                          decoration: BoxDecoration(
                            color: MauSac.nenThe,
                            borderRadius: BoGoc.borderLon,
                            border: Border.all(color: MauSac.duongVienNhat),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hàng tiêu đề mục tiêu + %
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: themeColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isKhanCap ? BieuTuong.khienBaoMatDay : BieuTuong.oTo,
                                      color: themeColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      quy.tenQuy,
                                      style: const TextStyle(
                                        color: MauSac.chuChinh,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${quy.phanTramHoanThanh.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: themeColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Tiến độ tiền + Còn lại
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${_dinhDangTien(quy.soTienHienCo)} ',
                                          style: const TextStyle(color: MauSac.chuChinh, fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                          text: '/ ${_dinhDangTien(quy.soTienMucTieu)}',
                                          style: const TextStyle(color: MauSac.chuPhu, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'Còn lại: ${_dinhDangTien(quy.soTienConLai)}',
                                    style: const TextStyle(color: MauSac.chuPhu, fontSize: 12),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Thanh Tiến Độ Fill
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: (quy.phanTramHoanThanh / 100).clamp(0.0, 1.0),
                                  minHeight: 8,
                                  backgroundColor: MauSac.nenNoi,
                                  color: themeColor,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Tốc độ tích lũy tháng
                              Row(
                                children: [
                                  Icon(BieuTuong.dongBo, color: themeColor, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+2.500.000 đ/tháng',
                                    style: TextStyle(color: themeColor, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // Hàng 4 Nút Thao Tác Nhanh (Nạp tiền, Rút quỹ, Chỉnh hạn, Chỉnh thời)
                              Row(
                                children: [
                                  Expanded(
                                    child: _taoNutThaoTacNhanh(
                                      icon: BieuTuong.napTien,
                                      nhan: 'Nạp tiền',
                                      color: MauSac.chuDao,
                                      onTap: () => _moHopThoaiNapTien(quy),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _taoNutThaoTacNhanh(
                                      icon: BieuTuong.rutTien,
                                      nhan: 'Rút quỹ',
                                      color: MauSac.chiTieu,
                                      onTap: () => _moHopThoaiRutTien(quy),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _taoNutThaoTacNhanh(
                                      icon: BieuTuong.nganSach,
                                      nhan: 'Chỉnh hạn...',
                                      color: MauSac.phu,
                                      onTap: () => _hienThongBao('Chức năng điều chỉnh hạn mức đang được cập nhật!', loai: LoaiThongBao.canhBao),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _taoNutThaoTacNhanh(
                                      icon: BieuTuong.dongHo,
                                      nhan: 'Chỉnh thời...',
                                      color: MauSac.chuPhu,
                                      onTap: () => _hienThongBao('Chức năng điều chỉnh thời hạn đang được cập nhật!', loai: LoaiThongBao.canhBao),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: KhoangCach.lon),

                  // SECTION 3: NÚT CTA "+ TẠO KHOẢN TIẾT KIỆM / MỤC TIÊU MỚI"
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _moHopThoaiTaoMucTieuMoi,
                      icon: const Icon(BieuTuong.themGiaoDich, color: Colors.black, size: 20),
                      label: const FittedBox(
                        child: Text(
                          '+ Tạo khoản tiết kiệm / Mục tiêu mới',
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

                  const SizedBox(height: KhoangCach.lon),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Nút Thao tác Nhanh trên Thẻ Quỹ (Nạp tiền, Rút quỹ, Chỉnh hạn...)
  Widget _taoNutThaoTacNhanh({
    required IconData icon,
    required String nhan,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: MauSac.nenNoi,
          borderRadius: BoGoc.borderVua,
          border: Border.all(color: MauSac.duongVienNhat),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                nhan,
                style: const TextStyle(color: MauSac.chuChinh, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
