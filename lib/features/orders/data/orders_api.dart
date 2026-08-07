import '../../../core/network/api_client.dart';

class CreateOrderRequest {
  const CreateOrderRequest({
    required this.customerId,
    required this.receiverName,
    required this.receiverPhone,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.weightKg,
    required this.codAmount,
    required this.shippingFee,
    this.pickupLatitude,
    this.pickupLongitude,
    this.deliveryLatitude,
    this.deliveryLongitude,
  });

  final String customerId,
      receiverName,
      receiverPhone,
      pickupAddress,
      deliveryAddress;
  final double weightKg, codAmount, shippingFee;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? deliveryLatitude;
  final double? deliveryLongitude;

  Map<String, dynamic> toJson() => {
    // Matches TaoDonRequest in the updated DonHang API.
    'customerId': customerId,
    'receiverName': receiverName,
    'receiverPhone': receiverPhone,
    'pickupAddress': pickupAddress,
    'deliveryAddress': deliveryAddress,
    'weightKg': weightKg,
    'codAmount': codAmount,
    'shippingFee': shippingFee,
    if (pickupLatitude != null) 'viDoLay': pickupLatitude,
    if (pickupLongitude != null) 'kinhDoLay': pickupLongitude,
    if (deliveryLatitude != null) 'viDoGiao': deliveryLatitude,
    if (deliveryLongitude != null) 'kinhDoGiao': deliveryLongitude,
  };
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.status,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.codAmount,
    required this.shippingFee,
    this.createdAt,
  });

  final String id, status, pickupAddress, deliveryAddress;
  final num codAmount, shippingFee;
  final String? createdAt;

  factory CustomerOrder.fromJson(Map<String, dynamic> json) => CustomerOrder(
    id: _value(json, const ['maDonHang', 'maDh', 'id']) ?? '',
    status:
        _value(json, const ['trangThai', 'trangThaiDonHang', 'status']) ??
        'Chưa có trạng thái',
    pickupAddress: _value(json, const ['diaChiLay', 'diaChiNguoiGui']) ?? '',
    deliveryAddress:
        _value(json, const ['diaChiGiao', 'diaChiNguoiNhan']) ?? '',
    codAmount:
        num.tryParse(
          _value(json, const ['tienCOD', 'tienCod', 'codAmount']) ?? '0',
        ) ??
        0,
    shippingFee:
        num.tryParse(
          _value(json, const ['phiVanChuyen', 'phiGiaoHang', 'shippingFee']) ??
              '0',
        ) ??
        0,
    createdAt: _value(json, const [
      'taoLuc',
      'ngayTao',
      'thoiGianTao',
      'createdAt',
    ]),
  );
}

class OrderStatusHistory {
  const OrderStatusHistory({required this.status, this.time, this.note});
  final String status;
  final String? time, note;

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) =>
      OrderStatusHistory(
        status:
            _value(json, const ['trangThaiMoi', 'trangThai', 'status']) ?? '',
        time: _value(json, const ['thoiGian', 'ngayTao', 'createdAt']),
        note: _value(json, const ['ghiChu', 'note']),
      );
}

class DeliveryProof {
  const DeliveryProof({this.imageUrl, this.otpSignature, this.time});
  final String? imageUrl, otpSignature, time;

  factory DeliveryProof.fromJson(Map<String, dynamic> json) => DeliveryProof(
    imageUrl: _value(json, const ['hinhAnh', 'hinhAnhUrl', 'imageUrl']),
    otpSignature: _value(json, const ['chuKyOtp', 'otpSignature']),
    time: _value(json, const ['thoiGian', 'ngayTao', 'createdAt']),
  );
}

class OrderDetailData {
  const OrderDetailData({
    required this.order,
    required this.history,
    this.proof,
  });
  final CustomerOrder order;
  final List<OrderStatusHistory> history;
  final DeliveryProof? proof;
}

class OrdersApi {
  final Map<String, List<CustomerOrder>> _customerCache = {};
  final Map<String, Future<List<CustomerOrder>>> _customerRequests = {};
  final Map<String, CustomerOrder> _orderCache = {};

