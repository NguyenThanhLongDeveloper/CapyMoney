import 'package:flutter/material.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/khoang_cach.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../../giao_dien/chuan_thiet_ke/dap_ung.dart';
import '../../giao_dien/thong_bao/thong_bao_giua_man_hinh.dart';
import '../../mo_hinh/giao_dich_model.dart';
import '../../mo_hinh/danh_muc_model.dart';
import '../../mo_hinh/tai_khoan_ngan_hang_model.dart';
import '../../dich_vu/dich_vu_supabase.dart';
import 'man_hinh_chinh_sua_giao_dich.dart';

/// Màn Hình Chi Tiết Giao Dịch (Transaction Details Screen)
/// 
/// Thiết kế chuẩn Kinetic Neo-Fintech Dark Mode khớp 100% UI mockup:
/// Thẻ Tổng quan (Số tiền cỡ lớn, Trạng thái thành công, Ngày giờ), Thẻ Thông tin chi tiết (Danh mục, Ví, Ghi chú),
/// Thẻ Chứng từ & Hóa đơn gốc (Phóng to xem ảnh) và Nút Xóa / Chỉnh sửa giao dịch.
class ManHinhChiTietGiaoDich extends StatefulWidget {
  final GiaoDichModel giaoDich;

  const ManHinhChiTietGiaoDich({
    super.key,
    required this.giaoDich,
  });

  @override
  State<ManHinhChiTietGiaoDich> createState() => _ManHinhChiTietGiaoDichState();
}

class _ManHinhChiTietGiaoDichState extends State<ManHinhChiTietGiaoDich> {
  /// Danh mục của giao dịch
  DanhMucModel? _danhMuc;

  /// Ví / Tài khoản ngân hàng của giao dịch
  TaiKhoanNganHangModel? _taiKhoan;

  /// Trạng thái đang thực hiện xóa
  bool _dangXoa = false;

  @override
  void initState() {
    super.initState();
    _loadDuLieu();
  }

