import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cau_hinh/cau_hinh_supabase.dart';
import '../cau_hinh/duong_dan_api.dart';
import '../mo_hinh/nguoi_dung_model.dart';
import '../mo_hinh/tai_khoan_ngan_hang_model.dart';
import '../mo_hinh/danh_muc_model.dart';
import '../mo_hinh/danh_muc_ngan_sach_model.dart';
import '../mo_hinh/giao_dich_model.dart';
import '../mo_hinh/quy_tiet_kiem_model.dart';
import '../mo_hinh/lich_su_quy_model.dart';

/// Lớp Dịch Vụ Trung Tâm Thực Thi API và Truy Vấn CSDL Supabase
/// 
/// Đóng gói bóc tách (Encapsulate API Service Layer). UI Component chỉ cần gọi hàm sạch 
/// mà không trực tiếp truy vấn đường dẫn API hay tên bảng CSDL.
class DichVuSupabase {
  DichVuSupabase._();

  /// Supabase Client dùng chung
  static SupabaseClient get client => CauHinhSupabase.client;

  /// Lấy thông tin User hiện đang đăng nhập (hoặc null)
  static User? get nguoiDungHienTai => client.auth.currentUser;

  /// Lắng nghe sự kiện thay đổi phiên đăng nhập Auth
  static Stream<AuthState> get onAuthStateChange => client.auth.onAuthStateChange;

  // ==========================================
  // XÁC THỰC NGƯỜI DÙNG & TÀI KHOẢN (AUTH & USER PROFILE)
  // ==========================================

