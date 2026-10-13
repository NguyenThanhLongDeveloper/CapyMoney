/// Mô hình tài khoản & ví ngân hàng liên kết
class TaiKhoanNganHangModel {
  final String id;
  final String nguoiDungId;
  final String tenNganHang;
  final String soTaiKhoan;
  final String tenChuTaiKhoan;
  final String loaiTaiKhoan; // ngan_hang, vi_dien_tu, tien_mat
  final double soDu;
  final bool laNhanChinh;
  final DateTime? taoLuc;

  TaiKhoanNganHangModel({
    required this.id,
    required this.nguoiDungId,
    required this.tenNganHang,
    required this.soTaiKhoan,
    required this.tenChuTaiKhoan,
    this.loaiTaiKhoan = 'ngan_hang',
    this.soDu = 0.0,
    this.laNhanChinh = false,
    this.taoLuc,
  });

  factory TaiKhoanNganHangModel.fromJson(Map<String, dynamic> json) {
    return TaiKhoanNganHangModel(
      id: json['id'] as String,
      nguoiDungId: json['nguoi_dung_id'] as String,
      tenNganHang: json['ten_ngan_hang'] as String,
      soTaiKhoan: json['so_tai_khoan'] as String,
      tenChuTaiKhoan: json['ten_chu_tai_khoan'] as String,
      loaiTaiKhoan: json['loai_tai_khoan'] as String? ?? 'ngan_hang',
      soDu: (json['so_du'] as num?)?.toDouble() ?? 0.0,
      laNhanChinh: json['la_nhan_chinh'] as bool? ?? false,
      taoLuc: json['tao_luc'] != null ? DateTime.tryParse(json['tao_luc']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nguoi_dung_id': nguoiDungId,
      'ten_ngan_hang': tenNganHang,
      'so_tai_khoan': soTaiKhoan,
      'ten_chu_tai_khoan': tenChuTaiKhoan,
      'loai_tai_khoan': loaiTaiKhoan,
      'so_du': soDu,
      'la_nhan_chinh': laNhanChinh,
    };
  }
}
