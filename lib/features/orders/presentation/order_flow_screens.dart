import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Badge;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/state/app_state.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../theme/app_colors.dart';
import '../data/orders_api.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<CustomerOrder>? _currentOrders;
  bool _isInitialLoading = true;
  String? _errorMessage;

  Timer? _pollTimer;
  bool _isPolling = false;

  static const Duration _pollInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();

    _loadInitial();

    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollOrders());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<List<CustomerOrder>> _load({bool forceRefresh = false}) {
    final customerId = appState.value.customerId;

    return customerId == null
        ? Future.value([])
        : ordersApi.forCustomer(customerId, forceRefresh: forceRefresh);
  }

  Future<void> _loadInitial() async {
    try {
      final orders = await _load(forceRefresh: true);

      if (!mounted) return;

      setState(() {
        _currentOrders = orders;
        _errorMessage = null;
        _isInitialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _pollOrders() async {
    if (_isPolling || !mounted) return;

    _isPolling = true;

    try {
      final freshOrders = await _load(forceRefresh: true);

      if (!mounted) return;

      // Không thay ScrollView/FutureBuilder => không reset scroll.
      setState(() {
        _currentOrders = freshOrders;
        _errorMessage = null;
      });
    } catch (_) {
      // Giữ UI cũ nếu poll lỗi.
    } finally {
      _isPolling = false;
    }
  }

  Future<void> _refresh() async {
    try {
      final freshOrders = await _load(forceRefresh: true);

      if (!mounted) return;

      setState(() {
        _currentOrders = freshOrders;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể làm mới: '
            '${e.toString().replaceAll('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('Danh sách đơn hàng'),
    bottomNavigationBar: const AppNav(1),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_isInitialLoading && _currentOrders == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _currentOrders == null) {
      return Center(
        child: PrimaryButton(
          'Tải lại',
          icon: Icons.refresh,
          onTap: _loadInitial,
        ),
      );
    }

    final orders = _currentOrders ?? [];

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        key: const PageStorageKey<String>('customer-orders-list'),
        padding: const EdgeInsets.all(16),
        children: [
          if (orders.isEmpty)
            const CardBox(child: Text('Bạn chưa có đơn hàng nào.'))
          else
            ...orders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrderCard(order),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard(this.order);

  final CustomerOrder order;

  String _money(num value) {
    final raw = value.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < raw.length; i++) {
      final remaining = raw.length - i;
      buffer.write(raw[i]);

      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()} đ';
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.go('/orders/${order.id}/status'),
    child: CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Mã đơn: ${order.id}',
                  style: GoogleFonts.ibmPlexMono(),
                ),
              ),
              const SizedBox(width: 8),
              Badge(customerOrderStatusLabel(order.status), color: appRed),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.deliveryAddress.isEmpty
                ? 'Chưa có địa chỉ giao'
                : order.deliveryAddress,
            style: const TextStyle(color: AppColors.muted),
          ),
          const Divider(height: 25),
          Text('COD: ${_money(order.codAmount)}'),
          const SizedBox(height: 6),
          Text(
            'Phí vận chuyển: '
            '${_money(order.shippingFee)}',
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    ),
  );
}

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  OrderDetailData? _currentDetail;
  bool _isInitialLoading = true;
  String? _errorMessage;

  Timer? _pollTimer;
  bool _isPolling = false;

  static const Duration _pollInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();

    _loadInitial();

    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollDetail());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    try {
      final detail = await ordersApi.detailById(widget.orderId);

      if (!mounted) return;

      setState(() {
        _currentDetail = detail;
        _errorMessage = detail == null ? 'Không tìm thấy đơn hàng.' : null;
        _isInitialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _pollDetail() async {
    if (_isPolling || !mounted) return;

    _isPolling = true;

    try {
      final fresh = await ordersApi.detailById(widget.orderId);

      if (!mounted || fresh == null) return;

      // Chỉ đổi data của các Text/Timeline trong ListView đang tồn tại.
      // ScrollController/ScrollPosition không bị destroy.
      setState(() {
        _currentDetail = fresh;
        _errorMessage = null;
      });
    } catch (_) {
      // Giữ dữ liệu cũ nếu poll lỗi.
    } finally {
      _isPolling = false;
    }
  }

  String _display(String? value, {String fallback = '---'}) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _money(num value) {
    final raw = value.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < raw.length; i++) {
      final remaining = raw.length - i;
      buffer.write(raw[i]);

      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()} đ';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('Chi tiết đơn hàng', fallbackRoute: '/orders'),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_isInitialLoading && _currentDetail == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentDetail == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage ?? 'Không thể tải thông tin đơn hàng.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadInitial,
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại'),
            ),
          ],
        ),
      );
    }

    final detail = _currentDetail!;
    final order = detail.order;

    return ListView(
      key: PageStorageKey<String>('customer-order-detail-${widget.orderId}'),
      padding: const EdgeInsets.all(16),
      children: [
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mã đơn: ${order.id}',
                style: GoogleFonts.ibmPlexMono(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Badge(customerOrderStatusLabel(order.status), color: appRed),
            ],
          ),
        ),

        const SizedBox(height: 14),

        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin người gửi',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 22),
              _InfoLine(
                icon: Icons.person_outline,
                label: 'Họ tên',
                value: _display(order.senderName),
              ),
              _InfoLine(
                icon: Icons.phone_outlined,
                label: 'Số điện thoại',
                value: _display(order.senderPhone),
              ),
              _InfoLine(
                icon: Icons.location_on_outlined,
                label: 'Địa chỉ lấy',
                value: _display(order.pickupAddress),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin người nhận',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 22),
              _InfoLine(
                icon: Icons.person_outline,
                label: 'Họ tên',
                value: _display(order.receiverName),
              ),
              _InfoLine(
                icon: Icons.phone_outlined,
                label: 'Số điện thoại',
                value: _display(order.receiverPhone),
              ),
              _InfoLine(
                icon: Icons.location_on_outlined,
                label: 'Địa chỉ giao',
                value: _display(order.deliveryAddress),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin đơn hàng',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 22),
              _InfoLine(
                icon: Icons.scale_outlined,
                label: 'Khối lượng',
                value: order.weightKg == null ? '---' : '${order.weightKg} kg',
              ),
              _InfoLine(
                icon: Icons.straighten_outlined,
                label: 'Kích thước',
                value: _display(order.sizeText),
              ),
              _InfoLine(
                icon: Icons.route_outlined,
                label: 'Quãng đường',
                value: order.distanceKm == null
                    ? '---'
                    : '${order.distanceKm} km',
              ),
              _InfoLine(
                icon: Icons.payments_outlined,
                label: 'COD',
                value: _money(order.codAmount),
              ),
              _InfoLine(
                icon: Icons.local_shipping_outlined,
                label: 'Phí vận chuyển',
                value: _money(order.shippingFee),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lịch sử trạng thái',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              if (detail.history.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Chưa có lịch sử trạng thái.'),
                )
              else
                ...detail.history.asMap().entries.map(
                  (entry) => _HistoryItem(
                    item: entry.value,
                    isLast: entry.key == detail.history.length - 1,
                  ),
                ),
            ],
          ),
        ),

        if (detail.proof != null) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProofScreen(orderId: order.id),
                  ),
                );
              },
              icon: const Icon(Icons.verified_outlined),
              label: const Text('XEM MINH CHỨNG GIAO HÀNG'),
              style: ElevatedButton.styleFrom(
                backgroundColor: appRed,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.item, required this.isLast});

  final OrderStatusHistory item;
  final bool isLast;

  String _formatTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';

    final date = DateTime.tryParse(raw)?.toLocal();

    if (date == null) return raw;

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(date.hour)}:${two(date.minute)} '
        '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final timeText = _formatTime(item.time);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Icon(
                isLast
                    ? Icons.radio_button_checked
                    : Icons.check_circle_outline,
                color: appRed,
                size: 20,
              ),
              if (!isLast)
                Container(width: 2, height: 54, color: Colors.red.shade100),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerOrderStatusLabel(item.status),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (timeText.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    timeText,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  customerHistoryDescription(
                    item.status,
                    backendNote: item.note,
                  ),
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('Theo doi don hang', fallbackRoute: '/orders'),
    body: Center(
      child: Text(
        'API chua co endpoint vi tri shipper cho don $orderId.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class ProofScreen extends StatelessWidget {
  const ProofScreen({super.key, required this.orderId});
  final String orderId;

  String _formatProofTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '';
    }

    final date = DateTime.tryParse(raw)?.toLocal();

    if (date == null) {
      return raw;
    }

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(date.hour)}:${two(date.minute)}'
        ' • ${two(date.day)}/${two(date.month)}/${date.year}';
  }

  Uint8List? _decodeDataUri(String? value) {
    if (value == null || value.isEmpty) return null;

    final index = value.indexOf(',');
    if (!value.startsWith('data:image/') || index < 0) {
      return null;
    }

    try {
      return base64Decode(value.substring(index + 1));
    } catch (_) {
      return null;
    }
  }

  Widget _imageFromProof(String? value, {required String emptyText}) {
    if (value == null || value.trim().isEmpty) {
      return Text(emptyText);
    }

    final bytes = _decodeDataUri(value);

    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text('Không hiển thị được ảnh.'),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        value,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Text('Không tải được ảnh.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('Minh chứng giao hàng', fallbackRoute: '/orders'),
    body: FutureBuilder<OrderDetailData?>(
      future: ordersApi.detailById(orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final proof = snapshot.data?.proof;

        if (proof == null) {
          return const Center(
            child: Text('Đơn hàng chưa có minh chứng giao hàng.'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ảnh giao hàng',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _imageFromProof(
                    proof.imageUrl,
                    emptyText: 'Chưa có ảnh giao hàng.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chữ ký người nhận',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _imageFromProof(
                    proof.otpSignature,
                    emptyText: 'Chưa có chữ ký.',
                  ),
                ],
              ),
            ),
            if (proof.time != null && proof.time!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              CardBox(
                child: Row(
                  children: [
                    const Icon(Icons.schedule_outlined, color: appRed),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Thời gian xác nhận: ${_formatProofTime(proof.time)}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    ),
  );
}
