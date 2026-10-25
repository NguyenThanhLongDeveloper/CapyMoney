import 'package:flutter/material.dart';
import '../chuan_thiet_ke/mau_sac.dart';
import '../chuan_thiet_ke/bo_goc.dart';
import '../chuan_thiet_ke/khoang_cach.dart';
import '../thong_bao/thong_bao_giua_man_hinh.dart';
import '../../mo_hinh/tai_khoan_ngan_hang_model.dart';
import '../../dich_vu/dich_vu_supabase.dart';

/// Bảng Trượt (Bottom Sheet) Quản Lý Tài Khoản & Ví Nhận Tiền Liên Kết
/// 
/// Hiển thị danh sách thực tế từ Supabase CSDL và hỗ trợ thêm/xóa/đặt ví chính.
class BsLienKetTaiKhoan extends StatefulWidget {
  const BsLienKetTaiKhoan({super.key});

  /// Hàm hỗ trợ mở Bảng trượt từ bất kỳ Context màn hình nào
  static Future<void> hienThi(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BsLienKetTaiKhoan(),
    );
  }

  @override
  State<BsLienKetTaiKhoan> createState() => _BsLienKetTaiKhoanState();
}

class _BsLienKetTaiKhoanState extends State<BsLienKetTaiKhoan> {
  /// Bộ điều khiển nhập Số tài khoản / Số điện thoại ví
  final _stkController = TextEditingController();

  /// Bộ điều khiển nhập Tên chủ tài khoản
  final _tenChuTaiKhoanController = TextEditingController();

  /// Ngân hàng / Loại ví được chọn mặc định
  String _nganHangChon = 'MB Bank - Ngân hàng Quân Đội';

  /// Trạng thái đang lưu dữ liệu mới
  bool _dangTai = false;

  /// Trạng thái đang nạp danh sách từ CSDL
  bool _dangTaiDanhSach = true;

  /// Danh sách các Ngân hàng và Ví điện tử phổ biến tại Việt Nam
  final List<String> _danhSachNganHang = [
    'MB Bank - Ngân hàng Quân Đội',
    'Vietcombank Digital',
    'Techcombank',
    'Ví Điện Tử MoMo',
    'VPBank Digital',
    'TP Bank',
  ];

  /// Danh sách các nguồn tài khoản thực tế lấy từ Supabase CSDL
  List<TaiKhoanNganHangModel> _danhSachTaiKhoan = [];

  @override
  void initState() {
    super.initState();
    _loadDanhSachTaiKhoan();
  }

