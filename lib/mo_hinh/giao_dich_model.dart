/// Mô hình nhật ký giao dịch thu chi
class GiaoDichModel {
  final String id;
  final String nguoiDungId;
  final String? taiKhoanId;
  final String? danhMucId;
  final String loaiGiaoDich; // chi_tieu hoac thu_nhap
  final double soTien;
  final String? ghiChu;
  final String? anhHoaDon;
  final DateTime ngayGiaoDich;
  final String trangThai; // da_tru, da_nhan, cho_duyet
  final DateTime? taoLuc;

  GiaoDichModel({
    required this.id,
    required this.nguoiDungId,
    this.taiKhoanId,
    this.danhMucId,
    required this.loaiGiaoDich,
    required this.soTien,
    this.ghiChu,
    this.anhHoaDon,
    required this.ngayGiaoDich,
    this.trangThai = 'da_tru',
    this.taoLuc,
  });

  factory GiaoDichModel.fromJson(Map<String, dynamic> json) {
    return GiaoDichModel(
      id: json['id'] as String,
      nguoiDungId: json['nguoi_dung_id'] as String,
      taiKhoanId: json['tai_khoan_id'] as String?,
      danhMucId: json['danh_muc_id'] as String?,
      loaiGiaoDich: json['loai_giao_dich'] as String,
      soTien: (json['so_tien'] as num).toDouble(),
      ghiChu: json['ghi_chu'] as String?,
      anhHoaDon: json['anh_hoa_don'] as String?,
      ngayGiaoDich: json['ngay_giao_dich'] != null
          ? DateTime.parse(json['ngay_giao_dich'])
          : DateTime.now(),
      trangThai: json['trang_thai'] as String? ?? 'da_tru',
      taoLuc: json['tao_luc'] != null ? DateTime.tryParse(json['tao_luc']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nguoi_dung_id': nguoiDungId,
      'tai_khoan_id': taiKhoanId,
      'danh_muc_id': danhMucId,
      'loai_giao_dich': loaiGiaoDich,
      'so_tien': soTien,
      'ghi_chu': ghiChu,
      'anh_hoa_don': anhHoaDon,
      'ngay_giao_dich': ngayGiaoDich.toIso8601String(),
      'trang_thai': trangThai,
    };
  }
}