  Future<CustomerOrder?> create(CreateOrderRequest order) async {
    final response = await apiClient.post(
      '/api/DonHang/tao-don-moi',
      data: order.toJson(),
    );
    final map = _findOrderMap(response);
    final orderId = map == null
        ? null
        : _value(map, const ['maDonHang', 'maDh', 'id']);
    if (orderId == null || orderId.isEmpty) {
      throw const FormatException(
        'Server khong tra ve ma don hang sau khi tao.',
      );
    }

    final created = CustomerOrder(
      id: orderId,
      status: 'CHO_XAC_NHAN',
      pickupAddress: order.pickupAddress,
      deliveryAddress: order.deliveryAddress,
      codAmount: order.codAmount,
      shippingFee: order.shippingFee,
      createdAt: DateTime.now().toIso8601String(),
    );
    _orderCache[orderId] = created;
    final current = _customerCache[order.customerId] ?? const [];
    _customerCache[order.customerId] = [created, ...current];
    return created;
  }

  Future<List<CustomerOrder>> forCustomer(
    String customerId, {
    bool forceRefresh = false,
  }) {
    if (!forceRefresh && _customerCache.containsKey(customerId)) {
      return Future.value(_customerCache[customerId]!);
    }
    if (!forceRefresh && _customerRequests.containsKey(customerId)) {
      return _customerRequests[customerId]!;
    }
    final request = _loadCustomerOrders(customerId);
    _customerRequests[customerId] = request;
    return request;
  }

  Future<CustomerOrder?> byId(String orderId) async {
    final detail = await detailById(orderId);
    return detail?.order;
  }

  Future<OrderDetailData?> detailById(String orderId) async {
    try {
      final response = await apiClient.get('/api/DonHang/chi-tiet/$orderId');
      if (response is! Map) return _cachedDetail(orderId);
      final root = _map(response);
      final orderMap = _mapOrNull(root['donHang']) ?? _findOrderMap(root);
      if (orderMap == null) return _cachedDetail(orderId);
      final history = _listOfMaps(
        root['lichSuTrangThai'],
      ).map(OrderStatusHistory.fromJson).toList();
      final proofMap = _mapOrNull(root['minhChung']);
      final order = CustomerOrder.fromJson(orderMap);
      _orderCache[order.id] = order;
      return OrderDetailData(
        order: order,
        history: history,
        proof: proofMap == null ? null : DeliveryProof.fromJson(proofMap),
      );
    } catch (_) {
      return _cachedDetail(orderId);
    }
  }

  Future<List<CustomerOrder>> _loadCustomerOrders(String customerId) async {
    try {
      final response = await apiClient.get('/api/DonHang/danh-sach-toan-bo');
      final orders = _findOrderMaps(response)
          .where(
            (json) => _value(json, const ['maKh', 'maKhachHang']) == customerId,
          )
          .map(CustomerOrder.fromJson)
          .toList();
      _customerCache[customerId] = orders;
      for (final order in orders) {
        if (order.id.isNotEmpty) _orderCache[order.id] = order;
      }
      return orders;
    } finally {
      _customerRequests.remove(customerId);
    }
  }

  OrderDetailData? _cachedDetail(String orderId) {
    final order = _orderCache[orderId];
    return order == null
        ? null
        : OrderDetailData(order: order, history: const []);
  }
}

final ordersApi = OrdersApi();

List<Map<String, dynamic>> _findOrderMaps(Object? value) {
  if (value is List) {
    return value.whereType<Map>().map(_map).toList();
  }
  if (value is Map) {
    final map = _map(value);
    for (final key in const [
      'data',
      'result',
      'items',
      'donHang',
      '\$values',
    ]) {
      final child = map[key];
      if (child != null) return _findOrderMaps(child);
    }
    return _value(map, const ['maDonHang', 'maDh', 'id']) == null ? [] : [map];
  }
  return [];
}

Map<String, dynamic>? _findOrderMap(Object? value) {
  final orders = _findOrderMaps(value);
  return orders.isEmpty ? null : orders.first;
}

Map<String, dynamic> _map(Map value) =>
    value.map((key, value) => MapEntry(key.toString(), value));

Map<String, dynamic>? _mapOrNull(Object? value) =>
    value is Map ? _map(value) : null;

List<Map<String, dynamic>> _listOfMaps(Object? value) {
  if (value is List) return value.whereType<Map>().map(_map).toList();
  if (value is Map) {
    final map = _map(value);
    return _listOfMaps(map['\$values'] ?? map['data'] ?? map['items']);
  }
  return [];
}

String? _value(Map<String, dynamic> map, List<String> names) {
  final wanted = names.map((name) => name.toLowerCase()).toSet();
  for (final entry in map.entries) {
    if (wanted.contains(entry.key.toLowerCase()) && entry.value != null) {
      return entry.value.toString();
    }
  }
  return null;
}
