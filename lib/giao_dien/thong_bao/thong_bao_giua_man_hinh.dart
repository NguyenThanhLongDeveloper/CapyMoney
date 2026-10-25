import 'dart:async';
import 'package:flutter/material.dart';
import '../chuan_thiet_ke/mau_sac.dart';
import '../chuan_thiet_ke/bo_goc.dart';
import '../chuan_thiet_ke/khoang_cach.dart';

/// Enum phân loại các dạng thông báo
enum LoaiThongBao {
  thanhCong,
  canhBao,
  loi,
}

/// Bảng Thông Báo Chính Giữa Màn Hình (Central Floating Toast Dialog)
/// 
/// Thiết kế chuẩn Kinetic Neo-Fintech Dark Mode hiển thị thẻ thông báo nổi giữa màn hình 
/// kèm hiệu ứng viền phát sáng và tự động ẩn sau 1.5 giây (1500ms).
class ThongBaoGiuaManHinh {
  ThongBaoGiuaManHinh._();

  /// Hiển thị Bảng thông báo chính giữa màn hình tự động biến mất sau 1.5s
  static void hienThi(
    BuildContext context, {
    required String noiDung,
    LoaiThongBao loai = LoaiThongBao.canhBao,
    Duration thoiGianHien = const Duration(milliseconds: 1500),
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        // Tự động đóng Dialog chính giữa sau đúng 1.5 giây
        Timer(thoiGianHien, () {
          if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
            Navigator.of(dialogContext, rootNavigator: true).pop();
          }
        });

        Color colorBorder;
        IconData iconData;

        switch (loai) {
          case LoaiThongBao.thanhCong:
            colorBorder = MauSac.chuDao;
            iconData = Icons.check_circle_rounded;
            break;
          case LoaiThongBao.loi:
            colorBorder = MauSac.chiTieu;
            iconData = Icons.error_rounded;
            break;
          case LoaiThongBao.canhBao:
            colorBorder = MauSac.canhBao;
            iconData = Icons.warning_amber_rounded;
            break;
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            padding: KhoangCach.lToanBoLon,
            decoration: BoxDecoration(
              color: MauSac.nenThe,
              borderRadius: BoGoc.borderLon,
              border: Border.all(color: colorBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: colorBorder.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorBorder.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: colorBorder, size: 30),
                ),
                const SizedBox(height: KhoangCach.vua),
                Text(
                  noiDung,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: MauSac.chuChinh,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
