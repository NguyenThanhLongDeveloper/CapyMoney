import 'package:flutter/material.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';
import '../../giao_dien/chuan_thiet_ke/bo_goc.dart';
import '../../giao_dien/chuan_thiet_ke/bieu_tuong.dart';
import '../tai_khoan/tab_tai_khoan.dart';

/// Màn hình Cấu trúc Chính (Main Navigation Screen)
/// 
/// Chứa Bottom Navigation Bar 4 Tab chuẩn và Nút Floating Action Button (+) trung tâm.
class ManHinhChinhTab extends StatefulWidget {
  /// Vị trí Tab mở ra ban đầu (Mặc định Tab 3 - Màn hình "Tôi")
  final int viTriTabBanDau;

  const ManHinhChinhTab({super.key, this.viTriTabBanDau = 3});

  @override
  State<ManHinhChinhTab> createState() => _ManHinhChinhTabState();
}

class _ManHinhChinhTabState extends State<ManHinhChinhTab> {
  late int _viTriTabHienTai;

  @override
  void initState() {
    super.initState();
    _viTriTabHienTai = widget.viTriTabBanDau;
  }

  /// Danh sách các Tab màn hình chính
  final List<Widget> _danhSachTab = [
    // Tab 1: Tổng quan (Dashboard)
    const Center(
      child: Text(
        'Màn hình Tổng quan (Dashboard)',
        style: TextStyle(color: MauSac.chuChinh, fontSize: 16),
      ),
    ),

    // Tab 2: Ngân sách & Mục tiêu
    const Center(
      child: Text(
        'Màn hình Ngân sách & Mục tiêu',
        style: TextStyle(color: MauSac.chuChinh, fontSize: 16),
      ),
    ),

    // Tab 3: Báo cáo & Phân tích
    const Center(
      child: Text(
        'Màn hình Báo cáo & Phân tích',
        style: TextStyle(color: MauSac.chuChinh, fontSize: 16),
      ),
    ),

    // Tab 4: Tôi (Profile cá nhân & Cài đặt)
    const TabTaiKhoan(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MauSac.nenChinh,
      // Dùng IndexedStack để giữ nguyên trạng thái UI của từng Tab khi chuyển đổi
      body: IndexedStack(
        index: _viTriTabHienTai,
        children: _danhSachTab,
      ),

      // Nút Nổi '+' Thêm giao dịch trung tâm
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 58,
        height: 58,
        margin: const EdgeInsets.only(top: 10),
        child: FloatingActionButton(
          onPressed: () {
            // Thao tác mở menu chọn ghi chép Chi tiêu / Thu nhập
          },
          backgroundColor: MauSac.chuDao,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.black,
            size: 32,
          ),
        ),
      ),

      // Thanh Bottom Navigation Bar 4 Tab
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: MauSac.nenThe,
          border: Border(
            top: BorderSide(color: MauSac.duongVienNhat, width: 1),
          ),
        ),
        child: BottomAppBar(
          color: MauSac.nenThe,
          elevation: 0,
          notchMargin: 8,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Tab 1: Tổng quan
                _taoItemTab(
                  index: 0,
                  icon: BieuTuong.tongQuan,
                  nhan: 'Tổng quan',
                ),

                // Tab 2: Ngân sách
                _taoItemTab(
                  index: 1,
                  icon: BieuTuong.nganSach,
                  nhan: 'Ngân sách',
                ),

                // Khoảng trống chừa vị trí cho nút '+' Trung tâm
                const SizedBox(width: 48),

                // Tab 3: Báo cáo
                _taoItemTab(
                  index: 2,
                  icon: BieuTuong.baoCao,
                  nhan: 'Báo cáo',
                ),

                // Tab 4: Tôi
                _taoItemTab(
                  index: 3,
                  icon: BieuTuong.taiKhoan,
                  nhan: 'Tôi',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hàm dựng Item Tab giao diện
  Widget _taoItemTab({
    required int index,
    required IconData icon,
    required String nhan,
  }) {
    final isSelected = _viTriTabHienTai == index;

    return InkWell(
      onTap: () => setState(() => _viTriTabHienTai = index),
      borderRadius: BoGoc.borderNho,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? MauSac.chuDao : MauSac.chuPhu,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            nhan,
            style: TextStyle(
              color: isSelected ? MauSac.chuDao : MauSac.chuPhu,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
