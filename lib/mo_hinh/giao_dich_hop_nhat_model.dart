import 'giao_dich_model.dart';
import 'lich_su_quy_model.dart';

/// Enum phân loại item trên dòng thời gian giao dịch hợp nhất
enum LoaiDongThoiGian {
  /// Thu nhập sinh hoạt thực tế
  thuNhap,

  /// Chi tiêu sinh hoạt thực tế
  chiTieu,

  /// Nạp tiền tích lũy vào Quỹ tiết kiệm
  napQuy,

  /// Rút tiền từ Quỹ tiết kiệm về ví
  rutQuy,
}

/// Mô hình giao dịch hợp nhất (Unified Timeline Transaction Model)
/// 
/// Kết hợp dữ liệu từ `giao_dich` và `lich_su_quy` trên cùng dòng thời gian
class GiaoDichHopNhatModel {
  /// Mã ID bản ghi
  final String id;

  /// Loại item trên dòng thời gian
  final LoaiDongThoiGian loai;

  /// Thời điểm phát sinh giao dịch
  final DateTime thoiGian;

  /// Số tiền giao dịch (luôn > 0)
  final double soTien;

  /// Tiêu đề chính hiển thị
  final String tieuDe;

  /// Ghi chú chi tiết
  final String ghiChu;

  /// ID Danh mục (DanhMucModel hoặc DanhMucNganSachModel)
  final String danhMucId;

  /// Bản ghi gốc giao dịch (nếu thuộc thu/chi)
  final GiaoDichModel? giaoDichGoc;

  /// Bản ghi gốc lịch sử quỹ (nếu thuộc nạp/rút quỹ)
  final LichSuQuyModel? lichSuQuyGoc;

  GiaoDichHopNhatModel({
    required this.id,
    required this.loai,
    required this.thoiGian,
    required this.soTien,
    required this.tieuDe,
    required this.ghiChu,
    required this.danhMucId,
    this.giaoDichGoc,
    this.lichSuQuyGoc,
  });

  /// Kiểm tra có phải Thu nhập thực tế
  bool get isThuNhap => loai == LoaiDongThoiGian.thuNhap;

  /// Kiểm tra có phải Chi tiêu thực tế
  bool get isChiTieu => loai == LoaiDongThoiGian.chiTieu;

  /// Kiểm tra có phải Nạp quỹ tích lũy
  bool get isNapQuy => loai == LoaiDongThoiGian.napQuy;

  /// Kiểm tra có phải Rút quỹ tích lũy
  bool get isRutQuy => loai == LoaiDongThoiGian.rutQuy;

  /// Kiểm tra có phải biến động nạp/rút quỹ
  bool get isBienDongQuy => isNapQuy || isRutQuy;

  /// Khởi tạo từ bản ghi GiaoDichModel thu chi
  factory GiaoDichHopNhatModel.fromGiaoDich(GiaoDichModel gd) {
    final bool isThu = gd.loaiGiaoDich == 'thu_nhap';
    return GiaoDichHopNhatModel(
      id: gd.id,
      loai: isThu ? LoaiDongThoiGian.thuNhap : LoaiDongThoiGian.chiTieu,
      thoiGian: gd.ngayGiaoDich,
      soTien: gd.soTien,
      tieuDe: '', // Sẽ tra cứu tên danh mục khi render
      ghiChu: gd.ghiChu ?? (isThu ? 'Ghi nhận thu nhập' : 'Ghi nhận chi tiêu'),
      danhMucId: gd.danhMucId ?? '',
      giaoDichGoc: gd,
    );
  }

  /// Khởi tạo từ bản ghi LichSuQuyModel nạp/rút quỹ
  factory GiaoDichHopNhatModel.fromLichSuQuy({
    required LichSuQuyModel ls,
    required String danhMucNganSachId,
    required String tenQuy,
  }) {
    final bool isNap = ls.isNapTien;
    final String defaultLyDo = isNap ? 'Tích lũy quỹ mục tiêu' : 'Rút tiền quỹ về ví';
    final String noteText = (ls.lyDo != null && ls.lyDo!.isNotEmpty) ? ls.lyDo! : defaultLyDo;

    return GiaoDichHopNhatModel(
      id: ls.id,
      loai: isNap ? LoaiDongThoiGian.napQuy : LoaiDongThoiGian.rutQuy,
      thoiGian: ls.taoLuc ?? DateTime.now(),
      soTien: ls.soTien.abs(),
      tieuDe: isNap ? 'Nạp $tenQuy' : 'Rút $tenQuy',
      ghiChu: noteText,
      danhMucId: danhMucNganSachId,
      lichSuQuyGoc: ls,
    );
  }
}
