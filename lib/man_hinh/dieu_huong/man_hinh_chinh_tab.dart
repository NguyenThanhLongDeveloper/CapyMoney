import 'package:flutter/material.dart';
import '../../giao_dien/chuan_thiet_ke/mau_sac.dart';

/// Màn hình chính chứa 4 tab & nút FAB
class ManHinhChinhTab extends StatefulWidget {
  const ManHinhChinhTab({super.key});

  @override
  State<ManHinhChinhTab> createState() => _ManHinhChinhTabState();
}

class _ManHinhChinhTabState extends State<ManHinhChinhTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MauSac.nenChinh,
      body: const Center(
        child: Text('Trang chủ 4 Tab CapyMoney'),
      ),
    );
  }
}
