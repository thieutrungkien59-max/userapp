import 'package:shared_preferences/shared_preferences.dart';

class DefaultPickupLocation {
  const DefaultPickupLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final double latitude;
  final double longitude;

  bool get isValid =>
      address.trim().isNotEmpty &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

/// Frontend-only persistence cho điểm lấy mặc định.
///
/// Đây KHÔNG phải dữ liệu mock:
/// - Customer chọn pin thật trên flutter_map.
/// - App reverse-geocode tọa độ thật bằng Nominatim.
/// - Tọa độ + địa chỉ được lưu cục bộ bằng SharedPreferences.
/// - Create Order đọc lại đúng dữ liệu đã lưu.
///
/// Khi backend hỗ trợ lat/lng profile, chỉ cần thay implementation store này
/// bằng API; UI/picker không cần đổi lớn.
class DefaultPickupStore {
  const DefaultPickupStore();

  String _prefix(String customerId) =>
      'customer_default_pickup_${customerId.trim()}';

  Future<DefaultPickupLocation?> load(String customerId) async {
    if (customerId.trim().isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final prefix = _prefix(customerId);

    final address = prefs.getString('${prefix}_address');
    final latitude = prefs.getDouble('${prefix}_latitude');
    final longitude = prefs.getDouble('${prefix}_longitude');

    if (address == null ||
        address.trim().isEmpty ||
        latitude == null ||
        longitude == null) {
      return null;
    }

    final result = DefaultPickupLocation(
      address: address.trim(),
      latitude: latitude,
      longitude: longitude,
    );

    return result.isValid ? result : null;
  }

  Future<void> save(
    String customerId,
    DefaultPickupLocation location,
  ) async {
    if (customerId.trim().isEmpty) {
      throw ArgumentError('customerId không được để trống.');
    }

    if (!location.isValid) {
      throw ArgumentError('Điểm lấy mặc định không hợp lệ.');
    }

    final prefs = await SharedPreferences.getInstance();
    final prefix = _prefix(customerId);

    await prefs.setString(
      '${prefix}_address',
      location.address.trim(),
    );
    await prefs.setDouble(
      '${prefix}_latitude',
      location.latitude,
    );
    await prefs.setDouble(
      '${prefix}_longitude',
      location.longitude,
    );
  }

  Future<void> clear(String customerId) async {
    if (customerId.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final prefix = _prefix(customerId);

    await prefs.remove('${prefix}_address');
    await prefs.remove('${prefix}_latitude');
    await prefs.remove('${prefix}_longitude');
  }
}

const defaultPickupStore = DefaultPickupStore();