  /// Đăng nhập bằng Email & Mật khẩu
  static Future<AuthResponse> dangNhap(String email, String matKhau) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: matKhau,
    );
  }

  /// Đăng nhập bằng Google OAuth
  static Future<bool> dangNhapBangGoogle() async {
    return await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? Uri.base.origin : DuongDanApi.redirectLoginCallback,
    );
  }

  /// Tự động đồng bộ thông tin Google OAuth (Họ tên, Email, Avatar) vào CSDL
  /// 
  /// - KỊCH BẢN 1: Nếu cột `ho_ten` trong CSDL đã có tên thực -> BẢO TỒN NGUYÊN VẸN CSDL, không ghi đè.
  /// - KỊCH BẢN 2: Nếu `ho_ten` bị rỗng hoặc mang tên mặc định ('Chủ tài khoản' / 'Người dùng Capy') -> Cập nhật tên thực từ Google Auth sang CSDL.
  static Future<NguoiDungModel?> dongBoThongTinNguoiDungGoogle() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      // 1. Trích xuất Display Name & Avatar từ Google Authentication Metadata
      final String tenGoogle = (user.userMetadata?['display_name'] as String?) ??
          (user.userMetadata?['full_name'] as String?) ??
          (user.userMetadata?['name'] as String?) ??
          (user.userMetadata?['ho_ten'] as String?) ??
          '';

      final String? avatarGoogle = (user.userMetadata?['avatar_url'] as String?) ??
          (user.userMetadata?['picture'] as String?) ??
          (user.userMetadata?['anh_dai_dien'] as String?);

      final String emailUser = user.email ?? '';

      // 2. Truy vấn bản ghi từ CSDL nguoi_dung
      final res = await client
          .from(DuongDanApi.bangNguoiDung)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (res != null) {
        final existingModel = NguoiDungModel.fromJson(res);
        final bool isTenMacDinh = existingModel.hoTen.trim().isEmpty ||
            existingModel.hoTen == 'Người dùng Capy' ||
            existingModel.hoTen == 'Chủ tài khoản';

        // Nếu bản ghi cũ mang tên mặc định và có tên thực từ Google Auth -> Cập nhật tên thực vào CSDL!
        if (isTenMacDinh && tenGoogle.isNotEmpty) {
          await client
              .from(DuongDanApi.bangNguoiDung)
              .update({
                'ho_ten': tenGoogle,
                'anh_dai_dien': existingModel.anhDaiDien ?? avatarGoogle,
              })
              .eq('id', user.id);

          await client.auth.updateUser(
            UserAttributes(data: {
              'ho_ten': tenGoogle,
              'anh_dai_dien': existingModel.anhDaiDien ?? avatarGoogle,
            }),
          );

          return await layThongTinNguoiDung(user.id);
        }

        // KỊCH BẢN 1: Đã có tên thực riêng -> Bảo tồn 100% dữ liệu CSDL cũ
        return existingModel;
      }

      // KỊCH BẢN 2: LẦN ĐẦU TIÊN ĐĂNG NHẬP -> Tạo mới bản ghi với Tên thực từ Google Auth
      final Map<String, dynamic> payload = {
        'id': user.id,
        'ho_ten': tenGoogle.isNotEmpty ? tenGoogle : 'Chủ tài khoản',
        'email': emailUser,
        'anh_dai_dien': avatarGoogle,
      };

      await client.from(DuongDanApi.bangNguoiDung).insert(payload);

      await client.auth.updateUser(
        UserAttributes(data: {
          'ho_ten': tenGoogle.isNotEmpty ? tenGoogle : 'Chủ tài khoản',
          'anh_dai_dien': avatarGoogle,
        }),
      );

      return await layThongTinNguoiDung(user.id);
    } catch (e) {
      debugPrint('Lỗi đồng bộ người dùng Google OAuth: $e');
      return null;
    }
  }

  /// Kiểm tra địa chỉ Email đã tồn tại trong CSDL chưa
  static Future<bool> kiemTraEmailDaTonTai(String email) async {
    try {
      final response = await client
          .from(DuongDanApi.bangNguoiDung)
          .select('id')
          .eq('email', email.trim())
          .maybeSingle();
      return response != null;
    } catch (_) {
      return false;
    }
  }

  /// Đăng ký tài khoản mới và tạo hồ sơ người dùng trong CSDL
  static Future<AuthResponse> dangKy({
    required String hoTen,
    required String email,
    required String matKhau,
    String? soDienThoai,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: matKhau,
      data: {
        'ho_ten': hoTen,
        'so_dien_thoai': soDienThoai,
      },
    );

    // Cập nhật thông tin ban đầu vào bảng nguoi_dung trong CSDL
    if (response.user != null &&
        response.user!.identities != null &&
        response.user!.identities!.isNotEmpty) {
      try {
        await client.from(DuongDanApi.bangNguoiDung).upsert({
          'id': response.user!.id,
          'ho_ten': hoTen,
          'email': email,
          'so_dien_thoai': soDienThoai,
        });
      } catch (_) {}
    }

    return response;
  }

  /// Quên mật khẩu - Gửi mã OTP khôi phục về Gmail
  static Future<void> guiMaKhoiPhuc(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  /// Xác thực mã OTP và đặt mật khẩu mới
  static Future<UserResponse> capNhatMatKhauMoi({
    required String email,
    required String maOtp,
    required String matKhauMoi,
  }) async {
    await client.auth.verifyOTP(
      email: email,
      token: maOtp,
      type: OtpType.recovery,
    );
    return await client.auth.updateUser(
      UserAttributes(password: matKhauMoi),
    );
  }

  /// Đăng xuất khỏi hệ thống
  static Future<void> dangXuat() async {
    await client.auth.signOut();
  }

  /// Truy xuất Hồ sơ người dùng sạch từ CSDL bằng User ID
  static Future<NguoiDungModel?> layThongTinNguoiDung(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final res = await client
          .from(DuongDanApi.bangNguoiDung)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (res != null) {
        return NguoiDungModel.fromJson(res);
      }
    } catch (_) {}
    return null;
  }

  /// Truy xuất Hồ sơ người dùng sạch từ CSDL bằng Email
  static Future<NguoiDungModel?> layThongTinNguoiDungTheoEmail(String email) async {
    if (email.isEmpty) return null;
    try {
      final res = await client
          .from(DuongDanApi.bangNguoiDung)
          .select()
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();

      if (res != null) {
        return NguoiDungModel.fromJson(res);
      }
    } catch (_) {}
    return null;
  }

  /// Cập nhật Họ tên và Số điện thoại cá nhân vào CSDL
  static Future<bool> capNhatThongTinCaNhan({
    required String userId,
    required String hoTen,
    required String soDienThoai,
  }) async {
    try {
      // 1. Cập nhật Metadata trên Auth User
      await client.auth.updateUser(
        UserAttributes(data: {'ho_ten': hoTen, 'so_dien_thoai': soDienThoai}),
      );

      // 2. Cập nhật bản ghi trong bảng nguoi_dung
      await client
          .from(DuongDanApi.bangNguoiDung)
          .update({'ho_ten': hoTen, 'so_dien_thoai': soDienThoai})
          .eq('id', userId);

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Cập nhật cài đặt Nhắc nhở ghi chép giao dịch (Bật/tắt + Giờ nhắc)
  static Future<bool> capNhatCaiDatNhacNho({
    required String userId,
    required bool nhacNhoGhiChep,
    required String thoiGianNhacNho,
  }) async {
    try {
      await client
          .from(DuongDanApi.bangNguoiDung)
          .update({
            'nhac_nho_ghi_chep': nhacNhoGhiChep,
            'thoi_gian_nhac_nho': thoiGianNhacNho,
          })
          .eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('Lỗi cập nhật cài đặt nhắc nhở: $e');
      return false;
    }
  }

  /// Cập nhật cài đặt Báo cáo tuần qua Gmail
  static Future<bool> capNhatCaiDatBaoCaoGmail({
    required String userId,
    required bool baoCaoGmail,
  }) async {
    try {
      await client
          .from(DuongDanApi.bangNguoiDung)
          .update({'bao_cao_gmail': baoCaoGmail})
          .eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('Lỗi cập nhật cài đặt báo cáo Gmail: $e');
      return false;
    }
  }

  /// Tải ảnh đại diện mới lên Storage Bucket 'avatars' (Xóa file cũ & Đặt tên độc nhất kèm Timestamp)
  static Future<String?> taiAnhDaiDienLenStorage(XFile xFile, String userId) async {
    if (userId.isEmpty) return null;

    try {
      final bytes = await xFile.readAsBytes();
      String fileExt = xFile.name.contains('.') ? xFile.name.split('.').last.toLowerCase() : 'jpeg';
      if (fileExt == 'jpg') fileExt = 'jpeg';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$userId/avatar_$timestamp.$fileExt';
      final mimeType = 'image/$fileExt';

      // 1. Tự động dọn dẹp các tệp ảnh cũ trong thư mục userId của tháp 'avatars'
      try {
        final danhSachFileCu = await client.storage.from(DuongDanApi.thapAvatars).list(path: userId);
        if (danhSachFileCu.isNotEmpty) {
          final filesToRemove = danhSachFileCu.map((f) => '$userId/${f.name}').toList();
          await client.storage.from(DuongDanApi.thapAvatars).remove(filesToRemove);
        }
      } catch (e) {
        debugPrint('Dọn dẹp avatar cũ trên Supabase: $e');
      }

      // 2. Upload file ảnh mới với MIME type chuẩn
      await client.storage.from(DuongDanApi.thapAvatars).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: mimeType,
        ),
      );

      // 3. Trả về URL công khai
      final publicUrl = client.storage.from(DuongDanApi.thapAvatars).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Lỗi upload Supabase Storage: $e');
      return null;
    }
  }

  // ==========================================
  // TÀI KHOẢN & VÍ NGÂN HÀNG (BANK ACCOUNTS & WALLETS)
  // ==========================================

  /// Lấy danh sách ví & tài khoản ngân hàng của người dùng
  static Future<List<TaiKhoanNganHangModel>> layDanhSachTaiKhoan() async {
    final nguoiDung = client.auth.currentUser;
    if (nguoiDung == null) return [];

    final response = await client
        .from(DuongDanApi.bangTaiKhoanNganHang)
        .select()
        .eq('nguoi_dung_id', nguoiDung.id)
        .order('tao_luc', ascending: false);

    return (response as List)
        .map((e) => TaiKhoanNganHangModel.fromJson(e))
        .toList();
  }

  /// Thêm tài khoản ngân hàng mới
  static Future<TaiKhoanNganHangModel> themTaiKhoan(TaiKhoanNganHangModel model) async {
    final Map<String, dynamic> data = model.toJson();
    data.remove('id'); // Tự động để Supabase tạo UUID

    final response = await client
        .from(DuongDanApi.bangTaiKhoanNganHang)
        .insert(data)
        .select()
        .single();

    return TaiKhoanNganHangModel.fromJson(response);
  }

  /// Xóa tài khoản ngân hàng / ví liên kết
  static Future<bool> xoaTaiKhoan(String id) async {
    try {
      await client
          .from(DuongDanApi.bangTaiKhoanNganHang)
          .delete()
          .eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Đặt làm nguồn nhận tiền chính
  static Future<bool> datLamNhanChinh(String id, String userId) async {
    try {
      // 1. Đặt tất cả tài khoản của user về la_nhan_chinh = false
      await client
          .from(DuongDanApi.bangTaiKhoanNganHang)
          .update({'la_nhan_chinh': false})
          .eq('nguoi_dung_id', userId);

      // 2. Đặt tài khoản id được chọn về la_nhan_chinh = true
      await client
          .from(DuongDanApi.bangTaiKhoanNganHang)
          .update({'la_nhan_chinh': true})
          .eq('id', id);

      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // DANH MỤC THU CHI (CATEGORIES)
  // ==========================================

  /// Lấy danh sách danh mục thu chi
  static Future<List<DanhMucModel>> layDanhSachDanhMuc() async {
    final nguoiDung = client.auth.currentUser;
    final response = await client
        .from(DuongDanApi.bangDanhMuc)
        .select()
        .or('nguoi_dung_id.is.null,nguoi_dung_id.eq.${nguoiDung?.id ?? ""}');

    return (response as List).map((e) => DanhMucModel.fromJson(e)).toList();
  }

  // ==========================================
  // GIAO DỊCH THU CHI (TRANSACTIONS)
  // ==========================================

  /// Lấy danh sách tất cả nhật ký giao dịch
  static Future<List<GiaoDichModel>> layDanhSachGiaoDich() async {
    final nguoiDung = client.auth.currentUser;
    if (nguoiDung == null) return [];

    final response = await client
        .from(DuongDanApi.bangGiaoDich)
        .select()
        .eq('nguoi_dung_id', nguoiDung.id)
        .order('ngay_giao_dich', ascending: false);

    return (response as List).map((e) => GiaoDichModel.fromJson(e)).toList();
  }

  /// Thêm giao dịch mới (Chi tiêu hoặc Thu nhập) và tự động cập nhật số dư ví liên kết
  static Future<GiaoDichModel> themGiaoDich(GiaoDichModel model) async {
    final Map<String, dynamic> data = model.toJson();
    if (data['id'] == null || (data['id'] as String).isEmpty) {
      data.remove('id');
    }

    // 1. Thêm bản ghi giao dịch mới vào CSDL
    final response = await client
        .from(DuongDanApi.bangGiaoDich)
        .insert(data)
        .select()
        .single();

    final giaoDichMoi = GiaoDichModel.fromJson(response);

    // 2. Tự động cộng/trừ số dư (so_du) trong bảng tai_khoan_ngan_hang
    if (model.taiKhoanId != null && model.taiKhoanId!.isNotEmpty) {
      try {
        final tkRes = await client
            .from(DuongDanApi.bangTaiKhoanNganHang)
            .select('so_du')
            .eq('id', model.taiKhoanId!)
            .maybeSingle();

        if (tkRes != null) {
          final double soDuHienTai = (tkRes['so_du'] as num?)?.toDouble() ?? 0.0;
          final double soDuMoi = model.loaiGiaoDich == 'thu_nhap'
              ? soDuHienTai + model.soTien
              : soDuHienTai - model.soTien;

          await client
              .from(DuongDanApi.bangTaiKhoanNganHang)
              .update({'so_du': soDuMoi})
              .eq('id', model.taiKhoanId!);
        }
      } catch (e) {
        debugPrint('Lỗi tự động cập nhật số dư tài khoản: $e');
      }
    }

    return giaoDichMoi;
  }

  /// Xóa giao dịch và tự động hoàn trả số dư ví tương ứng
  static Future<bool> xoaGiaoDich(GiaoDichModel model) async {
    try {
      // 1. Hoàn trả số dư ví (so_du)
      if (model.taiKhoanId != null && model.taiKhoanId!.isNotEmpty) {
        try {
          final tkRes = await client
              .from(DuongDanApi.bangTaiKhoanNganHang)
              .select('so_du')
              .eq('id', model.taiKhoanId!)
              .maybeSingle();

          if (tkRes != null) {
            final double soDuHienTai = (tkRes['so_du'] as num?)?.toDouble() ?? 0.0;
            // Xóa khoản chi -> cộng trả lại tiền vào ví
            // Xóa khoản thu -> trừ trả lại tiền khỏi ví
            final double soDuKhaiHoan = model.loaiGiaoDich == 'thu_nhap'
                ? soDuHienTai - model.soTien
                : soDuHienTai + model.soTien;

            await client
                .from(DuongDanApi.bangTaiKhoanNganHang)
                .update({'so_du': soDuKhaiHoan})
                .eq('id', model.taiKhoanId!);
          }
        } catch (e) {
          debugPrint('Lỗi hoàn trả số dư ví khi xóa giao dịch: $e');
        }
      }

      // 2. Xóa bản ghi giao dịch
      await client
          .from(DuongDanApi.bangGiaoDich)
          .delete()
          .eq('id', model.id);

      return true;
    } catch (e) {
      debugPrint('Lỗi xóa giao dịch: $e');
      return false;
    }
  }

  /// Cập nhật giao dịch đã có và tự động điều chỉnh cân bằng lại số dư ví tương ứng
  static Future<bool> capNhatGiaoDich({
    required GiaoDichModel giaoDichCu,
    required GiaoDichModel giaoDichMoi,
  }) async {
    try {
      // 1. Hoàn trả tác động số dư của giao dịch cũ
      if (giaoDichCu.taiKhoanId != null && giaoDichCu.taiKhoanId!.isNotEmpty) {
        try {
          final tkResCu = await client
              .from(DuongDanApi.bangTaiKhoanNganHang)
              .select('so_du')
              .eq('id', giaoDichCu.taiKhoanId!)
              .maybeSingle();

          if (tkResCu != null) {
            final double soDuCuHienTai = (tkResCu['so_du'] as num?)?.toDouble() ?? 0.0;
            final double soDuCuKhaiHoan = giaoDichCu.loaiGiaoDich == 'thu_nhap'
                ? soDuCuHienTai - giaoDichCu.soTien
                : soDuCuHienTai + giaoDichCu.soTien;

            await client
                .from(DuongDanApi.bangTaiKhoanNganHang)
                .update({'so_du': soDuCuKhaiHoan})
                .eq('id', giaoDichCu.taiKhoanId!);
          }
        } catch (e) {
          debugPrint('Lỗi hoàn trả số dư ví cũ: $e');
        }
      }

      // 2. Cập nhật bản ghi trong bảng giao_dich
      final dataMoi = giaoDichMoi.toJson();
      await client
          .from(DuongDanApi.bangGiaoDich)
          .update(dataMoi)
          .eq('id', giaoDichMoi.id);

      // 3. Áp dụng tác động số dư của giao dịch mới
      if (giaoDichMoi.taiKhoanId != null && giaoDichMoi.taiKhoanId!.isNotEmpty) {
        try {
          final tkResMoi = await client
              .from(DuongDanApi.bangTaiKhoanNganHang)
              .select('so_du')
              .eq('id', giaoDichMoi.taiKhoanId!)
              .maybeSingle();

          if (tkResMoi != null) {
            final double soDuMoiHienTai = (tkResMoi['so_du'] as num?)?.toDouble() ?? 0.0;
            final double soDuMoiCapNhat = giaoDichMoi.loaiGiaoDich == 'thu_nhap'
                ? soDuMoiHienTai + giaoDichMoi.soTien
                : soDuMoiHienTai - giaoDichMoi.soTien;

            await client
                .from(DuongDanApi.bangTaiKhoanNganHang)
                .update({'so_du': soDuMoiCapNhat})
                .eq('id', giaoDichMoi.taiKhoanId!);
          }
        } catch (e) {
          debugPrint('Lỗi áp dụng số dư ví mới: $e');
        }
      }

      return true;
    } catch (e) {
      debugPrint('Lỗi cập nhật giao dịch: $e');
      return false;
    }
  }

  /// Tải ảnh hóa đơn chứng từ lên Storage Bucket 'hoa_don'
  static Future<String?> taiHoaDonLenStorage(XFile xFile, String userId) async {
    if (userId.isEmpty) return null;

    try {
      final bytes = await xFile.readAsBytes();
      String fileExt = xFile.name.contains('.') ? xFile.name.split('.').last.toLowerCase() : 'jpeg';
      if (fileExt == 'jpg') fileExt = 'jpeg';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$userId/hoadon_$timestamp.$fileExt';
      final mimeType = 'image/$fileExt';

      await client.storage.from(DuongDanApi.thapHoaDon).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: mimeType,
        ),
      );

      final publicUrl = client.storage.from(DuongDanApi.thapHoaDon).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Lỗi upload hóa đơn Storage: $e');
      return null;
    }
  }

  // ==========================================
  // QUỸ TIẾT KIỆM & MỤC TIÊU (SAVINGS FUNDS)
  // ==========================================

  /// Lấy danh sách danh mục ngân sách & tiết kiệm từ bảng public.danh_muc_ngan_sach
  static Future<List<DanhMucNganSachModel>> layDanhSachDanhMucNganSach() async {
    final nguoiDung = client.auth.currentUser;

    final response = await client
        .from(DuongDanApi.bangDanhMucNganSach)
        .select()
        .or('nguoi_dung_id.is.null${nguoiDung != null ? ',nguoi_dung_id.eq.${nguoiDung.id}' : ''}');

    return (response as List).map((e) => DanhMucNganSachModel.fromJson(e)).toList();
  }

  /// Lấy danh sách các quỹ tiết kiệm
  static Future<List<QuyTietKiemModel>> layDanhSachQuy() async {
    final nguoiDung = client.auth.currentUser;
    if (nguoiDung == null) return [];

    final response = await client
        .from(DuongDanApi.bangQuyTietKiem)
        .select()
        .eq('nguoi_dung_id', nguoiDung.id)
        .order('tao_luc', ascending: false);

    return (response as List).map((e) => QuyTietKiemModel.fromJson(e)).toList();
  }

  /// Tạo khoản tiết kiệm / mục tiêu mới
  static Future<QuyTietKiemModel> taoQuyMoi(QuyTietKiemModel model) async {
    final response = await client
        .from(DuongDanApi.bangQuyTietKiem)
        .insert(model.toJson())
        .select()
        .single();

    return QuyTietKiemModel.fromJson(response);
  }

  /// Nạp tiền hoặc Rút tiền khỏi quỹ
  static Future<bool> capNhatSoDuQuy({
    required String quyId,
    required double soTienThayDoi, // Dương nếu nạp, Âm nếu rút
    required String loaiThaoTac, // 'nap_tien' hoac 'rut_tien'
    String? lyDo,
    String? taiKhoanId,
  }) async {
    final nguoiDung = client.auth.currentUser;
    if (nguoiDung == null) return false;

    // 1. Lấy thông tin quỹ hiện tại
    final quyData = await client
        .from(DuongDanApi.bangQuyTietKiem)
        .select()
        .eq('id', quyId)
        .single();

    final quy = QuyTietKiemModel.fromJson(quyData);
    final soDuMoi = quy.soTienHienCo + soTienThayDoi;

    // 2. Cập nhật số dư quỹ
    await client
        .from(DuongDanApi.bangQuyTietKiem)
        .update({'so_tien_hien_co': soDuMoi})
        .eq('id', quyId);

    // 3. Ghi nhật ký lịch sử quỹ
    final lichSu = LichSuQuyModel(
      id: '',
      quyId: quyId,
      nguoiDungId: nguoiDung.id,
      taiKhoanId: taiKhoanId,
      loaiThaoTac: loaiThaoTac,
      soTien: soTienThayDoi.abs(),
      lyDo: lyDo,
      maThamChieu: 'CAPY-${DateTime.now().millisecondsSinceEpoch}',
    );

    await client.from(DuongDanApi.bangLichSuQuy).insert({
      'quy_id': lichSu.quyId,
      'nguoi_dung_id': lichSu.nguoiDungId,
      'tai_khoan_id': lichSu.taiKhoanId,
      'loai_thao_tac': lichSu.loaiThaoTac,
      'so_tien': lichSu.soTien,
      'ly_do': lichSu.lyDo,
      'ma_tham_chieu': lichSu.maThamChieu,
    });

    return true;
  }
}
