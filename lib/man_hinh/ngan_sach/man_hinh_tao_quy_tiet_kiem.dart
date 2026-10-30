import 'package:flutter/material.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../../giao_dien/chuan_thiet_ke/dap_ung.dart';
import '../../giao_dien/thong_bao/thong_bao_giua_man_hinh.dart';
import '../../mo_hinh/quy_tiet_kiem_model.dart';
import '../../mo_hinh/tai_khoan_ngan_hang_model.dart';
import '../../dich_vu/dich_vu_supabase.dart';

/// Màn Hình Tạo Khoản Tiết Kiệm & Mục Tiêu Mới (Create Savings Goal Screen)
/// 
/// Thiết kế chuẩn Kinetic Neo-Fintech Dark Mode khớp 100% UI mockup:
/// Chọn Biểu tượng mục tiêu, Tên mục tiêu, Số tiền mục tiêu, Số tiền gửi ban đầu (Trích từ ví nguồn),
/// Kế hoạch dự kiến (3, 6, 12 tháng) và tính toán tốc độ nộp/tháng tự động.
class ManHinhTaoQuyTietKiem extends StatefulWidget {
  const ManHinhTaoQuyTietKiem({super.key});

  @override
  State<ManHinhTaoQuyTietKiem> createState() => _ManHinhTaoQuyTietKiemState();
}

class _ManHinhTaoQuyTietKiemState extends State<ManHinhTaoQuyTietKiem> {
  /// Key Biểu tượng đang chọn: 'xeMay', 'mayBay', 'hoaDon', 'lapTop', 'khienBaoMat', 'hocTap'
  String _bieuTuongChon = 'xeMay';

  /// Controller nhập Tên mục tiêu tiết kiệm
  final _tenQuyController = TextEditingController(text: 'Mua xe máy mới');

  /// Chuỗi số tiền mục tiêu (Ví dụ '50000000')
  String _soTienMucTieuText = '50000000';

  /// Chuỗi số tiền gửi ban đầu (Ví dụ '5000000')
  String _soTienGuiBanDauText = '5000000';

  /// Kỳ hạn tích lũy theo tháng: 3, 6, 12, hoặc 24
  int _kyHanThangChon = 12;

  /// Ví nguồn trích tiền ban đầu
  TaiKhoanNganHangModel? _taiKhoanNguonChon;

  /// Trạng thái đang nạp danh sách ví từ CSDL
  bool _dangTaiVi = true;

  /// Trạng thái đang lưu dữ liệu lên Supabase
  bool _dangXuLy = false;

  /// Danh sách ví từ CSDL
  List<TaiKhoanNganHangModel> _danhSachVi = [];

  @override
  void initState() {
    super.initState();
    _loadDanhSachVi();
  }

