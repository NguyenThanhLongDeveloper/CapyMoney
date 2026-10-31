import 'package:flutter/material.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../../giao_dien/chuan_thiet_ke/hinh_anh.dart';
import '../../giao_dien/chuan_thiet_ke/dap_ung.dart';
import '../../giao_dien/thong_bao/thong_bao_giua_man_hinh.dart';
import '../../giao_dien/bottom_sheet/bs_nap_tien_quy.dart';
import '../../giao_dien/bottom_sheet/bs_rut_tien_quy.dart';
import '../../giao_dien/bottom_sheet/bs_chinh_han_muc_quy.dart';
import '../../giao_dien/bottom_sheet/bs_chinh_thoi_han_quy.dart';
import '../../mo_hinh/quy_tiet_kiem_model.dart';
import '../../mo_hinh/danh_muc_ngan_sach_model.dart';
import '../../mo_hinh/tai_khoan_ngan_hang_model.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import 'man_hinh_tao_quy_tiet_kiem.dart';

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

  /// Danh sách danh mục ngân sách từ Supabase CSDL
  List<DanhMucNganSachModel> _danhSachDanhMucNganSach = [];

  /// Danh sách các quỹ tiết kiệm mục tiêu từ Supabase
  List<QuyTietKiemModel> _danhSachQuy = [];

  /// Danh sách ví ngân hàng để trích/nhận tiền
  List<TaiKhoanNganHangModel> _danhSachVi = [];

  @override
  void initState() {
    super.initState();
    _loadDuLieu();
  }

  /// Nạp danh sách danh mục ngân sách, quỹ tiết kiệm & ví ngân hàng từ CSDL Supabase
  Future<void> _loadDuLieu() async {
    setState(() => _dangTai = true);
    try {
      final listDM = await DichVuSupabase.layDanhSachDanhMucNganSach();
      final listQuy = await DichVuSupabase.layDanhSachQuy();
      final listVi = await DichVuSupabase.layDanhSachTaiKhoan();
      if (mounted) {
        setState(() {
          _danhSachDanhMucNganSach = listDM;
          _danhSachQuy = listQuy;
          _danhSachVi = listVi;
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

  void _hienThongBao(String noiDung, {LoaiThongBao loai = LoaiThongBao.loi}) {
    ThongBaoGiuaManHinh.hienThi(
      context,
      noiDung: noiDung,
      loai: loai,
    );
  }

  /// Hộp thoại xác nhận và thực thi xóa Quỹ tiết kiệm kèm hoàn tiền tự động về ví
  Future<void> _xacNhanXoaQuy(QuyTietKiemModel quy) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: MauSac.nenThe,
          shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
          title: Row(
            children: const [
              Icon(BieuTuong.xoaVien, color: MauSac.chiTieu, size: 22),
              SizedBox(width: 8),
              Text('Xóa khoản tiết kiệm', style: TextStyle(color: MauSac.chuChinh, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn có chắc chắn muốn xóa mục tiêu "${quy.tenQuy}"?',
                style: const TextStyle(color: MauSac.chuChinh, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Số tiền hiện có (${_dinhDangTien(quy.soTienHienCo)}) sẽ được tự động hoàn trả về các ví ngân hàng đã trích tiền tích lũy!',
                style: const TextStyle(color: MauSac.chuPhu, fontSize: 12, height: 1.4),
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
              child: const Text('Xác nhận xóa & Hoàn tiền', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final success = await DichVuSupabase.xoaQuyTietKiem(quy);
      if (success) {
        _hienThongBao('Đã xóa "${quy.tenQuy}" và hoàn trả tiền về ví thành công!', loai: LoaiThongBao.thanhCong);
        _loadDuLieu();
      } else {
        _hienThongBao('Không thể xóa khoản tiết kiệm. Vui lòng thử lại!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán số liệu tổng tiến độ từ CSDL Supabase
    double tongHienCo = 0;
    double tongMucTieu = 0;
    double tongConThieu = 0;
    double tongNopThangNay = 0;

    for (var q in _danhSachQuy) {
      tongHienCo += q.soTienHienCo;
      tongMucTieu += q.soTienMucTieu;
      tongConThieu += q.soTienConLai;
      tongNopThangNay += q.soTienCanNopHangThang;
    }

    final double phanTramTong = tongMucTieu > 0 ? (tongHienCo / tongMucTieu) * 100 : 0;

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
                                _danhSachQuy.isNotEmpty
                                    ? '${phanTramTong.toStringAsFixed(0)}% tổng mục tiêu'
                                    : 'Chưa có mục tiêu',
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

                        // Subtitle cần nộp tháng này & còn cần
                        Row(
                          children: [
                            Text(
                              '↑ Cần nộp tháng này: ${_dinhDangTien(tongNopThangNay)}',
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
                              _danhSachQuy.isNotEmpty
                                  ? 'Tổng tiến độ (${_danhSachQuy.length} mục tiêu)'
                                  : 'Chưa có mục tiêu',
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
                          '${_danhSachQuy.length} mục tiêu',
                          style: const TextStyle(color: MauSac.chuPhu, fontSize: 11),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: KhoangCach.lon),

                  // LƯỚI / DANH SÁCH THẺ MỤC TIÊU TIẾT KIỆM TỪ SUPABASE CSDL
                  if (_dangTai)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: MauSac.chuDao)))
                  else if (_danhSachQuy.isEmpty)
                    _taoEmptyStateChuaCoQuy()
                  else
                    Column(
                      children: _danhSachQuy.map((quy) {
                        final IconData iconData = _danhSachDanhMucNganSach.layIcon(quy.danhMucNganSachId);
                        final Color themeColor = _danhSachDanhMucNganSach.layMauSac(quy.danhMucNganSachId);
                        final double nopThangQuy = quy.soTienCanNopHangThang;

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
                              // Hàng tiêu đề mục tiêu + % + Icon Xóa
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
                                      iconData,
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
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(BieuTuong.xoaTron, color: MauSac.chiTieu, size: 20),
                                    onPressed: () => _xacNhanXoaQuy(quy),
                                    tooltip: 'Xóa khoản tiết kiệm',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
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

                              // Tốc độ nộp cần thiết trong tháng
                              Row(
                                children: [
                                  Icon(BieuTuong.dongBo, color: themeColor, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+${_dinhDangTien(nopThangQuy)}/tháng',
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
                                      onTap: () async {
                                        final res = await BsNapTienQuy.hienThi(
                                          context,
                                          quy: quy,
                                          danhSachVi: _danhSachVi,
                                        );
                                        if (res == true) {
                                          _hienThongBao('Nạp tiền vào ${quy.tenQuy} thành công!', loai: LoaiThongBao.thanhCong);
                                          _loadDuLieu();
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _taoNutThaoTacNhanh(
                                      icon: BieuTuong.rutTien,
                                      nhan: 'Rút quỹ',
                                      color: MauSac.chiTieu,
                                      onTap: () async {
                                        final res = await BsRutTienQuy.hienThi(
                                          context,
                                          quy: quy,
                                          danhSachVi: _danhSachVi,
                                        );
                                        if (res == true) {
                                          _hienThongBao('Rút quỹ ${quy.tenQuy} thành công!', loai: LoaiThongBao.thanhCong);
                                          _loadDuLieu();
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _taoNutThaoTacNhanh(
                                      icon: BieuTuong.nganSach,
                                      nhan: 'Chỉnh hạn...',
                                      color: MauSac.phu,
                                      onTap: () async {
                                        final res = await BsChinhHanMucQuy.hienThi(
                                          context,
                                          quy: quy,
                                        );
                                        if (res == true) {
                                          _hienThongBao('Cập nhật hạn mức ${quy.tenQuy} thành công!', loai: LoaiThongBao.thanhCong);
                                          _loadDuLieu();
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _taoNutThaoTacNhanh(
                                      icon: BieuTuong.dongHo,
                                      nhan: 'Chỉnh thời...',
                                      color: MauSac.chuPhu,
                                      onTap: () async {
                                        final res = await BsChinhThoiHanQuy.hienThi(
                                          context,
                                          quy: quy,
                                        );
                                        if (res == true) {
                                          _hienThongBao('Cập nhật thời hạn ${quy.tenQuy} thành công!', loai: LoaiThongBao.thanhCong);
                                          _loadDuLieu();
                                        }
                                      },
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
                      onPressed: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManHinhTaoQuyTietKiem(),
                          ),
                        );
                        if (res == true) {
                          _loadDuLieu();
                        }
                      },
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

  /// Khung hiển thị khi chưa có quỹ tiết kiệm nào trong CSDL Supabase
  Widget _taoEmptyStateChuaCoQuy() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: MauSac.nenThe,
        borderRadius: BoGoc.borderVua,
        border: Border.all(color: MauSac.duongVienNhat),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: MauSac.nenNoi,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              BieuTuong.nganSach,
              color: MauSac.chuPhu,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Chưa có khoản tiết kiệm nào',
            style: TextStyle(
              color: MauSac.chuChinh,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bạn chưa có mục tiêu tích lũy nào.\nHãy nhấn nút (+ Tạo khoản tiết kiệm / Mục tiêu mới) bên dưới để bắt đầu!',
            textAlign: TextAlign.center,
            style: TextStyle(color: MauSac.chuPhu, fontSize: 12, height: 1.4),
          ),
        ],
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
