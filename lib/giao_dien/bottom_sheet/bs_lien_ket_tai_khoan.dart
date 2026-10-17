import 'package:flutter/material.dart';
import '../chuan_thiet_ke/mau_sac.dart';
import '../chuan_thiet_ke/bo_goc.dart';
import '../chuan_thiet_ke/khoang_cach.dart';
import '../../mo_hinh/tai_khoan_ngan_hang_model.dart';
import '../../dich_vu/dich_vu_supabase.dart';

/// Bảng Trượt (Bottom Sheet) Quản Lý Tài Khoản & Ví Nhận Tiền Liên Kết
/// 
/// Hiển thị danh sách các tài khoản ngân hàng / ví điện tử khả dụng và hỗ trợ liên kết nguồn mới.
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
  final _stkController = TextEditingController(text: '098765432101');

  /// Bộ điều khiển nhập Tên chủ tài khoản
  final _tenChuTaiKhoanController = TextEditingController(text: 'NGUYEN HAI DANG');

  /// Ngân hàng / Loại ví được chọn mặc định
  String _nganHangChon = 'MB Bank - Ngân hàng Quân Đội';

  /// Trạng thái đang lưu dữ liệu
  bool _dangTai = false;

  /// Danh sách các Ngân hàng và Ví điện tử phổ biến tại Việt Nam
  final List<String> _danhSachNganHang = [
    'MB Bank - Ngân hàng Quân Đội',
    'Vietcombank Digital',
    'Techcombank',
    'Ví Điện Tử MoMo',
    'VPBank Digital',
    'BIDV',
  ];

  /// Danh sách các nguồn tài khoản hiện có
  List<TaiKhoanNganHangModel> _danhSachTaiKhoan = [
    TaiKhoanNganHangModel(
      id: '1',
      nguoiDungId: 'user1',
      tenNganHang: 'Vietcombank',
      soTaiKhoan: '9802',
      tenChuTaiKhoan: 'NGUYEN HAI DANG',
      laNhanChinh: true,
      soDu: 42850000,
    ),
    TaiKhoanNganHangModel(
      id: '2',
      nguoiDungId: 'user1',
      tenNganHang: 'Ví Điện Tử MoMo',
      soTaiKhoan: '098***789',
      tenChuTaiKhoan: 'Nguyễn Hải Đăng',
      laNhanChinh: false,
      soDu: 5000000,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDanhSachTaiKhoan();
  }

  /// Nạp danh sách ví & tài khoản ngân hàng thực tế từ Supabase CSDL
  Future<void> _loadDanhSachTaiKhoan() async {
    try {
      final danhSach = await DichVuSupabase.layDanhSachTaiKhoan();
      if (danhSach.isNotEmpty && mounted) {
        setState(() => _danhSachTaiKhoan = danhSach);
      }
    } catch (_) {}
  }

  /// Thao tác lưu tài khoản hoặc ví liên kết mới vào Supabase
  Future<void> _luuTaiKhoanMoi() async {
    final stk = _stkController.text.trim();
    final tenChu = _tenChuTaiKhoanController.text.trim();

    if (stk.isEmpty || tenChu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ Số tài khoản và Tên chủ tài khoản'),
          backgroundColor: MauSac.chiTieu,
        ),
      );
      return;
    }

    setState(() => _dangTai = true);

    try {
      final user = DichVuSupabase.client.auth.currentUser;
      final tkMoi = TaiKhoanNganHangModel(
        id: '',
        nguoiDungId: user?.id ?? 'demo_id',
        tenNganHang: _nganHangChon,
        soTaiKhoan: stk,
        tenChuTaiKhoan: tenChu,
        soDu: 0.0,
      );

      await DichVuSupabase.themTaiKhoan(tkMoi);
      await _loadDanhSachTaiKhoan();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thêm tài khoản / ví mới thành công!'),
          backgroundColor: MauSac.chuDao,
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: MauSac.chuDao, size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Column(
                    children: const [
                      Text(
                        'Tài khoản & Ví nhận tiền',
                        style: TextStyle(
                          color: MauSac.chuChinh,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Quản lý phương thức và nguồn nhận tiền',
                        style: TextStyle(
                          color: MauSac.chuPhu,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: MauSac.chuPhu, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: KhoangCach.lon),

              // SECTION 2: DANH SÁCH TÀI KHOẢN VÍ HIỆN CÓ
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tk.tenNganHang,
                                      style: const TextStyle(
                                        color: MauSac.chuChinh,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${tk.soTaiKhoan} • ${tk.tenChuTaiKhoan}',
                                      style: const TextStyle(
                                        color: MauSac.chuPhu,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: const [
                                Text('Sửa', style: TextStyle(color: MauSac.chuPhu, fontSize: 12)),
                                SizedBox(width: 8),
                                Icon(Icons.delete_outline_rounded, color: MauSac.chiTieu, size: 18),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            tk.laNhanChinh ? '● Đã làm nhận chính' : 'Đặt làm nhận chính',
                            style: TextStyle(
                              color: tk.laNhanChinh ? MauSac.chuDao : MauSac.phu,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
                    const Text('Tên chủ tài khoản (không dấu)', style: TextStyle(color: MauSac.chuPhu, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _tenChuTaiKhoanController,
                      style: const TextStyle(color: MauSac.chuChinh, fontSize: 14),
                      decoration: InputDecoration(
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
                          side: const BorderSide(color: MauSac.duongVienNhat),
                          shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.arrow_back_rounded, color: MauSac.chuPhu, size: 18),
                            SizedBox(width: 6),
                            Text('Quay lại', style: TextStyle(color: MauSac.chuChinh, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _dangTai ? null : _luuTaiKhoanMoi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MauSac.chuDao,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BoGoc.borderVua),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle_rounded, color: Colors.black, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Xong & Lưu lại',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
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
