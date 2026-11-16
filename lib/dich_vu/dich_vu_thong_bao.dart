import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Dịch vụ Quản lý Thông báo Đẩy Cục bộ (Local Push Notification Service)
/// 
/// Quản lý việc lập lịch thông báo nhắc nhở ghi chép giao dịch hàng ngày cho CapyMoney.
class DichVuThongBao {
  DichVuThongBao._();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _daKhoiTao = false;

  /// Khởi tạo plugin thông báo cục bộ và đăng ký Channel Android & Múi giờ địa phương
  static Future<void> khoiTao() async {
    if (_daKhoiTao) return;

    try {
      // 1. Khởi tạo múi giờ địa phương (Asia/Ho_Chi_Minh GMT+7)
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Bấm vào thông báo: ${details.payload}');
        },
      );

      // 2. Xin quyền gửi thông báo & Báo thức chính xác (Exact Alarm) trên Android
      final androidPlatform = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.requestNotificationsPermission();
        await androidPlatform.requestExactAlarmsPermission();
      }

      _daKhoiTao = true;
    } catch (e) {
      debugPrint('Lỗi khởi tạo DichVuThongBao: $e');
    }
  }

  /// Đặt lịch thông báo nhắc nhở ghi chép giao dịch lặp lại hàng ngày vào lúc `hour:minute`
  static Future<bool> datLichNhacNhoHangNgay({
    required int hour,
    required int minute,
  }) async {
    await khoiTao();

    try {
      // Hủy thông báo cũ trước khi đặt lịch mới
      await huyNhacNho();

      const androidDetails = AndroidNotificationDetails(
        'capymoney_nhac_nho_channel',
        'Nhắc nhở ghi chép giao dịch',
        channelDescription: 'Thông báo nhắc nhở ghi chép giao dịch hàng ngày cùng CapyMoney',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Tính mốc thời gian kế tiếp chuẩn múi giờ địa phương Việt Nam (GMT+7)
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      try {
        await _notificationsPlugin.zonedSchedule(
          888, // ID thông báo nhắc nhở cố định
          'Capy Money Chào Bạn !',
          'Bạn đã ghi chép thu chi hôm nay chưa? Dành 10 giây ghi lại giao dịch để kiểm soát tài chính nhé!',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {
        // Fallback sang inexact nếu Android OS hạn chế Exact Alarms
        await _notificationsPlugin.zonedSchedule(
          888,
          'Capy Money Chào Bạn !',
          'Bạn đã ghi chép thu chi hôm nay chưa? Dành 10 giây ghi lại giao dịch để kiểm soát tài chính nhé!',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Lỗi đặt lịch thông báo: $e');
      return false;
    }
  }

  /// Hủy bỏ thông báo nhắc nhở ghi chép hàng ngày
  static Future<void> huyNhacNho() async {
    try {
      await _notificationsPlugin.cancel(888);
    } catch (e) {
      debugPrint('Lỗi hủy thông báo: $e');
    }
  }

  /// Gửi thông báo thử nghiệm ngay lập tức để người dùng kiểm tra
  static Future<bool> guiThongBaoThu() async {
    await khoiTao();

    try {
      const androidDetails = AndroidNotificationDetails(
        'capymoney_nhac_nho_channel',
        'Nhắc nhở ghi chép giao dịch',
        channelDescription: 'Thông báo nhắc nhở ghi chép giao dịch hàng ngày cùng CapyMoney',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        999, // ID thông báo thử nghiệm
        'Capy Money 🦫 Kiểm tra thông báo!',
        'Tính năng nhắc nhở ghi chép giao dịch đã hoạt động tốt trên thiết bị của bạn!',
        notificationDetails,
      );

      return true;
    } catch (e) {
      debugPrint('Lỗi gửi thông báo thử: $e');
      return false;
    }
  }
}
