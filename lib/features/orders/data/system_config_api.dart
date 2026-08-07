import '../../../core/network/api_client.dart';
import 'peak_hour_model.dart';

class SystemConfigApi {
  const SystemConfigApi();

  Future<PeakHourConfig?> getPeakHourConfig() async {
    final response = await apiClient.get('/api/SystemConfig/gio-cao-diem');

    if (response == null) {
      return null;
    }

    // Backend hiện tại trả List và sau mỗi lần Admin lưu
    // sẽ xóa cấu hình cũ rồi thêm lại đúng 1 cấu hình mới.
    if (response is List) {
      if (response.isEmpty) {
        return null;
      }

      // Nếu backend cũ vẫn còn nhiều record, ưu tiên record cuối cùng
      // thay vì record đầu tiên rất cũ.
      final current = response.last;

      if (current is Map) {
        return PeakHourConfig.fromJson(Map<String, dynamic>.from(current));
      }

      throw const FormatException(
        'Dữ liệu cấu hình giờ cao điểm không hợp lệ.',
      );
    }

    // Giữ tương thích nếu backend về sau đổi GET sang trả object.
    if (response is Map) {
      return PeakHourConfig.fromJson(Map<String, dynamic>.from(response));
    }

    throw const FormatException(
      'Dữ liệu cấu hình giờ cao điểm không đúng định dạng.',
    );
  }
}

const systemConfigApi = SystemConfigApi();
