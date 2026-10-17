import 'package:supabase_flutter/supabase_flutter.dart';

/// Quản lý thông số cấu hình và điểm kết nối Supabase Backend cho CapyMoney
class CauHinhSupabase {
  CauHinhSupabase._();

  /// Địa chỉ URL dự án Supabase CapyMoney
  static const String urlSupabase = 'https://cznvpofurgjynzjgjdem.supabase.co';

  /// Khóa công khai Anon Key cho phép truy cập API
  static const String anonKeySupabase = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN6bnZwb2Z1cmdqeW56amdqZGVtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE3NDg4ODYsImV4cCI6MjEwNzMyNDg4Nn0.TkIS8EgBknAsRRvuring0V6xlAOe1YvvuVj6SMUGCUM';

  /// Khởi tạo phiên kết nối Supabase SDK
  static Future<void> khoiTao() async {
    await Supabase.initialize(
      url: urlSupabase,
      anonKey: anonKeySupabase,
    );
  }

  /// Truy xuất Supabase Client dùng chung trong toàn bộ ứng dụng
  static SupabaseClient get client => Supabase.instance.client;
}
