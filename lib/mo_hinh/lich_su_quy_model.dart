/// Mô hình lịch sử thao tác nạp / rút quỹ tiết kiệm
class LichSuQuyModel {
  final String id;
  final String quyId;
  final String nguoiDungId;
  final String? taiKhoanId;
  final String loaiThaoTac; // nap_tien hoac rut_tien
  final double soTien;
  final String? lyDo;
  final String? maThamChieu;
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
