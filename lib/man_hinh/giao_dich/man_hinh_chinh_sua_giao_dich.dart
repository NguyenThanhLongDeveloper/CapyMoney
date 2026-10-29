import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../../giao_dien/chuan_thiet_ke/dap_ung.dart';
import '../../giao_dien/thong_bao/thong_bao_giua_man_hinh.dart';
import '../../giao_dien/bottom_sheet/bs_lien_ket_tai_khoan.dart';
import '../../mo_hinh/danh_muc_model.dart';
import '../../mo_hinh/tai_khoan_ngan_hang_model.dart';
import '../../mo_hinh/giao_dich_model.dart';
import '../../dich_vu/dich_vu_supabase.dart';

/// Màn Hình Chỉnh Sửa Giao Dịch (Edit Transaction Screen)
/// 
/// Thiết kế chuẩn UI khớp 100% Màn hình Thêm giao dịch:
/// Bàn phím số Numpad 3x4, Chip cộng tiền nhanh, Lưới chọn danh mục 2x4, Chọn ví & thời gian,
/// Tải/thay đổi ảnh chứng từ hóa đơn, nhưng giữ lại tiêu đề "Chỉnh Sửa Giao Dịch" và nút "Cập nhật giao dịch".
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

  /// Chuỗi số tiền đang nhập từ Numpad
  late String _soTienText;

  /// Bộ điều khiển nhập Ghi chú
  final _ghiChuController = TextEditingController();

  /// Danh mục được chọn
  DanhMucModel? _danhMucChon;

  /// Tài khoản / Ví được chọn
  TaiKhoanNganHangModel? _taiKhoanChon;

  /// Ngày giờ phát sinh giao dịch
  late DateTime _ngayGiaoDich;

  /// URL ảnh hóa đơn chứng từ cũ (nếu có)
  String? _urlHoaDonCu;

  /// File ảnh hóa đơn mới được chọn từ Camera/Gallery (Memory State)
  XFile? _anhHoaDonMoiFile;

  /// Trạng thái đang nạp danh mục & ví
  bool _dangTaiDuLieu = true;

  /// Trạng thái đang lưu giao dịch
  bool _dangXuLy = false;

  /// Danh sách danh mục lấy từ CSDL
  List<DanhMucModel> _danhSachDanhMuc = [];

  /// Danh sách tài khoản ví lấy từ CSDL
  List<TaiKhoanNganHangModel> _danhSachTaiKhoan = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final gd = widget.giaoDichCu;
    _loaiGiaoDich = gd.loaiGiaoDich;
    _soTienText = gd.soTien.toInt().toString();
    _ghiChuController.text = gd.ghiChu ?? '';
    _ngayGiaoDich = gd.ngayGiaoDich;
    _urlHoaDonCu = gd.anhHoaDon;
    _loadDuLieu();
  }

  /// Nạp danh sách Danh mục và Ví liên kết thực tế từ CSDL Supabase
  Future<void> _loadDuLieu() async {
    setState(() => _dangTaiDuLieu = true);
    try {
      final danhMucList = await DichVuSupabase.layDanhSachDanhMuc();
      final taiKhoanList = await DichVuSupabase.layDanhSachTaiKhoan();

      if (mounted) {
        setState(() {
          _danhSachDanhMuc = danhMucList;
          _danhSachTaiKhoan = taiKhoanList;

          // Chọn sẵn Danh mục cũ
          _danhMucChon = danhMucList.timTheoId(widget.giaoDichCu.danhMucId);

          // Chọn sẵn Ví cũ
          if (widget.giaoDichCu.taiKhoanId != null) {
            final listTK = taiKhoanList.where((v) => v.id == widget.giaoDichCu.taiKhoanId).toList();
            if (listTK.isNotEmpty) {
              _taiKhoanChon = listTK.first;
            } else if (taiKhoanList.isNotEmpty) {
              _taiKhoanChon = taiKhoanList.first;
            }
          } else if (taiKhoanList.isNotEmpty) {
            _taiKhoanChon = taiKhoanList.first;
          }

          _dangTaiDuLieu = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _dangTaiDuLieu = false);
    }
  }

  /// Thay đổi giữa Chi Tiêu <-> Thu Nhập
  void _thayDoiLoaiGiaoDich(String loaiMoi) {
    if (_loaiGiaoDich == loaiMoi) return;
    setState(() {
      _loaiGiaoDich = loaiMoi;
      final dmPhuHop = _danhSachDanhMuc.where((d) => d.loai == _loaiGiaoDich).toList();
      _danhMucChon = dmPhuHop.isNotEmpty ? dmPhuHop.first : null;
    });
  }

  /// Xử lý bấm phím bàn phím số Numpad (0-9, 000, ⌫)
  void _nhapPhimNumpad(String kyTu) {
    setState(() {
      if (kyTu == 'xoa') {
        if (_soTienText.length > 1) {
          _soTienText = _soTienText.substring(0, _soTienText.length - 1);
        } else {
          _soTienText = '0';
        }
      } else if (kyTu == '000') {
        if (_soTienText != '0' && _soTienText.length <= 11) {
          _soTienText += '000';
        }
      } else {
        if (_soTienText == '0') {
          _soTienText = kyTu;
        } else if (_soTienText.length <= 12) {
          _soTienText += kyTu;
        }
      }
    });
  }

  /// Xóa trắng số tiền về 0
  void _xoaTrangSoTien() {
    setState(() => _soTienText = '0');
  }

  /// Cộng thêm tiền nhanh (+50k, +100k, +1M...)
  void _congTienNhanh(double soTienCong) {
    final cur = double.tryParse(_soTienText) ?? 0.0;
    final tong = cur + soTienCong;
    setState(() => _soTienText = tong.toInt().toString());
  }

  /// Trích xuất số tiền double
  double get _soTienParsed => double.tryParse(_soTienText) ?? 0.0;

  /// Định dạng hiển thị chuỗi số tiền (ví dụ: 5.000.000)
  String get _chuoiSoTienFormatted {
    final amount = _soTienParsed;
    final String numStr = amount.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  /// Chuỗi hiển thị thời gian chính xác của giao dịch
  String get _ngayGiaoDichFormatted {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(_ngayGiaoDich.year, _ngayGiaoDich.month, _ngayGiaoDich.day);

    final hh = _ngayGiaoDich.hour.toString().padLeft(2, '0');
    final mm = _ngayGiaoDich.minute.toString().padLeft(2, '0');

    if (target == today) {
      return 'Hôm nay, $hh:$mm';
    } else if (target == yesterday) {
      return 'Hôm qua, $hh:$mm';
    } else {
      final dd = _ngayGiaoDich.day.toString().padLeft(2, '0');
      final mo = _ngayGiaoDich.month.toString().padLeft(2, '0');
      return '$dd/$mo/${_ngayGiaoDich.year}, $hh:$mm';
    }
  }

  /// Chọn ngày giờ phát sinh giao dịch
  Future<void> _chonNgayGiaoDich() async {
    final DateTime? picked = await showDatePicker(
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
            dialogTheme: const DialogThemeData(backgroundColor: MauSac.nenThe),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (!mounted) return;
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_ngayGiaoDich),
      );

      setState(() {
        _ngayGiaoDich = DateTime(
          picked.year,
          picked.month,
          picked.day,
          timePicked?.hour ?? _ngayGiaoDich.hour,
          timePicked?.minute ?? _ngayGiaoDich.minute,
        );
      });
    }
  }

  /// Chọn / chụp ảnh hóa đơn mới
  Future<void> _chonAnhHoaDon(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() => _anhHoaDonMoiFile = image);
    }
  }

  /// Thao tác Cập nhật Giao dịch lên Supabase CSDL
  Future<void> _xuLyCapNhatGiaoDich() async {
    final user = DichVuSupabase.nguoiDungHienTai;
    if (user == null) {
      _hienThongBao('Vui lòng đăng nhập để thực hiện cập nhật giao dịch');
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
        final String soDuStr = _chuoiSoTienFormatted;
        _hienThongBao(
          'Số dư ví ${_taiKhoanChon!.tenNganHang} không đủ để chi tiêu! '
          '(Số dư hiện có: ${soDuHienCo.toInt()} đ, Cần chi: $soDuStr đ)',
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
      if (mounted) _hienThongBao('Không thể cập nhật giao dịch: $e');
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
    final isChiTieu = _loaiGiaoDich == 'chi_tieu';
    final colorTheme = isChiTieu ? MauSac.chiTieu : MauSac.thuNhap;
    final filteredDanhMuc = _danhSachDanhMuc.where((d) => d.loai == _loaiGiaoDich).toList();

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
                                Icon(BieuTuong.xuHuongGiam,
                                    color: isChiTieu ? MauSac.chiTieu : MauSac.chuPhu, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Chi tiêu',
                                  style: TextStyle(
                                    color: isChiTieu ? MauSac.chiTieu : MauSac.chuPhu,
                                    fontWeight: isChiTieu ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 14,
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
                              color: !isChiTieu ? MauSac.thuNhap : Colors.transparent,
                              borderRadius: BoGoc.borderTron,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(BieuTuong.xuHuongTang,
                                    color: !isChiTieu ? Colors.black : MauSac.chuPhu, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Thu nhập',
                                  style: TextStyle(
                                    color: !isChiTieu ? Colors.black : MauSac.chuPhu,
                                    fontWeight: !isChiTieu ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 14,
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

                // SECTION 2: CARD BẢNG SỐ TIỀN CỠ LỚN & CHIP THÊM TIỀN NHANH
                Container(
                  width: double.infinity,
                  padding: KhoangCach.lToanBoLon,
                  decoration: BoxDecoration(
                    color: MauSac.nenThe,
                    borderRadius: BoGoc.borderLon,
                    border: Border.all(color: colorTheme.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(BieuTuong.chamTron, color: colorTheme, size: 8),
                          const SizedBox(width: 6),
                          Text(
                            isChiTieu ? 'KHOẢN CHI TIÊU TỨC THÌ' : 'TIỀN VÀO TÀI KHOẢN',
                            style: TextStyle(
                              color: isChiTieu ? MauSac.chuPhu : MauSac.chuDao,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Hiển thị Số tiền lớn
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            isChiTieu ? '- ' : '+ ',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: colorTheme,
                            ),
                          ),
                          Text(
                            _chuoiSoTienFormatted,
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: colorTheme,
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

                // SECTION 3: DANH MỤC LƯỚI O CHỌN THU CHI (2x4 GRID)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isChiTieu ? 'Danh mục chi tiêu' : 'Nguồn thu nhập',
                      style: const TextStyle(
                        color: MauSac.chuChinh,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${filteredDanhMuc.length} danh mục',
                          style: const TextStyle(color: MauSac.chuPhu, fontSize: 11),
                        ),
                      ],
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
                          // Thêm viền bo và màu nền cho cả khung lớn bên ngoài
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isChiTieu ? MauSac.chiTieu.withValues(alpha: 0.15) : MauSac.chuDao.withValues(alpha: 0.15))
                                : MauSac.nenThe, // Màu nền thẻ khi chọn/không chọn
                            borderRadius: BoGoc.borderVua,
                            border: Border.all(
                              color: isSelected
                                  ? (isChiTieu ? MauSac.chiTieu : MauSac.chuDao)
                                  : MauSac.duongVienNhat, // Viền ngoài đổi màu khi được chọn
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Ô vuông chứa Icon bên trên
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
                              // Tên danh mục bên dưới
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

                // SECTION 4: THÔNG TIN THỜI GIAN, VÍ & GHI CHÚ
                Container(
                  padding: KhoangCach.lToanBoChuan,
                  decoration: BoxDecoration(
                    color: MauSac.nenThe,
                    borderRadius: BoGoc.borderVua,
                    border: Border.all(color: MauSac.duongVienNhat),
                  ),
                  child: Column(
                    children: [
                      // Dòng 1: Chọn Ví nhận tiền
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: MauSac.nenNoi,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(BieuTuong.nganHang, color: MauSac.chuDao, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tài khoản nhận tiền', style: TextStyle(color: MauSac.chuPhu, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  _taiKhoanChon != null
                                      ? '${_taiKhoanChon!.tenNganHang} (${_taiKhoanChon!.soTaiKhoan})'
                                      : 'Chưa chọn tài khoản ví',
                                  style: const TextStyle(color: MauSac.chuChinh, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<TaiKhoanNganHangModel>(
                            color: MauSac.nenThe,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BoGoc.borderVua,
                              side: BorderSide(color: MauSac.duongVienNhat),
                            ),
                            onSelected: (tk) => setState(() => _taiKhoanChon = tk),
                            itemBuilder: (context) {
                              return [
                                ..._danhSachTaiKhoan.map(
                                  (tk) => PopupMenuItem(
                                    value: tk,
                                    child: Text(
                                      '${tk.tenNganHang} (${tk.soTaiKhoan})',
                                      style: const TextStyle(color: MauSac.chuChinh, fontSize: 13),
                                    ),
                                  ),
                                ),
                                PopupMenuItem(
                                  onTap: () async {
                                    await BsLienKetTaiKhoan.hienThi(context);
                                    _loadDuLieu();
                                  },
                                  child: Row(
                                    children: const [
                                      Icon(BieuTuong.themVi, color: MauSac.chuDao, size: 16),
                                      SizedBox(width: 8),
                                      Text('+ Thêm ví mới', style: TextStyle(color: MauSac.chuDao, fontSize: 13, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ];
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              child: Row(
                                children: const [
                                  Text('Đổi', style: TextStyle(color: MauSac.chuDao, fontSize: 12, fontWeight: FontWeight.bold)),
                                  Icon(BieuTuong.muiTenXuong, color: MauSac.chuDao, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(color: MauSac.duongVienNhat, height: 16),

                      // Dòng 2: Thời gian & Ghi chú (2 cột)
                      Row(
                        children: [
                          // Thời gian
                          Expanded(
                            child: GestureDetector(
                              onTap: _chonNgayGiaoDich,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: MauSac.nenNoi,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(BieuTuong.lichThang, color: MauSac.phu, size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Thời gian', style: TextStyle(color: MauSac.chuPhu, fontSize: 10)),
                                        Text(
                                          _ngayGiaoDichFormatted,
                                          style: const TextStyle(color: MauSac.chuChinh, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Ô nhập Ghi chú
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: MauSac.nenNoi,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(BieuTuong.ghiChuSua, color: MauSac.chuDao, size: 18),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _ghiChuController,
                                    style: const TextStyle(color: MauSac.chuChinh, fontSize: 12),
                                    decoration: InputDecoration(
                                      hintText: isChiTieu ? 'Ăn trưa...' : 'Thưởng dự án...',
                                      hintStyle: const TextStyle(color: MauSac.chuMo, fontSize: 11),
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Divider(color: MauSac.duongVienNhat, height: 16),

                      // Dòng 3: Đính kèm ảnh Hóa đơn / Chứng từ
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Row(
                                children: [
                                  Icon(BieuTuong.saoKe, color: MauSac.chuDao, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Sao kê / Chứng từ giao dịch',
                                    style: TextStyle(color: MauSac.chuChinh, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Text('Tùy chọn', style: TextStyle(color: MauSac.chuPhu, fontSize: 11)),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _chonAnhHoaDon(ImageSource.camera),
                                  icon: const Icon(BieuTuong.mayAnh, color: MauSac.chuDao, size: 16),
                                  label: const FittedBox(
                                    child: Text('Chụp ảnh', style: TextStyle(color: MauSac.chuChinh, fontSize: 12)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: MauSac.nenNoi,
                                    side: const BorderSide(color: MauSac.duongVienNhat),
                                    shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _chonAnhHoaDon(ImageSource.gallery),
                                  icon: const Icon(BieuTuong.thuVienAnh, color: MauSac.phu, size: 16),
                                  label: const FittedBox(
                                    child: Text('Tải ảnh từ máy', style: TextStyle(color: MauSac.chuChinh, fontSize: 12)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: MauSac.nenNoi,
                                    side: const BorderSide(color: MauSac.duongVienNhat),
                                    shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Khung xem trước ảnh chứng từ (Ảnh mới chọn HOẶC URL cũ)
                          if (_anhHoaDonMoiFile != null || _urlHoaDonCu != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: MauSac.nenNoi,
                                borderRadius: BoGoc.borderVua,
                                border: Border.all(color: MauSac.chuDao, width: 1),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: _anhHoaDonMoiFile != null
                                          ? FutureBuilder<Uint8List>(
                                              future: _anhHoaDonMoiFile!.readAsBytes(),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  return Image.memory(
                                                    snapshot.data!,
                                                    fit: BoxFit.cover,
                                                  );
                                                }
                                                return const Center(
                                                  child: SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: MauSac.chuDao,
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Image.network(
                                              _urlHoaDonCu!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => const Icon(
                                                BieuTuong.mayAnh,
                                                color: MauSac.chuPhu,
                                                size: 20,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: const [
                                            Icon(BieuTuong.dauTichTron, color: MauSac.chuDao, size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              'Ảnh chứng từ giao dịch',
                                              style: TextStyle(
                                                color: MauSac.chuDao,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _anhHoaDonMoiFile != null ? _anhHoaDonMoiFile!.name : 'Chung_tu_hoa_don.jpg',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: MauSac.chuPhu, fontSize: 10),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _anhHoaDonMoiFile != null ? 'Sẽ tải lên Supabase khi bấm Cập nhật' : 'Đã tải lên Supabase Storage',
                                          style: const TextStyle(color: MauSac.chuMo, fontSize: 9),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(BieuTuong.xoaTron, color: MauSac.chiTieu, size: 22),
                                    onPressed: () => setState(() {
                                      _anhHoaDonMoiFile = null;
                                      _urlHoaDonCu = null;
                                    }),
                                    tooltip: 'Xóa ảnh',
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 6),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Hỗ trợ JPG, PNG tối đa 10MB', style: TextStyle(color: MauSac.chuMo, fontSize: 10)),
                              Row(
                                children: [
                                  Icon(BieuTuong.dauTichTron, color: MauSac.chuDao, size: 12),
                                  SizedBox(width: 4),
                                  Text('An toàn', style: TextStyle(color: MauSac.chuDao, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),

                // SECTION 5: BÀN PHÍM SỐ TÍCH HỢP (INTEGRATED 3x4 NUMERIC KEYPAD)
                Container(
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
                          _taoPhimNumpad('1'),
                          _taoPhimNumpad('2'),
                          _taoPhimNumpad('3'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _taoPhimNumpad('4'),
                          _taoPhimNumpad('5'),
                          _taoPhimNumpad('6'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _taoPhimNumpad('7'),
                          _taoPhimNumpad('8'),
                          _taoPhimNumpad('9'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _taoPhimNumpad('000'),
                          _taoPhimNumpad('0'),
                          _taoPhimNumpad('xoa', icon: BieuTuong.xoaLui),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),

                // SECTION 6: NÚT CTA CẬP NHẬT GIAO DỊCH
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _dangXuLy ? null : _xuLyCapNhatGiaoDich,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorTheme,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BoGoc.borderTron),
                    ),
                    child: _dangXuLy
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(BieuTuong.dauTichTron, color: Colors.black, size: 20),
                              SizedBox(width: 8),
                              FittedBox(
                                child: Text(
                                  'Cập nhật giao dịch',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Nút phím Numpad nhỏ
  Widget _taoPhimNumpad(String giaTri, {IconData? icon}) {
    return Expanded(
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () => _nhapPhimNumpad(giaTri),
          style: ElevatedButton.styleFrom(
            backgroundColor: MauSac.nenNoi,
            foregroundColor: MauSac.chuChinh,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.zero,
          ),
          child: icon != null
              ? Icon(icon, color: MauSac.chuPhu, size: 20)
              : Text(
                  giaTri,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MauSac.chuChinh),
                ),
        ),
      ),
    );
  }

  /// Chip cộng tiền nhanh (+50k, +1M...)
  Widget _taoChipCongTien(String nhan, double soTienCong) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(nhan, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        backgroundColor: MauSac.nenNoi,
        labelStyle: const TextStyle(color: MauSac.chuChinh),
        side: const BorderSide(color: MauSac.duongVienNhat),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: () => _congTienNhanh(soTienCong),
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
