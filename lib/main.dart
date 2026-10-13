import 'package:flutter/material.dart';
import 'cau_hinh/cau_hinh_supabase.dart';
import 'giao_dien/chuan_thiet_ke/mau_sac.dart';
import 'giao_dien/chuan_thiet_ke/kieu_chu.dart';
import 'man_hinh/cho/man_hinh_cho.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Supabase client
  try {
    await CauHinhSupabase.khoiTao();
  } catch (e) {
    debugPrint('Chua cau hinh URL Supabase thuc te: $e');
  }

  runApp(const CapyMoneyApp());
}

class CapyMoneyApp extends StatelessWidget {
  const CapyMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capy Money',
      debugShowCheckedModeBanner: false,
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
      home: const ManHinhCho(),
    );
  }
}
