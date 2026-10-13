import 'package:supabase_flutter/supabase_flutter.dart';

/// Cấu hình kết nối Supabase cho ứng dụng CapyMoney
class CauHinhSupabase {
  CauHinhSupabase._();

  // URL và Anon Key của dự án Supabase
  static const String urlSupabase = 'https://cznvpofurgjynzjgjdem.supabase.co';
  static const String anonKeySupabase = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN6bnZwb2Z1cmdqeW56amdqZGVtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE3NDg4ODYsImV4cCI6MjEwNzMyNDg4Nn0.TkIS8EgBknAsRRvuring0V6xlAOe1YvvuVj6SMUGCUM';

  /// Khởi tạo Supabase client
  static Future<void> khoiTao() async {
    await Supabase.initialize(
      url: urlSupabase,
      anonKey: anonKeySupabase,
    );
  }

  /// Supabase Client dùng chung trong ứng dụng
  static SupabaseClient get client => Supabase.instance.client;
}
