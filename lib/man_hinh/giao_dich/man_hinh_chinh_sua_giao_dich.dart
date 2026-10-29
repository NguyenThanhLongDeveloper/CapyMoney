import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../../giao_dien/chuan_thiet_ke/dap_ung.dart';
import '../../giao_dien/bottom_sheet/bs_lien_ket_tai_khoan.dart';
import '../../giao_dien/thong_bao/thong_bao_giua_man_hinh.dart';
import '../../mo_hinh/danh_muc_model.dart';
import '../../mo_hinh/tai_khoan_ngan_hang_model.dart';
import '../../mo_hinh/giao_dich_model.dart';
import '../../dich_vu/dich_vu_supabase.dart';

/// Màn Hình Chỉnh Sửa Giao Dịch (Edit Transaction Screen)
/// 
/// Cho phép cập nhật số tiền (bàn phím Numpad), loại thu/chi, danh mục, ví thanh toán,
/// ghi chú, ngày giao dịch và đính kèm/thay đổi ảnh chứng từ hóa đơn.
class ManHinhChinhSuaGiaoDich extends StatefulWidget {
  final GiaoDichModel giaoDichCu;

  const ManHinhChinhSuaGiaoDich({
    super.key,
    required this.giaoDichCu,
  });

  @override
  State<ManHinhChinhSuaGiaoDich> createState() => _ManHinhChinhSuaGiaoDichState();
}

class _ManHinhChinhSuaGiaoDichState extends State<ManHinhChinhSuaGiaoDich> {
  /// Loại giao dịch: 'chi_tieu' hoặc 'thu_nhap'
  late String _loaiGiaoDich;

  /// Chuỗi số tiền đang nhập trên Numpad
  late String _chuoiSoTien;

  /// Bộ điều khiển nhập Ghi chú
  final _ghiChuController = TextEditingController();

  /// Ngày phát sinh giao dịch
  late DateTime _ngayGiaoDich;

  /// Danh mục được chọn
  DanhMucModel? _danhMucChon;

  /// Tài khoản / Ví ngân hàng được chọn
  TaiKhoanNganHangModel? _taiKhoanChon;

  /// URL ảnh hóa đơn chứng từ cũ (nếu có)
  String? _urlHoaDonCu;

  /// File ảnh hóa đơn mới được chọn từ Camera/Gallery (Memory State)
  XFile? _anhHoaDonMoiFile;

  /// Trạng thái đang tải dữ liệu danh mục & ví
  bool _dangTaiDuLieu = true;

  /// Trạng thái đang lưu dữ liệu lên Supabase
  bool _dangXuLy = false;

  /// Danh sách danh mục từ Supabase
  List<DanhMucModel> _danhSachDanhMuc = [];

  /// Danh sách ví từ Supabase
  List<TaiKhoanNganHangModel> _danhSachVi = [];

  @override
  void initState() {
    super.initState();
    final gd = widget.giaoDichCu;
    _loaiGiaoDich = gd.loaiGiaoDich;
    _chuoiSoTien = gd.soTien.toInt().toString();
    _ghiChuController.text = gd.ghiChu ?? '';
    _ngayGiaoDich = gd.ngayGiaoDich;
    _urlHoaDonCu = gd.anhHoaDon;
    _loadDuLieu();
  }

