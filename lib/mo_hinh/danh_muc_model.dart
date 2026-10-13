/// Mô hình danh mục thu chi
class DanhMucModel {
  final String id;
  final String? nguoiDungId;
  final String tenDanhMuc;
  final String loai; // chi_tieu hoac thu_nhap
  final String bieuTuong;
  final String mauSac;

  DanhMucModel({
    required this.id,
    this.nguoiDungId,
    required this.tenDanhMuc,
    required this.loai,
    required this.bieuTuong,
    this.mauSac = '#00F59B',
  });

  factory DanhMucModel.fromJson(Map<String, dynamic> json) {
    return DanhMucModel(
      id: json['id'] as String,
      nguoiDungId: json['nguoi_dung_id'] as String?,
      tenDanhMuc: json['ten_danh_muc'] as String,
      loai: json['loai'] as String,
      bieuTuong: json['bieu_tuong'] as String,
      mauSac: json['mau_sac'] as String? ?? '#00F59B',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nguoi_dung_id': nguoiDungId,
      'ten_danh_muc': tenDanhMuc,
      'loai': loai,
      'bieu_tuong': bieuTuong,
      'mau_sac': mauSac,
    };
  }
}
