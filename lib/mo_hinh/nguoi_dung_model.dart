/// Mô hình thông tin người dùng trong CapyMoney
class NguoiDungModel {
  final String id;
  final String hoTen;
  final String email;
  final String? soDienThoai;
  final String? anhDaiDien;
  final bool baoCaoGmail;
  final bool nhacNhoGhiChep;
  final String thoiGianNhacNho;
  final DateTime? taoLuc;

  NguoiDungModel({
    required this.id,
    required this.hoTen,
    required this.email,
    this.soDienThoai,
    this.anhDaiDien,
    this.baoCaoGmail = true,
    this.nhacNhoGhiChep = true,
    this.thoiGianNhacNho = '21:30',
    this.taoLuc,
  });

  factory NguoiDungModel.fromJson(Map<String, dynamic> json) {
    return NguoiDungModel(
      id: json['id'] as String,
      hoTen: json['ho_ten'] as String? ?? 'Người dùng Capy',
      email: json['email'] as String? ?? '',
      soDienThoai: json['so_dien_thoai'] as String?,
      anhDaiDien: json['anh_dai_dien'] as String?,
      baoCaoGmail: json['bao_cao_gmail'] as bool? ?? true,
      nhacNhoGhiChep: json['nhac_nho_ghi_chep'] as bool? ?? true,
      thoiGianNhacNho: json['thoi_gian_nhac_nho'] as String? ?? '21:30',
      taoLuc: json['tao_luc'] != null ? DateTime.tryParse(json['tao_luc']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ho_ten': hoTen,
      'email': email,
      'so_dien_thoai': soDienThoai,
      'anh_dai_dien': anhDaiDien,
      'bao_cao_gmail': baoCaoGmail,
      'nhac_nho_ghi_chep': nhacNhoGhiChep,
      'thoi_gian_nhac_nho': thoiGianNhacNho,
    };
  }
}