  /// Nạp danh sách Danh mục và Ví thực tế từ Supabase CSDL
  Future<void> _loadDuLieu() async {
    setState(() => _dangTaiDuLieu = true);
    try {
      final danhMucList = await DichVuSupabase.layDanhSachDanhMuc();
      final viList = await DichVuSupabase.layDanhSachTaiKhoan();

      if (mounted) {
        setState(() {
          _danhSachDanhMuc = danhMucList;
          _danhSachVi = viList;

          // Chọn sẵn Danh mục cũ
          _danhMucChon = danhMucList.timTheoId(widget.giaoDichCu.danhMucId);

          // Chọn sẵn Ví cũ
          if (widget.giaoDichCu.taiKhoanId != null) {
            final listTK = viList.where((v) => v.id == widget.giaoDichCu.taiKhoanId).toList();
            if (listTK.isNotEmpty) {
              _taiKhoanChon = listTK.first;
            } else if (viList.isNotEmpty) {
              _taiKhoanChon = viList.first;
            }
          } else if (viList.isNotEmpty) {
            _taiKhoanChon = viList.first;
          }

          _dangTaiDuLieu = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi nạp dữ liệu chỉnh sửa: $e');
      if (mounted) setState(() => _dangTaiDuLieu = false);
    }
  }

  /// Chuyển đổi tab Thu Nhập <-> Chi Tiêu
  void _thayDoiLoaiGiaoDich(String loai) {
    if (_loaiGiaoDich == loai) return;
    setState(() {
      _loaiGiaoDich = loai;
      final filteredList = _danhSachDanhMuc.where((d) => d.loai == loai).toList();
      _danhMucChon = filteredList.isNotEmpty ? filteredList.first : null;
    });
  }

  /// Xử lý bấm phím số Numpad (1..9, 0, 000, ⌫)
  void _nhapPhimNumpad(String val) {
    setState(() {
      if (val == 'xoa') {
        if (_chuoiSoTien.length > 1) {
          _chuoiSoTien = _chuoiSoTien.substring(0, _chuoiSoTien.length - 1);
        } else {
          _chuoiSoTien = '0';
        }
      } else if (val == '0' || val == '000') {
        if (_chuoiSoTien != '0') {
          if (_chuoiSoTien.length + val.length <= 12) {
            _chuoiSoTien += val;
          }
        }
      } else {
        if (_chuoiSoTien == '0') {
          _chuoiSoTien = val;
        } else {
          if (_chuoiSoTien.length < 12) {
            _chuoiSoTien += val;
          }
        }
      }
    });
  }

  /// Xóa trắng về 0 đ
  void _xoaTrangSoTien() {
    setState(() => _chuoiSoTien = '0');
  }

  /// Cộng nhanh tiền (+50k, +100k...)
  void _congNhanhTien(double addVal) {
    final current = double.tryParse(_chuoiSoTien) ?? 0.0;
    final total = current + addVal;
    setState(() => _chuoiSoTien = total.toInt().toString());
  }

  /// Lấy giá trị double số tiền
  double get _soTienParsed => double.tryParse(_chuoiSoTien) ?? 0.0;

  /// Định dạng tiền VND đẹp (ví dụ: 65.000)
  String get _chuoiSoTienFormatted {
    final val = _soTienParsed;
    final String numStr = val.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  /// Chọn ảnh hóa đơn chứng từ mới từ Camera hoặc Gallery
  Future<void> _chonAnhHoaDon(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _anhHoaDonMoiFile = pickedFile;
      });
    }
  }

  /// Mở Hộp thoại Chọn Ngày
  Future<void> _chonNgayGiaoDich() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _ngayGiaoDich,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: MauSac.chuDao,
              onPrimary: Colors.black,
              surface: MauSac.nenThe,
              onSurface: MauSac.chuChinh,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _ngayGiaoDich = picked);
    }
  }

  /// Thao tác Cập nhật Giao dịch lên Supabase CSDL
  Future<void> _xuLyCapNhatGiaoDich() async {
    final user = DichVuSupabase.nguoiDungHienTai;
    if (user == null) {
      _hienThongBao('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại!');
      return;
    }

    final double soTienMoi = _soTienParsed;
    if (soTienMoi <= 0) {
      _hienThongBao('Vui lòng nhập số tiền lớn hơn 0 đ');
      return;
    }

    if (_danhMucChon == null) {
      _hienThongBao('Vui lòng chọn danh mục thu chi');
      return;
    }

    if (_taiKhoanChon == null) {
      _hienThongBao('Vui lòng chọn tài khoản ví thanh toán');
      return;
    }

    // RÀNG BUỘC SỐ DƯ KHI CHI TIÊU:
    if (_loaiGiaoDich == 'chi_tieu') {
      double soDuHienCo = _taiKhoanChon!.soDu;
      // Nếu ví chọn mới trùng ví cũ -> Hoàn trả tác động cũ để kiểm tra số dư hiệu dụng
      if (_taiKhoanChon!.id == widget.giaoDichCu.taiKhoanId) {
        soDuHienCo += widget.giaoDichCu.loaiGiaoDich == 'chi_tieu'
            ? widget.giaoDichCu.soTien
            : -widget.giaoDichCu.soTien;
      }

      if (soDuHienCo < soTienMoi) {
        _hienThongBao(
          'Số dư ví ${_taiKhoanChon!.tenNganHang} không đủ để chi tiêu! '
          '(Khả dụng: ${soDuHienCo.toInt()} đ, Cần: ${_chuoiSoTienFormatted} đ)',
        );
        return;
      }
    }

    setState(() => _dangXuLy = true);

    try {
      String? urlHoaDonFinal = _urlHoaDonCu;

      // 1. Nếu có chọn ảnh hóa đơn mới -> Upload lên Supabase Storage
      if (_anhHoaDonMoiFile != null) {
        final urlMoi = await DichVuSupabase.taiHoaDonLenStorage(_anhHoaDonMoiFile!, user.id);
        if (urlMoi != null) {
          urlHoaDonFinal = urlMoi;
        }
      }

      // 2. Khởi tạo đối tượng GiaoDichModel mới
      final giaoDichMoi = GiaoDichModel(
        id: widget.giaoDichCu.id,
        nguoiDungId: user.id,
        taiKhoanId: _taiKhoanChon!.id,
        danhMucId: _danhMucChon!.id,
        loaiGiaoDich: _loaiGiaoDich,
        soTien: soTienMoi,
        ghiChu: _ghiChuController.text.trim(),
        anhHoaDon: urlHoaDonFinal,
        ngayGiaoDich: _ngayGiaoDich,
        trangThai: _loaiGiaoDich == 'chi_tieu' ? 'da_tru' : 'da_nhan',
      );

      // 3. Đẩy thông tin cập nhật lên Supabase (Tự động hoàn trả ví cũ và áp dụng ví mới)
      final success = await DichVuSupabase.capNhatGiaoDich(
        giaoDichCu: widget.giaoDichCu,
        giaoDichMoi: giaoDichMoi,
      );

      if (!mounted) return;

      if (success) {
        ThongBaoGiuaManHinh.hienThi(
          context,
          noiDung: 'Cập nhật giao dịch thành công!',
          loai: LoaiThongBao.thanhCong,
        );

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        _hienThongBao('Không thể cập nhật giao dịch. Vui lòng thử lại!');
      }
    } catch (e) {
      if (mounted) _hienThongBao('Lỗi cập nhật giao dịch: $e');
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
    _ghiChuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isChiTieu = _loaiGiaoDich == 'chi_tieu';
    final Color colorTheme = isChiTieu ? MauSac.chiTieu : MauSac.thuNhap;
    final List<DanhMucModel> filteredDanhMuc = _danhSachDanhMuc.where((d) => d.loai == _loaiGiaoDich).toList();

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
          'Chỉnh Sửa Giao Dịch',
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

                // SECTION 1: THANH TAB CHUYỂN ĐỔI (CHI TIÊU <-> THU NHẬP)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: MauSac.nenThe,
                    borderRadius: BoGoc.borderTron,
                    border: Border.all(color: MauSac.duongVienNhat),
                  ),
                  child: Row(
                    children: [
                      // Tab Chi tiêu
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _thayDoiLoaiGiaoDich('chi_tieu'),
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: isChiTieu ? MauSac.chiTieu.withValues(alpha: 0.25) : Colors.transparent,
                              borderRadius: BoGoc.borderTron,
                              border: isChiTieu ? Border.all(color: MauSac.chiTieu, width: 1) : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(BieuTuong.xuHuongGiam, color: isChiTieu ? MauSac.chiTieu : MauSac.chuPhu, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Chi tiêu',
                                  style: TextStyle(
                                    color: isChiTieu ? MauSac.chiTieu : MauSac.chuPhu,
                                    fontSize: 14,
                                    fontWeight: isChiTieu ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Tab Thu nhập
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _thayDoiLoaiGiaoDich('thu_nhap'),
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: !isChiTieu ? MauSac.thuNhap.withValues(alpha: 0.25) : Colors.transparent,
                              borderRadius: BoGoc.borderTron,
                              border: !isChiTieu ? Border.all(color: MauSac.thuNhap, width: 1) : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(BieuTuong.xuHuongTang, color: !isChiTieu ? MauSac.thuNhap : MauSac.chuPhu, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Thu nhập',
                                  style: TextStyle(
                                    color: !isChiTieu ? MauSac.thuNhap : MauSac.chuPhu,
                                    fontSize: 14,
                                    fontWeight: !isChiTieu ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),

                // SECTION 2: Ô HIỂN THỊ SỐ TIỀN & CHIP CỘNG NHANH
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(BieuTuong.chamTron, color: colorTheme, size: 8),
                          const SizedBox(width: 6),
                          Text(
                            isChiTieu ? 'SỐ TIỀN CHI TIÊU' : 'SỐ TIỀN THU NHẬP',
                            style: const TextStyle(
                              color: MauSac.chuPhu,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Chuỗi số tiền cỡ lớn
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          FittedBox(
                            child: Text(
                              _chuoiSoTienFormatted,
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: colorTheme,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'đ',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colorTheme,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Hàng Chip Cộng Tiền Nhanh & Nút Xóa
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isChiTieu) ...[
                              _taoChipCongTien('+50k', 50000),
                              _taoChipCongTien('+100k', 100000),
                              _taoChipCongTien('+200k', 200000),
                              _taoChipXoaTrang('Xóa trắng'),
                            ] else ...[
                              _taoChipCongTien('+500k', 500000),
                              _taoChipCongTien('+1M', 1000000),
                              _taoChipCongTien('+5M', 5000000),
                              _taoChipCongTien('+10M', 10000000),
                              _taoChipXoaTrang('⌫ Xóa'),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),

                // SECTION 3: BÀN PHÍM SỐ NUMPAD 3x4
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: MauSac.nenThe,
                    borderRadius: BoGoc.borderLon,
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
                ),

                const SizedBox(height: KhoangCach.lon),

                // SECTION 4: DANH MỤC THU CHI (2x4 GRID)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Danh mục',
                      style: TextStyle(
                        color: MauSac.chuChinh,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${filteredDanhMuc.length} lựa chọn',
                      style: const TextStyle(color: MauSac.chuPhu, fontSize: 12),
                    ),
                  ],
                ),

                const SizedBox(height: KhoangCach.nho),

                if (_dangTaiDuLieu)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: MauSac.chuDao)))
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filteredDanhMuc.length,
                    itemBuilder: (context, index) {
                      final dm = filteredDanhMuc[index];
                      final bool isSelected = _danhMucChon?.id == dm.id;

                      return GestureDetector(
                        onTap: () => setState(() => _danhMucChon = dm),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isChiTieu ? MauSac.chiTieu.withValues(alpha: 0.15) : MauSac.chuDao.withValues(alpha: 0.15))
                                : MauSac.nenThe,
                            borderRadius: BoGoc.borderVua,
                            border: Border.all(
                              color: isSelected
                                  ? (isChiTieu ? MauSac.chiTieu : MauSac.chuDao)
                                  : MauSac.duongVienNhat,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isChiTieu ? MauSac.chiTieu : MauSac.chuDao)
                                      : MauSac.nenThe,
                                  borderRadius: BoGoc.borderNho,
                                ),
                                child: Icon(
                                  dm.iconData,
                                  color: isSelected
                                      ? Colors.black
                                      : MauSac.chuPhu,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: Text(
                                  dm.tenDanhMuc,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : MauSac.chuPhu,
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: KhoangCach.lon),

                // SECTION 5: TÀI KHOẢN VÍ & THỜI GIAN
                Container(
                  padding: KhoangCach.lToanBoChuan,
                  decoration: BoxDecoration(
                    color: MauSac.nenThe,
                    borderRadius: BoGoc.borderVua,
                    border: Border.all(color: MauSac.duongVienNhat),
                  ),
                  child: Column(
                    children: [
                      // Dòng chọn Ví thanh toán
                      GestureDetector(
                        onTap: () async {
                          await BsLienKetTaiKhoan.hienThi(context);
                          final reloadedVi = await DichVuSupabase.layDanhSachTaiKhoan();
                          if (mounted) setState(() => _danhSachVi = reloadedVi);
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: MauSac.nenNoi,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(BieuTuong.nganHang, color: MauSac.chuDao, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isChiTieu ? 'Ví thanh toán' : 'Tài khoản nhận tiền',
                                    style: const TextStyle(color: MauSac.chuPhu, fontSize: 11),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _taiKhoanChon != null
                                        ? '${_taiKhoanChon!.tenNganHang} •• ${_taiKhoanChon!.soTaiKhoan.length >= 4 ? _taiKhoanChon!.soTaiKhoan.substring(_taiKhoanChon!.soTaiKhoan.length - 4) : _taiKhoanChon!.soTaiKhoan}'
                                        : 'Chưa liên kết ví',
                                    style: const TextStyle(
                                      color: MauSac.chuChinh,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(BieuTuong.muiTenXuong, color: MauSac.chuDao, size: 20),
                          ],
                        ),
                      ),

                      const Divider(color: MauSac.duongVienNhat, height: 24),

                      // Dòng chọn Ngày giao dịch
                      GestureDetector(
                        onTap: _chonNgayGiaoDich,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: MauSac.nenNoi,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(BieuTuong.lichNgay, color: MauSac.chuDao, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Ngày giao dịch', style: TextStyle(color: MauSac.chuPhu, fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_ngayGiaoDich.day.toString().padLeft(2, '0')}/${_ngayGiaoDich.month.toString().padLeft(2, '0')}/${_ngayGiaoDich.year}',
                                    style: const TextStyle(
                                      color: MauSac.chuChinh,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(BieuTuong.lichSua, color: MauSac.chuPhu, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),

                // SECTION 6: GHI CHÚ
                const Text('Ghi chú giao dịch', style: TextStyle(color: MauSac.chuChinh, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _ghiChuController,
                  style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Nhập diễn giải (Ăn trưa, Đổ xăng, Thưởng KPI...)',
                    hintStyle: const TextStyle(color: MauSac.chuMo),
                    prefixIcon: const Icon(BieuTuong.ghiChuSua, color: MauSac.chuPhu, size: 20),
                    filled: true,
                    fillColor: MauSac.nenThe,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                    enabledBorder: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.duongVienNhat)),
                    focusedBorder: OutlineInputBorder(borderRadius: BoGoc.borderVua, borderSide: const BorderSide(color: MauSac.chuDao)),
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),

                // SECTION 7: ĐÍNH KÈM / ĐỔI ÁNH HÓA ĐƠN
                Container(
                  padding: KhoangCach.lToanBoChuan,
                  decoration: BoxDecoration(
                    color: MauSac.nenThe,
                    borderRadius: BoGoc.borderVua,
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
                              Icon(BieuTuong.mayAnh, color: MauSac.chuDao, size: 18),
                              SizedBox(width: 8),
                              Text('Ảnh hóa đơn & Chứng từ', style: TextStyle(color: MauSac.chuChinh, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          if (_anhHoaDonMoiFile != null || _urlHoaDonCu != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _anhHoaDonMoiFile = null;
                                  _urlHoaDonCu = null;
                                });
                              },
                              child: const Text('Xóa ảnh', style: TextStyle(color: MauSac.chiTieu, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Preview Ảnh đã chọn mới hoặc URL ảnh cũ
                      if (_anhHoaDonMoiFile != null)
                        FutureBuilder<Uint8List>(
                          future: _anhHoaDonMoiFile!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return ClipRRect(
                                borderRadius: BoGoc.borderVua,
                                child: Image.memory(snapshot.data!, height: 120, width: double.infinity, fit: BoxFit.cover),
                              );
                            }
                            return const Center(child: CircularProgressIndicator(color: MauSac.chuDao));
                          },
                        )
                      else if (_urlHoaDonCu != null)
                        ClipRRect(
                          borderRadius: BoGoc.borderVua,
                          child: Image.network(_urlHoaDonCu!, height: 120, width: double.infinity, fit: BoxFit.cover),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _chonAnhHoaDon(ImageSource.camera),
                                icon: const Icon(BieuTuong.mayAnhChup, color: MauSac.chuDao, size: 18),
                                label: const Text('Chụp ảnh', style: TextStyle(color: MauSac.chuChinh, fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: MauSac.nenNoi,
                                  side: const BorderSide(color: MauSac.duongVienNhat),
                                  shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _chonAnhHoaDon(ImageSource.gallery),
                                icon: const Icon(BieuTuong.thuVienAnh, color: MauSac.phu, size: 18),
                                label: const Text('Thư viện', style: TextStyle(color: MauSac.chuChinh, fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: MauSac.nenNoi,
                                  side: const BorderSide(color: MauSac.duongVienNhat),
                                  shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: KhoangCach.sieuLon),

                // SECTION 8: NÚT CTA CẬP NHẬT GIAO DỊCH
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _dangXuLy ? null : _xuLyCapNhatGiaoDich,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MauSac.chuDao,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BoGoc.borderTron,
                      ),
                    ),
                    child: _dangXuLy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(BieuTuong.dauTichTron, color: Colors.black, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Cập nhật giao dịch',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
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

  /// Nút phím Numpad
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
            shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
          ),
          child: isIcon
              ? const Icon(BieuTuong.xoaLui, color: MauSac.chuPhu, size: 20)
              : Text(
                  val,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MauSac.chuChinh),
                ),
        ),
      ),
    );
  }

  /// Chip cộng nhanh tiền
  Widget _taoChipCongTien(String nhan, double addVal) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(nhan, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        backgroundColor: MauSac.nenNoi,
        labelStyle: const TextStyle(color: MauSac.chuDao),
        side: const BorderSide(color: MauSac.duongVienNhat),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: () => _congNhanhTien(addVal),
      ),
    );
  }

  /// Chip xóa trắng
  Widget _taoChipXoaTrang(String nhan) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(nhan, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        backgroundColor: MauSac.chiTieu.withValues(alpha: 0.15),
        labelStyle: const TextStyle(color: MauSac.chiTieu),
        side: const BorderSide(color: MauSac.chiTieu),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: _xoaTrangSoTien,
      ),
    );
  }
}
