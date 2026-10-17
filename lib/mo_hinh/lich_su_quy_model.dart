/// Mô hình dữ liệu Nhật ký Nạp / Rút Quỹ Tiết Kiệm (Savings Fund History Model)
/// 
/// Lưu vết chi tiết các thao tác nạp tiền hoặc rút tiền từ Quỹ trong bảng `lich_su_quy`.
class LichSuQuyModel {
  /// Mã định danh lịch sử (UUID)
  final String id;

  /// Mã quỹ tiết kiệm liên quan
  final String quyId;

  /// Mã người dùng thực hiện
  final String nguoiDungId;

  /// Nguồn tiền liên quan (Tài khoản ngân hàng / Ví)
  final String? taiKhoanId;

  /// Loai thao tác: `nap_tien` hoặc `rut_tien`
  final String loaiThaoTac;

  /// Số tiền biến động
  final double soTien;

  /// Diễn giải / Lý do nạp rút
  final String? lyDo;

  /// Mã tham chiếu ngân hàng
  final String? maThamChieu;

  /// Thời điểm nạp rút
  final DateTime? taoLuc;

  LichSuQuyModel({
    required this.id,
    required this.quyId,
    required this.nguoiDungId,
    this.taiKhoanId,
    required this.loaiThaoTac,
    required this.soTien,
    this.lyDo,
    this.maThamChieu,
    this.taoLuc,
  });

  /// Khởi tạo đối tượng LichSuQuyModel từ bản ghi JSON của Supabase
  factory LichSuQuyModel.fromJson(Map<String, dynamic> json) {
    return LichSuQuyModel(
      id: json['id'] as String,
      quyId: json['quy_id'] as String,
      nguoiDungId: json['nguoi_dung_id'] as String,
      taiKhoanId: json['tai_khoan_id'] as String?,
      loaiThaoTac: json['loai_thao_tac'] as String,
      soTien: (json['so_tien'] as num).toDouble(),
      lyDo: json['ly_do'] as String?,
      maThamChieu: json['ma_tham_chieu'] as String?,
      taoLuc: json['tao_luc'] != null ? DateTime.tryParse(json['tao_luc']) : null,
    );
  }

  /// Chuyển đổi đối tượng sang định dạng JSON để ghi vào Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quy_id': quyId,
      'nguoi_dung_id': nguoiDungId,
      'tai_khoan_id': taiKhoanId,
      'loai_thao_tac': loaiThaoTac,
      'so_tien': soTien,
      'ly_do': lyDo,
      'ma_tham_chieu': maThamChieu,
    };
  }
}
