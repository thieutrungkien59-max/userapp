import 'dart:async';

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/state/app_state.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../profile/data/default_pickup_store.dart';
import '../data/geocoding_service.dart';
import '../data/orders_api.dart';
import '../data/peak_hour_model.dart';
import '../data/shipping_fee_api.dart';
import '../data/shipping_quote_model.dart';
import '../data/system_config_api.dart';
import 'location_picker_screen.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen>
    with WidgetsBindingObserver {
  final weight = TextEditingController();
  final cod = TextEditingController(text: '0');
  final shippingFee = TextEditingController();
  final pickupAddress = TextEditingController();
  final deliveryAddress = TextEditingController();
  final receiverName = TextEditingController();
  final receiverPhone = TextEditingController();

  LatLng? pickupLocation;
  LatLng? deliveryLocation;

  bool submitting = false;
  bool resolvingPickupAddress = false;
  bool resolvingDeliveryAddress = false;

  PeakHourConfig? _peakHourConfig;
  bool _loadingPeakHour = true;
  Timer? _peakHourRefreshTimer;

  ShippingQuote? _shippingQuote;
  bool _calculatingShippingFee = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _loadPeakHourConfig();
    _loadSavedDefaultPickup();

    // Tự đồng bộ lại cấu hình khi Customer vẫn đang mở màn tạo đơn.
    _peakHourRefreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadPeakHourConfig(),
    );
  }

  Future<void> _loadSavedDefaultPickup() async {
    final customerId = appState.value.customerId;

    if (customerId == null || customerId.isEmpty) {
      return;
    }

    try {
      final saved = await defaultPickupStore.load(customerId);

      if (!mounted || saved == null) return;

      // Không ghi đè nếu user đã tự chọn pickup trong phiên hiện tại.
      if (pickupLocation != null || pickupAddress.text.trim().isNotEmpty) {
        return;
      }

      setState(() {
        pickupLocation = LatLng(saved.latitude, saved.longitude);
        pickupAddress.text = saved.address;
      });

      // QUAN TRỌNG:
      // File hiện tại đã có flow tự tính phí thật bằng shippingFeeApi.
      // Khi default pickup được nạp, gọi lại quote để nếu delivery đã có
      // thì phí/quãng đường vẫn được tính tự động như feature hiện tại.
      await _refreshShippingQuote();
    } catch (error) {
      debugPrint('Không tải được điểm lấy mặc định cục bộ: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _loadPeakHourConfig();
    }
  }

  Future<void> _loadPeakHourConfig() async {
    try {
      final config = await systemConfigApi.getPeakHourConfig();

      if (!mounted) return;

      setState(() {
        _peakHourConfig = config;
        _loadingPeakHour = false;
      });
    } catch (error) {
      // Cảnh báo giờ cao điểm chỉ là thông tin bổ sung.
      // Không chặn tạo đơn nếu API cấu hình tạm thời gặp lỗi.
      if (!mounted) return;

      setState(() {
        _peakHourConfig = null;
        _loadingPeakHour = false;
      });

      debugPrint('Không tải được cấu hình giờ cao điểm: $error');
    }
  }

  @override
  void dispose() {
    _peakHourRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    for (final controller in [
      weight,
      cod,
      shippingFee,
      pickupAddress,
      deliveryAddress,
      receiverName,
      receiverPhone,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLocation({required bool isPickup}) async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          title: isPickup ? 'Chọn vị trí lấy hàng' : 'Chọn vị trí giao hàng',
          initialLocation: isPickup ? pickupLocation : deliveryLocation,
          routeStartLocation: isPickup ? null : pickupLocation,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      if (isPickup) {
        resolvingPickupAddress = true;
      } else {
        resolvingDeliveryAddress = true;
      }
    });

    try {
      final address = await geocodingService.reverseGeocode(result);

      if (!mounted) return;

      setState(() {
        if (isPickup) {
          pickupLocation = result;
          pickupAddress.text = address;
        } else {
          deliveryLocation = result;
          deliveryAddress.text = address;
        }
      });

      // Khi đủ cả 2 điểm, backend tính tuyến đường + phí ngay.
      await _refreshShippingQuote();
    } catch (error) {
      if (!mounted) return;

      // Không ghi đè tọa độ/địa chỉ cũ khi vị trí mới không hợp lệ
      // hoặc nằm ngoài Việt Nam.
      _error(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          if (isPickup) {
            resolvingPickupAddress = false;
          } else {
            resolvingDeliveryAddress = false;
          }
        });
      }
    }
  }

  Future<void> _refreshShippingQuote() async {
    final pickup = pickupLocation;
    final delivery = deliveryLocation;

    if (pickup == null || delivery == null) {
      if (!mounted) return;

      setState(() {
        _shippingQuote = null;
        shippingFee.clear();
      });
      return;
    }

    setState(() => _calculatingShippingFee = true);

    try {
      final quote = await shippingFeeApi.calculate(
        pickup: pickup,
        delivery: delivery,
      );

      if (!mounted) return;

      setState(() {
        _shippingQuote = quote;
        shippingFee.text = quote.shippingFee.toStringAsFixed(0);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _shippingQuote = null;
        shippingFee.clear();
      });

      _error('Không thể tính phí vận chuyển: $error');
    } finally {
      if (mounted) {
        setState(() => _calculatingShippingFee = false);
      }
    }
  }

  String _formatMoney(double value) {
    final digits = value.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      buffer.write(digits[i]);

      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()} đ';
  }

  Widget _shippingFeeSummary() {
    if (_calculatingShippingFee) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Đang tính quãng đường và phí vận chuyển...'),
          ],
        ),
      );
    }

    final quote = _shippingQuote;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: quote == null ? Colors.grey.shade50 : Colors.blue.shade50,
        border: Border.all(
          color: quote == null ? Colors.grey.shade300 : Colors.blue.shade200,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: quote == null
          ? const Text(
              'Chọn đầy đủ điểm lấy và điểm giao để hệ thống tự tính phí.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phí vận chuyển: ${_formatMoney(quote.shippingFee)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Quãng đường đường bộ: '
                  '${quote.distanceKm.toStringAsFixed(2)} km',
                ),
                Text('Thời gian dự kiến: ${quote.durationMinutes} phút'),
                if (quote.isPeakHour)
                  Text(
                    'Giờ cao điểm: x${quote.peakMultiplier}',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> submit() async {
    if (resolvingPickupAddress || resolvingDeliveryAddress) {
      _error('Ứng dụng đang xác định địa chỉ. Vui lòng chờ trong giây lát.');
      return;
    }

    final customerId = appState.value.customerId;
    final weightValue = double.tryParse(weight.text.trim());
    final codValue = double.tryParse(cod.text.trim());
    final feeValue = _shippingQuote?.shippingFee;

    if (customerId == null || customerId.isEmpty) {
      _error('Phiên đăng nhập không có mã khách hàng. Vui lòng đăng nhập lại.');
      return;
    }

    if (weightValue == null || weightValue <= 0) {
      _error('Khối lượng phải là số lớn hơn 0.');
      return;
    }

    if (codValue == null || codValue < 0) {
      _error('Tiền COD phải là số nguyên từ 0 trở lên.');
      return;
    }

    if (feeValue == null || feeValue < 0) {
      _error(
        'Chưa có phí vận chuyển hợp lệ. '
        'Vui lòng chọn đầy đủ điểm lấy và điểm giao.',
      );
      return;
    }

    if (receiverName.text.trim().isEmpty ||
        receiverPhone.text.trim().length != 10) {
      _error('Vui lòng nhập đầy đủ thông tin người nhận hợp lệ.');
      return;
    }

    if (pickupLocation == null ||
        deliveryLocation == null ||
        pickupAddress.text.trim().isEmpty ||
        deliveryAddress.text.trim().isEmpty) {
      _error('Vui lòng chọn đầy đủ vị trí lấy hàng và vị trí giao hàng.');
      return;
    }

    if (!_isValidCoordinate(pickupLocation!) ||
        !_isValidCoordinate(deliveryLocation!)) {
      _error('Tọa độ lấy hàng hoặc giao hàng không hợp lệ. Vui lòng chọn lại.');
      return;
    }

    setState(() => submitting = true);

    try {
      await ordersApi.create(
        CreateOrderRequest(
          customerId: customerId,
          receiverName: receiverName.text.trim(),
          receiverPhone: receiverPhone.text.trim(),
          pickupAddress: pickupAddress.text.trim(),
          deliveryAddress: deliveryAddress.text.trim(),
          weightKg: weightValue,
          codAmount: codValue,
          shippingFee: feeValue,
          pickupLatitude: pickupLocation!.latitude,
          pickupLongitude: pickupLocation!.longitude,
          deliveryLatitude: deliveryLocation!.latitude,
          deliveryLongitude: deliveryLocation!.longitude,
        ),
      );

      if (mounted) {
        context.go('/order-confirmation');
      }
    } catch (error) {
      _error('Tạo đơn không thành công: $error');
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  bool _isValidCoordinate(LatLng location) {
    return location.latitude >= -90 &&
        location.latitude <= 90 &&
        location.longitude >= -180 &&
        location.longitude <= 180;
  }

  void _error(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _input(
    String label,
    String hint,
    TextEditingController controller, {
    bool number = false,
    bool integerOnly = false,
    bool phone = false,
  }) {
    List<TextInputFormatter>? formatters;

    if (phone) {
      formatters = [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ];
    } else if (number && integerOnly) {
      // COD: chỉ cho nhập chữ số, không âm, không ký tự chữ.
      formatters = [FilteringTextInputFormatter.digitsOnly];
    } else if (number) {
      // Khối lượng: chỉ cho số dương dạng 5 hoặc 5.25.
      // Không cho chữ, dấu âm, nhiều dấu chấm hoặc quá 2 số thập phân.
      formatters = [
        TextInputFormatter.withFunction((oldValue, newValue) {
          if (newValue.text.isEmpty) {
            return newValue;
          }

          final valid = RegExp(r'^\d+(?:\.\d{0,2})?$').hasMatch(newValue.text);

          return valid ? newValue : oldValue;
        }),
      ];
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InputBox(
        label,
        hint,
        controller: controller,
        keyboardType: number
            ? TextInputType.numberWithOptions(decimal: !integerOnly)
            : phone
            ? TextInputType.phone
            : null,
        inputFormatters: formatters,
      ),
    );
  }

  Widget _readonlyAddress({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        readOnly: true,
        minLines: 1,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Địa chỉ sẽ tự động hiển thị sau khi chọn vị trí',
          prefixIcon: const Icon(Icons.location_on_outlined),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _locationSelector({
    required String label,
    required LatLng? location,
    required String address,
    required bool resolving,
    required VoidCallback onTap,
  }) {
    final hasLocation = location != null && address.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: hasLocation ? Colors.green : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
        color: hasLocation ? Colors.green.shade50 : null,
      ),
      child: Row(
        children: [
          Icon(
            hasLocation ? Icons.location_on : Icons.location_off,
            color: hasLocation ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: resolving
                ? const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Expanded(child: Text('Đang xác định địa chỉ...')),
                    ],
                  )
                : Text(
                    hasLocation
                        ? '$label đã xác nhận\n$address'
                        : '$label chưa được chọn',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: resolving ? null : onTap,
            child: Text(hasLocation ? 'Chọn lại' : 'Chọn trên bản đồ'),
          ),
        ],
      ),
    );
  }

  Widget _buildPeakHourWarning() {
    if (_loadingPeakHour) {
      return const SizedBox.shrink();
    }

    final config = _peakHourConfig;

    if (config == null) {
      return const SizedBox.shrink();
    }

    if (!config.isActiveAt(DateTime.now())) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đang trong giờ cao điểm',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 5),
                Text('Khung giờ: ${config.displayTimeRange}'),
                Text('Hệ số phụ phí: ${config.displayMultiplier}'),
                const SizedBox(height: 5),
                const Text(
                  'Phí vận chuyển có thể cao hơn so với thời gian thông thường.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageHeader('Tạo đơn hàng'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Thông tin đơn hàng',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          _buildPeakHourWarning(),
          _input('Khối lượng (kg)', 'Ví dụ: 2.5', weight, number: true),
          _input(
            'Tiền COD (VNĐ)',
            '0 nếu không thu hộ',
            cod,
            number: true,
            integerOnly: true,
          ),
          _shippingFeeSummary(),
          const Divider(height: 40, thickness: 4),
          const Text(
            'Lộ trình',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),

          _locationSelector(
            label: 'Vị trí lấy hàng',
            location: pickupLocation,
            address: pickupAddress.text,
            resolving: resolvingPickupAddress,
            onTap: () => _pickLocation(isPickup: true),
          ),
          _readonlyAddress(
            label: 'Địa chỉ lấy hàng',
            controller: pickupAddress,
          ),

          _locationSelector(
            label: 'Vị trí giao hàng',
            location: deliveryLocation,
            address: deliveryAddress.text,
            resolving: resolvingDeliveryAddress,
            onTap: () => _pickLocation(isPickup: false),
          ),
          _readonlyAddress(
            label: 'Địa chỉ giao hàng',
            controller: deliveryAddress,
          ),

          const Divider(height: 40, thickness: 4),
          const Text(
            'Người nhận',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          _input('Họ và tên', 'Nhập tên người nhận', receiverName),
          _input('Số điện thoại', '090xxxxxxx', receiverPhone, phone: true),
          const SizedBox(height: 16),
          PrimaryButton(
            submitting ? 'Đang tạo đơn...' : 'Xác nhận tạo đơn',
            onTap: submitting ? null : submit,
          ),
        ],
      ),
    );
  }
}