  /// Nạp thông tin Danh mục và Ví liên kết từ Supabase CSDL
  Future<void> _loadDuLieu() async {
    try {
      final danhMucList = await DichVuSupabase.layDanhSachDanhMuc();
      final taiKhoanList = await DichVuSupabase.layDanhSachTaiKhoan();

      if (mounted) {
        setState(() {
          _danhMuc = danhMucList.timTheoId(widget.giaoDich.danhMucId);
          if (widget.giaoDich.taiKhoanId != null) {
            final listTK = taiKhoanList.where((t) => t.id == widget.giaoDich.taiKhoanId).toList();
            if (listTK.isNotEmpty) _taiKhoan = listTK.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Lỗi nạp Chi tiết giao dịch: $e');
    }
  }

  /// Định dạng tiền VND dạng đầy đủ (ví dụ: -65.000 đ)
  String _dinhDangTien(double amount, bool isThu) {
    final String numStr = amount.abs().toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formatted = numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    final prefix = isThu ? '+' : '-';
    return '$prefix$formatted đ';
  }

  /// Định dạng ngày giờ hiển thị (ví dụ: '08:30 • Thứ Năm, 24/10/2026')
  String _dinhDangNgayGio(DateTime dt) {
    const weekdays = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
    final tenThu = weekdays[(dt.weekday - 1) % 7];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');

    return '$hh:$mm • $tenThu, $dd/$mo/${dt.year}';
  }

  /// Mở Hộp thoại Phóng to Ảnh Hóa đơn / Chứng từ
  void _phongToAnhHoaDon(String url) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BoGoc.borderVua,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(24),
                    color: MauSac.nenThe,
                    child: const Text('Không thể tải ảnh chứng từ', style: TextStyle(color: MauSac.chuPhu)),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(BieuTuong.dongX, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Thao tác Xóa giao dịch kèm Xác nhận
  Future<void> _xacNhanXoaGiaoDich() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: MauSac.nenThe,
          shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
          title: Row(
            children: const [
              Icon(BieuTuong.canhBao, color: MauSac.chiTieu, size: 22),
              SizedBox(width: 8),
              Text('Xác nhận xóa', style: TextStyle(color: MauSac.chuChinh, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Bạn có chắc chắn muốn xóa giao dịch này? Số dư ví thanh toán sẽ tự động được hoàn trả cân bằng lại.',
            style: TextStyle(color: MauSac.chuPhu, fontSize: 13, height: 1.4),
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
              child: const Text('Xóa ngay', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() => _dangXoa = true);
      final res = await DichVuSupabase.xoaGiaoDich(widget.giaoDich);
      if (!mounted) return;

      if (res) {
        ThongBaoGiuaManHinh.hienThi(
          context,
          noiDung: 'Đã xóa giao dịch và hoàn trả số dư ví thành công!',
          loai: LoaiThongBao.thanhCong,
        );
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        ThongBaoGiuaManHinh.hienThi(
          context,
          noiDung: 'Không thể xóa giao dịch. Vui lòng thử lại!',
          loai: LoaiThongBao.loi,
        );
        setState(() => _dangXoa = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gd = widget.giaoDich;
    final isThu = gd.loaiGiaoDich == 'thu_nhap';
    final colorTheme = isThu ? MauSac.thuNhap : MauSac.chiTieu;
    final iconDM = _danhMuc?.iconData ?? (isThu ? BieuTuong.nganHang : BieuTuong.gioHang);
    final tenDM = _danhMuc?.tenDanhMuc ?? (isThu ? 'Thu nhập' : 'Chi tiêu');

    final String tenViFormatted = _taiKhoan != null
        ? '${_taiKhoan!.tenNganHang} •• ${_taiKhoan!.soTaiKhoan.length >= 4 ? _taiKhoan!.soTaiKhoan.substring(_taiKhoan!.soTaiKhoan.length - 4) : _taiKhoan!.soTaiKhoan}'
        : 'Ví mặc định (VCB •• 4289)';

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
          'Chi Tiết Giao Dịch',
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

                // SECTION 1: CARD TỔNG QUAN (SỐ TIỀN CỠ LỚN, TRẠNG THÁI & NGÀY GIỜ)
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
                      // Badge Trạng thái "Giao dịch thành công"
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: MauSac.chuDao.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: MauSac.chuDao.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(BieuTuong.dauTichTron, color: MauSac.chuDao, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'Giao dịch thành công',
                              style: TextStyle(
                                color: MauSac.chuDao,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: KhoangCach.lon),

                      // Icon Danh mục trung tâm có đốm tích xanh
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: MauSac.nenNoi,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: MauSac.duongVienNhat),
                            ),
                            child: Icon(
                              iconDM,
                              color: isThu ? MauSac.thuNhap : MauSac.phu,
                              size: 32,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: MauSac.chuDao,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(BieuTuong.dauTich, color: Colors.black, size: 10),
                          ),
                        ],
                      ),

                      const SizedBox(height: KhoangCach.vua),

                      // Ngày giờ giao dịch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(BieuTuong.dongHo, color: MauSac.chuPhu, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _dinhDangNgayGio(gd.ngayGiaoDich),
                            style: const TextStyle(
                              color: MauSac.chuPhu,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: KhoangCach.vua),

                      // Thẻ chứa Số tiền cỡ lớn
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: MauSac.nenNoi,
                          borderRadius: BoGoc.borderVua,
                        ),
                        child: Center(
                          child: FittedBox(
                            child: Text(
                              _dinhDangTien(gd.soTien, isThu),
                              style: TextStyle(
                                color: colorTheme,
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),

                // SECTION 2: CARD THÔNG TIN CHI TIẾT (DANH MỤC, VÍ, GHI CHÚ)
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
                        children: const [
                          Icon(BieuTuong.saoKe, color: MauSac.chuDao, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Thông tin chi tiết',
                            style: TextStyle(
                              color: MauSac.chuChinh,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: KhoangCach.lon),

                      // Dòng 1: Danh mục
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isThu ? 'Nguồn thu nhập' : 'Danh mục chi tiêu',
                            style: const TextStyle(color: MauSac.chuPhu, fontSize: 13),
                          ),
                          Row(
                            children: [
                              const Icon(BieuTuong.chamTron, color: MauSac.chuDao, size: 8),
                              const SizedBox(width: 6),
                              Text(
                                tenDM,
                                style: const TextStyle(
                                  color: MauSac.chuChinh,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const Divider(color: MauSac.duongVienNhat, height: 24),

                      // Dòng 2: Ví thanh toán
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isThu ? 'Tài khoản nhận tiền' : 'Ví thanh toán',
                            style: const TextStyle(color: MauSac.chuPhu, fontSize: 13),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: MauSac.phu,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    'M',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tenViFormatted,
                                style: const TextStyle(
                                  color: MauSac.chuChinh,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: KhoangCach.lon),

                      // Dòng 3: Ghi chú
                      const Text('Ghi chú', style: TextStyle(color: MauSac.chuPhu, fontSize: 12)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: KhoangCach.lToanBoChuan,
                        decoration: BoxDecoration(
                          color: MauSac.nenNoi,
                          borderRadius: BoGoc.borderVua,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(BieuTuong.ghiChuSua, color: MauSac.chuPhu, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                gd.ghiChu != null && gd.ghiChu!.trim().isNotEmpty
                                    ? gd.ghiChu!
                                    : (isThu ? 'Ghi nhận thu nhập' : 'Ghi nhận chi tiêu'),
                                style: TextStyle(
                                  color: gd.ghiChu != null && gd.ghiChu!.trim().isNotEmpty
                                      ? MauSac.chuChinh
                                      : MauSac.chuMo,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),

                // SECTION 3: CARD CHỨNG TỪ & HÓA ĐƠN GỐC
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
                              Icon(BieuTuong.mayAnh, color: MauSac.chuDao, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Chứng từ & Hóa đơn gốc',
                                style: TextStyle(
                                  color: MauSac.chuChinh,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            gd.anhHoaDon != null ? '1 tệp đính kèm' : 'Chưa có tệp',
                            style: const TextStyle(color: MauSac.chuPhu, fontSize: 11),
                          ),
                        ],
                      ),

                      const SizedBox(height: KhoangCach.vua),

                      if (gd.anhHoaDon != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: MauSac.nenNoi,
                            borderRadius: BoGoc.borderVua,
                            border: Border.all(color: MauSac.duongVienNhat),
                          ),
                          child: Row(
                            children: [
                              // Ảnh thumbnail nhỏ
                              GestureDetector(
                                onTap: () => _phongToAnhHoaDon(gd.anhHoaDon!),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    color: MauSac.nenThe,
                                    child: Image.network(
                                      gd.anhHoaDon!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        BieuTuong.mayAnh,
                                        color: MauSac.chuPhu,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Tên tệp & Nút Phóng to
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Chung_tu_hoa_don.jpg',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: MauSac.chuChinh,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () => _phongToAnhHoaDon(gd.anhHoaDon!),
                                      child: Row(
                                        children: const [
                                          Text(
                                            'Xem phóng to',
                                            style: TextStyle(
                                              color: MauSac.chuDao,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(BieuTuong.muiTenTien, color: MauSac.chuDao, size: 12),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: MauSac.nenNoi,
                            borderRadius: BoGoc.borderVua,
                          ),
                          child: const Center(
                            child: Text(
                              'Không có ảnh chứng từ hay hóa đơn đính kèm',
                              style: TextStyle(color: MauSac.chuPhu, fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: KhoangCach.lon),

                // SECTION 4: NÚT CTA THAO TÁC XÓA & CHỈNH SỬA
                Row(
                  children: [
                    // Nút Xóa Giao Dịch
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _dangXoa ? null : _xacNhanXoaGiaoDich,
                          icon: const Icon(BieuTuong.xoaVien, color: MauSac.chiTieu, size: 18),
                          label: FittedBox(
                            child: Text(
                              _dangXoa ? 'Đang xóa...' : 'Xóa giao dịch',
                              style: const TextStyle(color: MauSac.chiTieu, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: MauSac.nenThe,
                            side: const BorderSide(color: MauSac.chiTieu),
                            shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Nút Chỉnh Sửa
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            final res = await navigator.push(
                              MaterialPageRoute(
                                builder: (_) => ManHinhChinhSuaGiaoDich(
                                  giaoDichCu: widget.giaoDich,
                                ),
                              ),
                            );
                            if (res == true) {
                              navigator.pop(true);
                            }
                          },
                          icon: const Icon(BieuTuong.chinhSua, color: Colors.black, size: 18),
                          label: const FittedBox(
                            child: Text(
                              'Chỉnh sửa',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MauSac.chuDao,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: KhoangCach.lon),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