  /// Nạp danh sách Ví ngân hàng từ CSDL Supabase
  Future<void> _loadDanhSachVi() async {
    setState(() => _dangTaiVi = true);
    try {
      final listVi = await DichVuSupabase.layDanhSachTaiKhoan();
      if (mounted) {
        setState(() {
          _danhSachVi = listVi;
          if (listVi.isNotEmpty) {
            _taiKhoanNguonChon = listVi.firstWhere(
              (tk) => tk.laNhanChinh,
              orElse: () => listVi.first,
            );
          }
          _dangTaiVi = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi nạp danh sách ví: $e');
      if (mounted) setState(() => _dangTaiVi = false);
    }
  }

  /// Lấy số tiền double mục tiêu
  double get _soTienMucTieuParsed => double.tryParse(_soTienMucTieuText) ?? 0.0;

  /// Lấy số tiền double gửi ban đầu
  double get _soTienGuiBanDauParsed => double.tryParse(_soTienGuiBanDauText) ?? 0.0;

  /// Định dạng tiền VND dạng đầy đủ (ví dụ: 50.000.000)
  String _dinhDangTien(double amount) {
    final String numStr = amount.abs().toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  /// Tính phần trăm gửi ban đầu so với mục tiêu
  double get _phanTramBanDau {
    final target = _soTienMucTieuParsed;
    final initial = _soTienGuiBanDauParsed;
    if (target <= 0) return 0;
    return ((initial / target) * 100).clamp(0, 100);
  }

  /// Tính số tiền cần gửi hàng tháng
  double get _soTienCanGuiHangThang {
    final target = _soTienMucTieuParsed;
    final initial = _soTienGuiBanDauParsed;
    final conLai = target > initial ? target - initial : 0.0;
    return conLai / _kyHanThangChon;
  }

  /// Tính ngày tháng dự kiến hoàn thành
  String get _thangHoanThanhFormatted {
    final now = DateTime.now();
    final targetDate = DateTime(now.year, now.month + _kyHanThangChon, now.day);
    final mo = targetDate.month.toString().padLeft(2, '0');
    return 'Tháng $mo/${targetDate.year}';
  }

  /// Thao tác tạo Khoản Tiết Kiệm Ngay
  Future<void> _xuLyTaoQuyTietKiem() async {
    final user = DichVuSupabase.nguoiDungHienTai;
    if (user == null) {
      _hienThongBao('Vui lòng đăng nhập để tạo khoản tiết kiệm');
      return;
    }

    final tenQuy = _tenQuyController.text.trim();
    final mucTieu = _soTienMucTieuParsed;
    final guiBanDau = _soTienGuiBanDauParsed;

    if (tenQuy.isEmpty) {
      _hienThongBao('Vui lòng nhập tên mục tiêu tiết kiệm');
      return;
    }

    if (mucTieu <= 0) {
      _hienThongBao('Số tiền mục tiêu phải lớn hơn 0 đ');
      return;
    }

    if (guiBanDau > mucTieu) {
      _hienThongBao('Số tiền gửi ban đầu không được lớn hơn số tiền mục tiêu!');
      return;
    }

    // KHÔNG ĐỦ SỐ DƯ: Kiểm tra ví nguồn nếu gửi ban đầu > 0
    if (guiBanDau > 0) {
      if (_taiKhoanNguonChon == null) {
        _hienThongBao('Vui lòng chọn tài khoản ví nguồn để trích tiền gửi ban đầu!');
        return;
      }

      final double soDuHienCo = _taiKhoanNguonChon!.soDu;
      if (soDuHienCo < guiBanDau) {
        _hienThongBao(
          'Số dư ví ${_taiKhoanNguonChon!.tenNganHang} không đủ để gửi ban đầu! '
          '(Số dư hiện có: ${_dinhDangTien(soDuHienCo)} đ, Cần gửi: ${_dinhDangTien(guiBanDau)} đ)',
        );
        return;
      }
    }

    setState(() => _dangXuLy = true);

    try {
      final ngayVeDich = DateTime.now().add(Duration(days: _kyHanThangChon * 30));

      // 1. Tạo bản ghi khoản tiết kiệm mới trong Supabase
      final quyMoi = QuyTietKiemModel(
        id: '',
        nguoiDungId: user.id,
        tenQuy: tenQuy,
        bieuTuong: _bieuTuongChon,
        soTienMucTieu: mucTieu,
        soTienHienCo: guiBanDau,
        nguonTrichId: _taiKhoanNguonChon?.id,
        kyHanThang: _kyHanThangChon,
        ngayVeDich: ngayVeDich,
        nhacNhoDinhKy: true,
      );

      final quyDaTao = await DichVuSupabase.taoQuyMoi(quyMoi);

      // 2. Nếu gửi ban đầu > 0 -> Trừ số dư khỏi ví ngân hàng tương ứng & ghi nhật ký
      if (guiBanDau > 0 && _taiKhoanNguonChon != null) {
        await DichVuSupabase.capNhatSoDuQuy(
          quyId: quyDaTao.id,
          soTienThayDoi: guiBanDau,
          loaiThaoTac: 'nap_tien',
          lyDo: 'Gửi ban đầu vào quỹ "$tenQuy"',
          taiKhoanId: _taiKhoanNguonChon!.id,
        );

        // Trừ tiền khỏi tài khoản ngân hàng
        final double soDuSauTru = _taiKhoanNguonChon!.soDu - guiBanDau;
        await DichVuSupabase.client
            .from('tai_khoan_ngan_hang')
            .update({'so_du': soDuSauTru})
            .eq('id', _taiKhoanNguonChon!.id);
      }

      if (!mounted) return;

      ThongBaoGiuaManHinh.hienThi(
        context,
        noiDung: 'Tạo khoản tiết kiệm "$tenQuy" thành công!',
        loai: LoaiThongBao.thanhCong,
      );

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      if (mounted) _hienThongBao('Không thể tạo khoản tiết kiệm: $e');
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
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
  void dispose() {
    _tenQuyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MauSac.nenChinh,
      appBar: AppBar(
        backgroundColor: MauSac.nenChinh,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(BieuTuong.muiTenTrai, color: MauSac.chuChinh, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tạo Khoản Tiết Kiệm',
          style: TextStyle(
            color: MauSac.chuChinh,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: DapUng.bocKhungForm(
          child: SingleChildScrollView(
            padding: KhoangCach.lNgangLon,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: KhoangCach.nho),

                // SECTION 1: CARD BIỂU TƯỢNG MỤC TIÊU
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
                      const Text(
                        'BIỂU TƯỢNG MỤC TIÊU',
                        style: TextStyle(
                          color: MauSac.chuPhu,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: QuyTietKiemModel.danhSachBieuTuongGoiY.map((item) {
                            final key = item.key;
                            final label = item.label;
                            final icon = item.icon;
                            final bool isSelected = _bieuTuongChon == key;

                            return GestureDetector(
                              onTap: () => setState(() => _bieuTuongChon = key),
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? MauSac.chuDao.withValues(alpha: 0.2) : MauSac.nenNoi,
                                  borderRadius: BoGoc.borderVua,
                                  border: Border.all(
                                    color: isSelected ? MauSac.chuDao : MauSac.duongVienNhat,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      icon,
                                      color: isSelected ? MauSac.chuDao : MauSac.chuPhu,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        color: isSelected ? MauSac.chuDao : MauSac.chuPhu,
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),

                // SECTION 2: TÊN MỤC TIÊU TIẾT KIỆM
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
                      const Text(
                        'TÊN MỤC TIÊU TIẾT KIỆM',
                        style: TextStyle(
                          color: MauSac.chuPhu,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _tenQuyController,
                        style: const TextStyle(color: MauSac.chuChinh, fontSize: 16, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'Nhập tên mục tiêu (Mua xe, Du lịch...)',
                          hintStyle: const TextStyle(color: MauSac.chuMo, fontSize: 14),
                          suffixIcon: const Icon(BieuTuong.chinhSua, color: MauSac.chuPhu, size: 20),
                          filled: true,
                          fillColor: MauSac.nenNoi,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                          enabledBorder: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                          focusedBorder: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.chuDao)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),

                // SECTION 3: SỐ TIỀN MỤC TIÊU & CHIP THÊM TIỀN NHANH
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
                          const Text(
                            'SỐ TIỀN MỤC TIÊU',
                            style: TextStyle(
                              color: MauSac.chuPhu,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _soTienMucTieuText = '50000000'),
                            child: Row(
                              children: const [
                                Icon(BieuTuong.lamMoi, color: MauSac.chuPhu, size: 12),
                                SizedBox(width: 4),
                                Text('Đặt lại', style: TextStyle(color: MauSac.chuPhu, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Chuỗi hiển thị Số tiền mục tiêu cỡ lớn
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: MauSac.chuChinh, fontSize: 32, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              controller: TextEditingController(text: _dinhDangTien(_soTienMucTieuParsed)),
                              onChanged: (val) {
                                final clean = val.replaceAll('.', '').replaceAll(' ', '');
                                setState(() => _soTienMucTieuText = clean);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'VND',
                            style: TextStyle(color: MauSac.chuPhu, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Hàng Chip Tiền Nhanh (+5 Tr, +10 Tr, +20 Tr, +50 Tr)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _taoChipTienMucTieu('+5 Tr', 5000000),
                            _taoChipTienMucTieu('+10 Tr', 10000000),
                            _taoChipTienMucTieu('+20 Tr', 20000000),
                            _taoChipTienMucTieu('+50 Tr', 50000000),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),

                // SECTION 4: SỐ TIỀN GỬI BAN ĐẦU & NGUỒN TRÍCH TIỀN
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
                          const Text(
                            'SỐ TIỀN GỬI BAN ĐẦU',
                            style: TextStyle(
                              color: MauSac.chuPhu,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _soTienGuiBanDauText = '0'),
                            child: const Text(
                              'Để sau (0đ)',
                              style: TextStyle(color: MauSac.chuDao, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Ô nhập Số tiền gửi ban đầu
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: MauSac.chuChinh, fontSize: 24, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              controller: TextEditingController(text: _dinhDangTien(_soTienGuiBanDauParsed)),
                              onChanged: (val) {
                                final clean = val.replaceAll('.', '').replaceAll(' ', '');
                                setState(() => _soTienGuiBanDauText = clean);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('đ', style: TextStyle(color: MauSac.chuDao, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Subtitle Tiến độ ban đầu %
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Khởi đầu ngay', style: TextStyle(color: MauSac.chuPhu, fontSize: 11)),
                          Text(
                            '${_phanTramBanDau.toStringAsFixed(0)}% mục tiêu',
                            style: const TextStyle(color: MauSac.chuDao, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_phanTramBanDau / 100).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: MauSac.nenNoi,
                          color: MauSac.chuDao,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Dòng chọn Ví Nguồn Trích Tiền
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Trích từ nguồn:', style: TextStyle(color: MauSac.chuPhu, fontSize: 12)),
                          _dangTaiVi
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MauSac.chuDao))
                              : PopupMenuButton<TaiKhoanNganHangModel>(
                                  color: MauSac.nenThe,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BoGoc.borderVua,
                                    side: BorderSide(color: MauSac.duongVienNhat),
                                  ),
                                  onSelected: (tk) => setState(() => _taiKhoanNguonChon = tk),
                                  itemBuilder: (context) {
                                    return _danhSachVi.map((tk) {
                                      final soCuoi = tk.soTaiKhoan.length >= 4
                                          ? tk.soTaiKhoan.substring(tk.soTaiKhoan.length - 4)
                                          : tk.soTaiKhoan;
                                      return PopupMenuItem(
                                        value: tk,
                                        child: Text('${tk.tenNganHang} •• $soCuoi (Dư: ${_dinhDangTien(tk.soDu)})',
                                            style: const TextStyle(color: MauSac.chuChinh, fontSize: 12)),
                                      );
                                    }).toList();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: MauSac.nenNoi,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: MauSac.duongVienNhat),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(color: MauSac.thuNhap, shape: BoxShape.circle),
                                          child: const Text('VCB', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _taiKhoanNguonChon != null
                                              ? '${_taiKhoanNguonChon!.tenNganHang} •• ${_taiKhoanNguonChon!.soTaiKhoan.length >= 4 ? _taiKhoanNguonChon!.soTaiKhoan.substring(_taiKhoanNguonChon!.soTaiKhoan.length - 4) : _taiKhoanNguonChon!.soTaiKhoan}'
                                              : 'Chọn ví nguồn',
                                          style: const TextStyle(color: MauSac.chuChinh, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(BieuTuong.muiTenXuong, color: MauSac.chuPhu, size: 16),
                                      ],
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),

                // SECTION 5: KẾ HOẠCH DỰ KIẾN (CHIP 3, 6, 12 THÁNG & BẢNG DỰ TÍNH)
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
                      const Text(
                        'KẾ HOẠCH DỰ KIẾN',
                        style: TextStyle(
                          color: MauSac.chuPhu,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Hàng Chip Kỳ Hạn (3 tháng, 6 tháng, 12 tháng, Tuỳ chọn)
                      Row(
                        children: [
                          _taoChipKyHan(3, '3 tháng'),
                          _taoChipKyHan(6, '6 tháng'),
                          _taoChipKyHan(12, '12 tháng'),
                          _taoChipKyHan(24, 'Tuỳ chọn'),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Banner Bảng Dự Tính Nộp Mỗi Tháng
                      Container(
                        padding: KhoangCach.lToanBoChuan,
                        decoration: BoxDecoration(
                          color: MauSac.nenNoi,
                          borderRadius: BoGoc.borderVua,
                          border: Border.all(color: MauSac.duongVienNhat),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: MauSac.chuDao.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(BieuTuong.lichThang, color: MauSac.chuDao, size: 20),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('MỖI THÁNG CẦN GỬI', style: TextStyle(color: MauSac.chuPhu, fontSize: 10, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '~ ${_dinhDangTien(_soTienCanGuiHangThang)}/tháng',
                                    style: const TextStyle(color: MauSac.chuDao, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),

                            // Badge Tím Dự kiến hoàn thành
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Text('Dự kiến hoàn thành', style: TextStyle(color: Color(0xFFA855F7), fontSize: 9)),
                                  const SizedBox(height: 2),
                                  Text(_thangHoanThanhFormatted, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: KhoangCach.sieuLon),

                // SECTION 6: NÚT CTA "TẠO KHOẢN TIẾT KIỆM NGAY"
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _dangXuLy ? null : _xuLyTaoQuyTietKiem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MauSac.chuDao,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BoGoc.borderTron),
                    ),
                    child: _dangXuLy
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(BieuTuong.capybaraThantai, color: Colors.black, size: 22),
                              SizedBox(width: 8),
                              FittedBox(
                                child: Text(
                                  '+ Tạo khoản tiết kiệm ngay',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: KhoangCach.sieuLon),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Chip Kỳ Hạn Khung Kế Hoạch
  Widget _taoChipKyHan(int valMonths, String nhan) {
    final bool isSelected = _kyHanThangChon == valMonths;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _kyHanThangChon = valMonths),
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          height: 38,
          decoration: BoxDecoration(
            color: isSelected ? MauSac.chuDao.withValues(alpha: 0.2) : MauSac.nenNoi,
            borderRadius: BoGoc.borderVua,
            border: Border.all(
              color: isSelected ? MauSac.chuDao : MauSac.duongVienNhat,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              nhan,
              style: TextStyle(
                color: isSelected ? MauSac.chuDao : MauSac.chuPhu,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Chip Số Tiền Mục Tiêu
  Widget _taoChipTienMucTieu(String nhan, double soTien) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(nhan, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        backgroundColor: MauSac.nenNoi,
        labelStyle: const TextStyle(color: MauSac.chuDao),
        side: const BorderSide(color: MauSac.duongVienNhat),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: () {
          final cur = _soTienMucTieuParsed;
          final total = cur + soTien;
          setState(() => _soTienMucTieuText = total.toInt().toString());
        },
      ),
    );
  }
}