  /// Nạp danh sách ví & tài khoản ngân hàng thực tế từ Service CSDL Supabase
  Future<void> _loadDanhSachTaiKhoan() async {
    setState(() => _dangTaiDanhSach = true);
    try {
      final danhSach = await DichVuSupabase.layDanhSachTaiKhoan();
      if (mounted) {
        setState(() {
          _danhSachTaiKhoan = danhSach;
          _dangTaiDanhSach = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _dangTaiDanhSach = false);
    }
  }

  /// Thao tác lưu tài khoản hoặc ví liên kết mới vào Supabase CSDL
  Future<void> _luuTaiKhoanMoi() async {
    final stk = _stkController.text.trim();
    final tenChu = _tenChuTaiKhoanController.text.trim();

    if (stk.isEmpty || tenChu.isEmpty) {
      ThongBaoGiuaManHinh.hienThi(
        context,
        noiDung: 'Vui lòng nhập đầy đủ Số tài khoản và Tên chủ tài khoản',
        loai: LoaiThongBao.loi,
      );
      return;
    }

    setState(() => _dangTai = true);

    try {
      final user = DichVuSupabase.nguoiDungHienTai;
      final tkMoi = TaiKhoanNganHangModel(
        id: '',
        nguoiDungId: user?.id ?? '',
        tenNganHang: _nganHangChon.split(' - ').first,
        soTaiKhoan: stk,
        tenChuTaiKhoan: tenChu,
        laNhanChinh: _danhSachTaiKhoan.isEmpty,
        soDu: 0.0,
      );

      await DichVuSupabase.themTaiKhoan(tkMoi);
      
      _stkController.clear();
      _tenChuTaiKhoanController.clear();

      await _loadDanhSachTaiKhoan();
      if (!mounted) return;

      ThongBaoGiuaManHinh.hienThi(
        context,
        noiDung: 'Thêm tài khoản / ví liên kết mới thành công!',
        loai: LoaiThongBao.thanhCong,
      );
    } catch (e) {
      if (!mounted) return;
      ThongBaoGiuaManHinh.hienThi(
        context,
        noiDung: 'Lỗi thêm tài khoản: $e',
        loai: LoaiThongBao.loi,
      );
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  /// Thao tác đặt tài khoản làm nguồn nhận tiền chính
  Future<void> _datLamNhanChinh(String id) async {
    final user = DichVuSupabase.nguoiDungHienTai;
    if (user == null) return;
    try {
      await DichVuSupabase.datLamNhanChinh(id, user.id);
      await _loadDanhSachTaiKhoan();
    } catch (_) {}
  }

  /// Thao tác xóa tài khoản khỏi danh sách liên kết
  Future<void> _xoaTaiKhoan(String id) async {
    try {
      await DichVuSupabase.xoaTaiKhoan(id);
      await _loadDanhSachTaiKhoan();
      if (!mounted) return;
      ThongBaoGiuaManHinh.hienThi(
        context,
        noiDung: 'Đã xóa tài khoản liên kết',
        loai: LoaiThongBao.thanhCong,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _stkController.dispose();
    _tenChuTaiKhoanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tự động đẩy khung Bottom Sheet lên khi bàn phím ảo xuất hiện
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: keyboardSpace),
      decoration: const BoxDecoration(
        color: MauSac.nenChinh,
        borderRadius: BoGoc.borderBottomSheet,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
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

              // SECTION 1: HEADER BẢNG TRƯỢT & TIÊU ĐỀ
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.chevron_left_rounded, color: MauSac.chuDao, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        Text(
                          'Tài khoản & Ví nhận tiền',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: MauSac.chuChinh,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Quản lý phương thức và nguồn nhận tiền',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: MauSac.chuPhu,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close_rounded, color: MauSac.chuPhu, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: KhoangCach.lon),

              // SECTION 2: DANH SÁCH TÀI KHOẢN VÍ THỰC TẾ TỪ SUPABASE
              if (_dangTaiDanhSach)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(color: MauSac.chuDao),
                  ),
                )
              else if (_danhSachTaiKhoan.isEmpty)
                Container(
                  width: double.infinity,
                  padding: KhoangCach.lToanBoChuan,
                  decoration: BoxDecoration(
                    color: MauSac.nenThe,
                    borderRadius: BoGoc.borderVua,
                    border: Border.all(color: MauSac.duongVienNhat),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.account_balance_wallet_outlined, color: MauSac.chuPhu, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Chưa có tài khoản / ví liên kết nào',
                        style: TextStyle(color: MauSac.chuChinh, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Thêm tài khoản ngân hàng hoặc ví điện tử bên dưới',
                        style: TextStyle(color: MauSac.chuPhu, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: _danhSachTaiKhoan.map((tk) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: KhoangCach.lToanBoChuan,
                      decoration: BoxDecoration(
                        color: MauSac.nenThe,
                        borderRadius: BoGoc.borderVua,
                        border: Border.all(
                          color: tk.laNhanChinh ? MauSac.chuDao : MauSac.duongVienNhat,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: MauSac.nenNoi,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.account_balance_wallet_rounded,
                                    color: MauSac.phu, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tk.tenNganHang,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: MauSac.chuChinh,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${tk.soTaiKhoan} • ${tk.tenChuTaiKhoan}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: MauSac.chuPhu,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.delete_outline_rounded, color: MauSac.chiTieu, size: 20),
                                onPressed: () => _xoaTaiKhoan(tk.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => _datLamNhanChinh(tk.id),
                              child: Text(
                                tk.laNhanChinh ? '● Tài khoản chính' : 'Đặt làm tài khoản chính',
                                style: TextStyle(
                                  color: tk.laNhanChinh ? MauSac.chuDao : MauSac.phu,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: KhoangCach.vua),

              // SECTION 3: FORM NHẬP TÀI KHOẢN HOẶC VÍ MỚI
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
                      children: const [
                        Icon(Icons.add_card_rounded, color: MauSac.chuDao, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Thêm tài khoản hoặc ví mới',
                          style: TextStyle(
                            color: MauSac.chuChinh,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: KhoangCach.phatChuan),

                    // Dropdown chọn ngân hàng
                    const Text('Ngân hàng / Loại ví', style: TextStyle(color: MauSac.chuPhu, fontSize: 12)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: MauSac.nenNoi,
                        borderRadius: BoGoc.borderVua,
                        border: Border.all(color: MauSac.duongVienNhat),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _nganHangChon,
                          isExpanded: true,
                          dropdownColor: MauSac.nenThe,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: MauSac.chuPhu),
                          items: _danhSachNganHang.map((nh) {
                            return DropdownMenuItem(
                              value: nh,
                              child: Text(
                                nh,
                                style: const TextStyle(color: MauSac.chuChinh, fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _nganHangChon = val);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: KhoangCach.phatChuan),

                    // Ô nhập Số tài khoản
                    const Text('Số tài khoản / Số điện thoại ví', style: TextStyle(color: MauSac.chuPhu, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _stkController,
                      style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: '09******21',
                        hintStyle: const TextStyle(color: MauSac.chuMo),
                        prefixIcon: const Icon(Icons.numbers_rounded, color: MauSac.chuPhu, size: 18),
                        filled: true,
                        fillColor: MauSac.nenNoi,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BoGoc.borderVua,
                          borderSide: const BorderSide(color: MauSac.duongVienNhat),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BoGoc.borderVua,
                          borderSide: const BorderSide(color: MauSac.duongVienNhat),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BoGoc.borderVua,
                          borderSide: const BorderSide(color: MauSac.chuDao),
                        ),
                      ),
                    ),

                    const SizedBox(height: KhoangCach.phatChuan),

                    // Ô nhập Tên chủ tài khoản
                    const Text('Tên chủ tài khoản (in hoa không dấu)', style: TextStyle(color: MauSac.chuPhu, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _tenChuTaiKhoanController,
                      style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'NGUYEN VAN A',
                        hintStyle: const TextStyle(color: MauSac.chuMo),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: MauSac.chuPhu, size: 18),
                        filled: true,
                        fillColor: MauSac.nenNoi,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BoGoc.borderVua,
                          borderSide: const BorderSide(color: MauSac.duongVienNhat),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BoGoc.borderVua,
                          borderSide: const BorderSide(color: MauSac.duongVienNhat),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BoGoc.borderVua,
                          borderSide: const BorderSide(color: MauSac.chuDao),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KhoangCach.lon),

              // SECTION 4: NÚT ĐIỀU HƯỚNG QUAY LẠI VÀ LƯU LẠI
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: MauSac.nenNoi,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          side: const BorderSide(color: MauSac.duongVienNhat),
                          shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.arrow_back_rounded, color: MauSac.chuPhu, size: 16),
                            SizedBox(width: 4),
                            FittedBox(
                              child: Text('Quay lại', style: TextStyle(color: MauSac.chuChinh, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _dangTai ? null : _luuTaiKhoanMoi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MauSac.chuDao,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
                        ),
                        child: _dangTai
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.check_circle_rounded, color: Colors.black, size: 16),
                                  SizedBox(width: 4),
                                  FittedBox(
                                    child: Text(
                                      'Xong & Lưu lại',
                                      style: TextStyle(
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
    );
  }
}
