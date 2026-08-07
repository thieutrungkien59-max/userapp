import '../../../core/network/api_client.dart';

class CustomerSession {
  const CustomerSession({
    required this.customerId,
    required this.name,
    required this.phone,
    this.email,
    this.defaultAddress,
  });

  final String customerId;
  final String name;
  final String phone;
  final String? email;
  final String? defaultAddress;

  factory CustomerSession.fromResponse(
    Object? response, {
    required String fallbackName,
    required String fallbackPhone,
    String? fallbackEmail,
  }) {
    final data = _asMap(response);
    final customerId = _string(data, const [
      'maKhachHang',
      'maKH',
      'maKh',
      'customerId',
    ]);
    if (customerId == null || customerId.isEmpty) {
      throw const FormatException(
        'Server không trả về mã khách hàng. Hãy kiểm tra response API đăng nhập/đăng ký.',
      );
    }
    return CustomerSession(
      customerId: customerId,
      name: _string(data, const ['hoTen', 'name']) ?? fallbackName,
      phone: _string(data, const ['soDienThoai', 'phone']) ?? fallbackPhone,
      email: _string(data, const ['email']) ?? fallbackEmail,
      defaultAddress: _string(data, const ['diaChiMacDinh', 'diaChi']),
    );
  }
}

class AuthApi {
  Future<CustomerSession> registerCustomer({
    required String username,
    required String password,
    required String name,
    required String phone,
    String? email,
  }) async {
    final response = await apiClient.post(
      '/api/Auth/register-khach-hang',
      data: {
        'tenDangNhap': username,
        'matKhau': password,
        'hoTen': name,
        'soDienThoai': phone,
        'email': email,
        'diaChi': '',
      },
    );
    return _customerSessionFromAuthResponse(
      response,
      fallbackName: name,
      fallbackPhone: phone,
      fallbackEmail: email,
    );
  }

  Future<CustomerSession> login({
    required String username,
    required String password,
  }) async {
    final response = await apiClient.post(
      '/api/Auth/login',
      data: {'username': username, 'password': password},
    );
    return _customerSessionFromAuthResponse(
      response,
      fallbackName: username,
      fallbackPhone: username,
    );
  }

  Future<CustomerSession> updateCustomer({
    required String customerId,
    required String name,
    required String phone,
    String? email,
    String? address,
  }) async {
    final response = await apiClient.put(
      '/api/Auth/update-khach-hang/$customerId',
      data: {
        'hoTen': name,
        'soDienThoai': phone,
        'email': email,
        'diaChi': address,
      },
    );
    if (response is Map) {
      try {
        return CustomerSession.fromResponse(
          response,
          fallbackName: name,
          fallbackPhone: phone,
          fallbackEmail: email,
        );
      } on FormatException {
        // A success-only response is also valid for this endpoint.
      }
    }
    return CustomerSession(
      customerId: customerId,
      name: name,
      phone: phone,
      email: email,
      defaultAddress: address,
    );
  }

  /// Login/register may return a customer ID directly, or only `maTk`.
  /// The latter is resolved through the profile endpoint provided by the API.
  Future<CustomerSession> _customerSessionFromAuthResponse(
    Object? response, {
    required String fallbackName,
    required String fallbackPhone,
    String? fallbackEmail,
  }) async {
    final data = _asMap(response);
    if (_string(data, const ['maKhachHang', 'maKH', 'maKh', 'customerId']) !=
        null) {
      return CustomerSession.fromResponse(
        data,
        fallbackName: fallbackName,
        fallbackPhone: fallbackPhone,
        fallbackEmail: fallbackEmail,
      );
    }

    final accountId = _string(data, const ['maTk', 'maTaiKhoan', 'accountId']);
    if (accountId == null || accountId.isEmpty) {
      return CustomerSession.fromResponse(
        data,
        fallbackName: fallbackName,
        fallbackPhone: fallbackPhone,
        fallbackEmail: fallbackEmail,
      );
    }

    final profile = await apiClient.get('/api/Auth/profile/$accountId');
    return CustomerSession.fromResponse(
      profile,
      fallbackName: fallbackName,
      fallbackPhone: fallbackPhone,
      fallbackEmail: fallbackEmail,
    );
  }
}

final authApi = AuthApi();

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  throw const FormatException('Phản hồi từ server không có dữ liệu tài khoản.');
}

String? _string(Map<String, dynamic> data, List<String> keys) {
  final normalizedKeys = keys.map(_normalize).toSet();
  return _findValue(data, normalizedKeys);
}

String? _findValue(Object? value, Set<String> keys) {
  if (value is Map) {
    for (final entry in value.entries) {
      if (keys.contains(_normalize(entry.key.toString())) &&
          entry.value != null &&
          entry.value is! Map &&
          entry.value is! Iterable) {
        return entry.value.toString();
      }
    }
    for (final child in value.values) {
      final found = _findValue(child, keys);
      if (found != null) return found;
    }
  } else if (value is Iterable) {
    for (final child in value) {
      final found = _findValue(child, keys);
      if (found != null) return found;
    }
  }
  return null;
}

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
