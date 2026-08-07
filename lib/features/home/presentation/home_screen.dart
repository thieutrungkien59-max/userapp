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
  late Future<List<CustomerOrder>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = _load();
  }

  Future<List<CustomerOrder>> _load({bool forceRefresh = false}) {
    final id = appState.value.customerId;
    return id == null
        ? Future.value([])
        : ordersApi.forCustomer(id, forceRefresh: forceRefresh);
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
    body: RefreshIndicator(
      onRefresh: () async =>
          setState(() => _orders = _load(forceRefresh: true)),
      child: FutureBuilder<List<CustomerOrder>>(
        future: _orders,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError)
            return _ErrorView(onRetry: () => setState(() => _orders = _load()));
          final orders = snapshot.data ?? [];
          final active = orders
              .where(
                (order) => !order.status.toLowerCase().contains('hoàn tất'),
              )
              .toList();
          final completed = orders.length - active.length;
          return ListView(
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
                  Expanded(
                    child: _Stat('${active.length}', 'Đang xử lý', appRed),
                  ),
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
          );
        },
      ),
    ),
  );
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
    onTap: () => context.go('/orders/${order.id}/status'),
    child: CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.id, style: GoogleFonts.ibmPlexMono()),
              Badge(order.status, color: appRed),
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
