import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingException implements Exception {
  const GeocodingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GeocodingService {
  const GeocodingService();

  Future<String> reverseGeocode(LatLng location) async {
    if (!_isValidCoordinate(location)) {
      throw const GeocodingException(
        'Tọa độ đã chọn không hợp lệ. Vui lòng chọn lại vị trí.',
      );
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': location.latitude.toString(),
      'lon': location.longitude.toString(),
      'accept-language': 'vi',
      'addressdetails': '1',
      'zoom': '18',
    });

    final response = await http
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'LogiRoute-Customer-App/1.0',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw const GeocodingException(
        'Không thể xác định địa chỉ từ vị trí đã chọn.',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (decoded is! Map<String, dynamic>) {
      throw const GeocodingException('Dữ liệu địa chỉ trả về không hợp lệ.');
    }

    final rawAddress = decoded['address'];

    if (rawAddress is! Map) {
      throw const GeocodingException(
        'Không tìm thấy thông tin địa chỉ cho vị trí này.',
      );
    }

    final address = Map<String, dynamic>.from(rawAddress);

    // Nominatim trả country_code theo ISO 3166-1 alpha-2.
    // Chặn ngay tại client nếu điểm được chọn không thuộc Việt Nam.
    final countryCode = address['country_code']
        ?.toString()
        .trim()
        .toLowerCase();

    if (countryCode != 'vn') {
      throw const GeocodingException(
        'LogiRoute hiện chỉ hỗ trợ giao hàng trong lãnh thổ Việt Nam. '
        'Vui lòng chọn một vị trí tại Việt Nam.',
      );
    }

    final formatted = _formatVietnameseAddress(address);

    if (formatted.isEmpty) {
      throw const GeocodingException(
        'Không thể tạo địa chỉ từ vị trí đã chọn.',
      );
    }

    return formatted;
  }

  bool _isValidCoordinate(LatLng location) {
    return location.latitude >= -90 &&
        location.latitude <= 90 &&
        location.longitude >= -180 &&
        location.longitude <= 180;
  }

  String _formatVietnameseAddress(Map<String, dynamic> address) {
    String? firstValue(List<String> keys) {
      for (final key in keys) {
        final value = address[key]?.toString().trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
      return null;
    }

    final houseNumber = firstValue(['house_number']);

    final road = firstValue([
      'road',
      'pedestrian',
      'residential',
      'footway',
      'path',
    ]);

    // Tên địa điểm cụ thể, ví dụ trường học/bệnh viện/tòa nhà.
    final placeName = firstValue([
      'amenity',
      'building',
      'office',
      'shop',
      'tourism',
      'leisure',
    ]);

    // Cấp địa phương nhỏ: thôn/ấp/khu phố/khu dân cư.
    final localArea = firstValue(['neighbourhood', 'quarter', 'hamlet']);

    // Phường/xã/thị trấn hoặc địa phương gần nhất.
    final ward = firstValue(['suburb', 'village', 'town']);

    // Tỉnh/thành phố trực thuộc trung ương.
    // Ưu tiên state vì với dữ liệu OSM Việt Nam, state thường ổn định hơn
    // city_district/county khi xác định cấp tỉnh/thành phố.
    final province = firstValue(['state', 'city', 'province', 'municipality']);

    final parts = <String>[];

    void addUnique(String? value) {
      if (value == null) return;

      final cleaned = _cleanPart(value);
      if (cleaned.isEmpty) return;

      final normalized = _normalizeForCompare(cleaned);

      final alreadyExists = parts.any(
        (item) => _normalizeForCompare(item) == normalized,
      );

      if (!alreadyExists) {
        parts.add(cleaned);
      }
    }

    // Nếu có POI cụ thể thì giữ lại ở đầu địa chỉ.
    addUnique(placeName);

    if (road != null) {
      if (houseNumber != null && houseNumber.trim().isNotEmpty) {
        addUnique('${houseNumber.trim()} ${road.trim()}');
      } else {
        addUnique(road);
      }
    } else {
      addUnique(houseNumber);
    }

    addUnique(localArea);
    addUnique(ward);

    // Cố ý không ghép city_district/county mặc định.
    // Nominatim/OSM tại Việt Nam đôi khi trả cấp trung gian không nhất quán
    // (ví dụ gắn nhầm thành phố/quận). Tọa độ mới là nguồn sự thật;
    // địa chỉ text ưu tiên gọn và không thêm cấp hành chính đáng ngờ.
    addUnique(_normalizeProvinceName(province));

    return parts.join(', ');
  }

  String _cleanPart(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s*,\s*'), ', ');
  }

  String _normalizeForCompare(String value) {
    return value
        .toLowerCase()
        .replaceAll('thành phố', '')
        .replaceAll('tỉnh', '')
        .replaceAll('tp.', '')
        .replaceAll('tp ', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? _normalizeProvinceName(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final cleaned = _cleanPart(value);
    final normalized = cleaned.toLowerCase();

    if (normalized.contains('hồ chí minh') ||
        normalized.contains('ho chi minh')) {
      return 'TP. Hồ Chí Minh';
    }

    if (normalized.contains('hà nội') || normalized.contains('ha noi')) {
      return 'Hà Nội';
    }

    return cleaned;
  }
}

const geocodingService = GeocodingService();
