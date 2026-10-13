/// Mô hình quỹ tiết kiệm & mục tiêu tích lũy
class QuyTietKiemModel {
  final String id;
  final String nguoiDungId;
  final String tenQuy;
  final String bieuTuong;
  final double soTienMucTieu;
  final double soTienHienCo;
  final String? nguonTrichId;
  final int kyHanThang;
  final DateTime? ngayVeDich;
  final bool nhacNhoDinhKy;
  final DateTime? taoLuc;

  QuyTietKiemModel({
    required this.id,
    required this.nguoiDungId,
    required this.tenQuy,
    this.bieuTuong = 'xe_may',
    required this.soTienMucTieu,
    this.soTienHienCo = 0.0,
    this.nguonTrichId,
    this.kyHanThang = 12,
    this.ngayVeDich,
    this.nhacNhoDinhKy = true,
    this.taoLuc,
  });

  double get phanTramHoanThanh =>
      soTienMucTieu > 0 ? (soTienHienCo / soTienMucTieu) * 100 : 0;

  double get soTienConLai =>
      soTienMucTieu > soTienHienCo ? soTienMucTieu - soTienHienCo : 0;

  factory QuyTietKiemModel.fromJson(Map<String, dynamic> json) {
    return QuyTietKiemModel(
      id: json['id'] as String,
      nguoiDungId: json['nguoi_dung_id'] as String,
      tenQuy: json['ten_quy'] as String,
      bieuTuong: json['bieu_tuong'] as String? ?? 'xe_may',
      soTienMucTieu: (json['so_tien_muc_tieu'] as num).toDouble(),
      soTienHienCo: (json['so_tien_hien_co'] as num?)?.toDouble() ?? 0.0,
      nguonTrichId: json['nguon_trich_id'] as String?,
      kyHanThang: json['ky_han_thang'] as int? ?? 12,
      ngayVeDich: json['ngay_ve_dich'] != null ? DateTime.tryParse(json['ngay_ve_dich']) : null,
      nhacNhoDinhKy: json['nhac_nho_dinh_ky'] as bool? ?? true,
      taoLuc: json['tao_luc'] != null ? DateTime.tryParse(json['tao_luc']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nguoi_dung_id': nguoiDungId,
      'ten_quy': tenQuy,
      'bieu_tuong': bieuTuong,
      'so_tien_muc_tieu': soTienMucTieu,
      'so_tien_hien_co': soTienHienCo,
      'nguon_trich_id': nguonTrichId,
      'ky_han_thang': kyHanThang,
      'ngay_ve_dich': ngayVeDich?.toIso8601String(),
      'nhac_nho_dinh_ky': nhacNhoDinhKy,
    };
  }
}
