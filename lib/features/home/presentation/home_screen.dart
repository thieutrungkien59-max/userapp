import 'dart:async';

import 'package:flutter/material.dart' hide Badge;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/state/app_state.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../theme/app_colors.dart';
import '../../orders/data/orders_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<List<CustomerOrder>> _load({bool forceRefresh = false}) {
    final id = appState.value.customerId;

    return id == null
        ? Future.value([])
        : ordersApi.forCustomer(id, forceRefresh: forceRefresh);
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

  void _startPolling() {
    _pollTimer?.cancel();

    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollOrders());
  }

  Future<void> _pollOrders() async {
    if (_isPolling || !mounted) return;

    _isPolling = true;

    try {
      final freshOrders = await _load(forceRefresh: true);

      if (!mounted) return;

      // QUAN TRỌNG:
      // Chỉ cập nhật data. Không thay FutureBuilder/ListView bằng widget
      // loading nên ScrollPosition hiện tại được giữ nguyên.
      setState(() {
        _currentOrders = freshOrders;
        _errorMessage = null;
      });
    } catch (_) {
      // Poll lỗi tạm thời: giữ nguyên UI/data hiện có.
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
    appBar: AppBar(
      title: Text(
        'LogiRoute',
        style: GoogleFonts.spaceGrotesk(
          color: appRed,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      centerTitle: true,
    ),
    bottomNavigationBar: const AppNav(0),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_isInitialLoading && _currentOrders == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _currentOrders == null) {
      return _ErrorView(onRetry: _loadInitial);
    }

    final orders = _currentOrders ?? [];

    final active = orders
        .where((order) => isCustomerOrderActive(order.status))
        .toList();

    final completed = orders
        .where((order) => isCustomerOrderCompleted(order.status))
        .length;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        // Key ổn định giúp Flutter giữ nguyên ScrollPosition khi setState.
        key: const PageStorageKey<String>('customer-home-list'),
        padding: const EdgeInsets.all(18),
        children: [
          PrimaryButton(
            'Tạo đơn hàng',
            icon: Icons.add_box_outlined,
            onTap: () => context.go('/create-order'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _Stat('${active.length}', 'Đang xử lý', appRed)),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat('$completed', 'Hoàn thành', AppColors.green),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Đơn hàng đang xử lý',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 12),
          if (active.isEmpty)
            const CardBox(child: Text('Chưa có đơn hàng đang xử lý.'))
          else
            ...active
                .take(3)
                .map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OrderCard(order),
                  ),
                ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: PrimaryButton('Tải lại', icon: Icons.refresh, onTap: onRetry),
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.color);
  final String value, label;
  final Color color;
  @override
  Widget build(BuildContext context) => CardBox(
    padding: const EdgeInsets.all(11),
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    ),
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard(this.order);
  final CustomerOrder order;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/orders/${order.id}/status'),
    child: CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.id, style: GoogleFonts.ibmPlexMono()),
              Badge(customerOrderStatusLabel(order.status), color: appRed),
            ],
          ),
          const Divider(height: 22),
          Text(
            order.deliveryAddress.isEmpty
                ? 'Chưa có địa chỉ giao'
                : order.deliveryAddress,
          ),
        ],
      ),
    ),
  );
}
