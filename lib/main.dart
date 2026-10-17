import 'package:flutter/material.dart';
import 'cau_hinh/cau_hinh_supabase.dart';
import 'giao_dien/chuan_thiet_ke/mau_sac.dart';
import 'giao_dien/chuan_thiet_ke/kieu_chu.dart';
import 'man_hinh/cho/man_hinh_cho.dart';

/// Điểm khởi chạy chính (Entrypoint) của ứng dụng CapyMoney
void main() async {
  // Đảm bảo các khung liên kết Flutter Engine được khởi tạo sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();

  // Thử khởi tạo kết nối tới Supabase Backend
  try {
    await CauHinhSupabase.khoiTao();
  } catch (e) {
    debugPrint('Cảnh báo khởi tạo Supabase: $e');
  }

  // Chạy ứng dụng CapyMoneyApp
  runApp(const CapyMoneyApp());
}

/// Root Widget khởi tạo chủ đề (Theme) và cài đặt tổng thể cho ứng dụng CapyMoney
class CapyMoneyApp extends StatelessWidget {
  const CapyMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capy Money',
      debugShowCheckedModeBanner: false,
      // Cấu hình chủ đề Kinetic Neo-Fintech Dark Mode dùng chung
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: MauSac.nenChinh,
        fontFamily: KieuChu.fontMacDinh,
        colorScheme: const ColorScheme.dark(
          primary: MauSac.chuDao,
          secondary: MauSac.phu,
          surface: MauSac.nenThe,
          error: MauSac.chiTieu,
        ),
        useMaterial3: true,
      ),
      // Màn hình bắt đầu khi bật ứng dụng (Splash Screen)
      home: const ManHinhCho(),
    );
  }
}
