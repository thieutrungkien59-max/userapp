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
  late Future<List<CustomerOrder>> _orders;
  @override
  void initState() {
    super.initState();
    _orders = _load();
  }

  Future<List<CustomerOrder>> _load({bool forceRefresh = false}) =>
      appState.value.customerId == null
      ? Future.value([])
      : ordersApi.forCustomer(
          appState.value.customerId!,
          forceRefresh: forceRefresh,
        );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('Danh sach don hang'),
    bottomNavigationBar: const AppNav(1),
    body: RefreshIndicator(
      onRefresh: () async =>
          setState(() => _orders = _load(forceRefresh: true)),
      child: FutureBuilder<List<CustomerOrder>>(
        future: _orders,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
              child: PrimaryButton(
                'Tai lai',
                icon: Icons.refresh,
                onTap: () => setState(() => _orders = _load()),
              ),
            );
          final orders = snapshot.data ?? [];
          if (orders.isEmpty)
            return ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                CardBox(child: Text('Ban chua co don hang nao.')),
              ],
            );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: orders
                .map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OrderCard(order),
                  ),
                )
                .toList(),
          );
        },
      ),
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
              Text('Ma don: ${order.id}', style: GoogleFonts.ibmPlexMono()),
              Badge(order.status, color: appRed),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.deliveryAddress,
            style: const TextStyle(color: AppColors.muted),
          ),
          const Divider(height: 25),
          Text('COD: ${order.codAmount} d'),
          const SizedBox(height: 6),
          Text(
            'Phi van chuyen: ${order.shippingFee} d',
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    ),
  );
}

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('Chi tiet don hang', fallbackRoute: '/orders'),
    body: FutureBuilder<OrderDetailData?>(
      future: ordersApi.detailById(orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError || snapshot.data == null)
          return const Center(child: Text('Khong the tai thong tin don hang.'));
        final detail = snapshot.data!;
        final order = detail.order;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ma don: ${order.id}', style: GoogleFonts.ibmPlexMono()),
                  const SizedBox(height: 12),
                  Badge(order.status, color: appRed),
                  const Divider(height: 24),
                  Text('Lay hang: ${order.pickupAddress}'),
                  const SizedBox(height: 8),
                  Text('Giao hang: ${order.deliveryAddress}'),
                  const SizedBox(height: 8),
                  Text('COD: ${order.codAmount} d'),
                  const SizedBox(height: 8),
                  Text('Phi van chuyen: ${order.shippingFee} d'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lich su trang thai',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  if (detail.history.isEmpty) const Text('Chua co lich su.'),
                  ...detail.history.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history, color: appRed),
                      title: Text(item.status),
                      subtitle: Text(
                        [item.time, item.note]
                            .whereType<String>()
                            .where((value) => value.isNotEmpty)
                            .join('\n'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
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
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('Minh chung giao hang', fallbackRoute: '/orders'),
    body: FutureBuilder<OrderDetailData?>(
      future: ordersApi.detailById(orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        final proof = snapshot.data?.proof;
        if (proof == null)
          return const Center(
            child: Text('Don hang chua co minh chung giao hang.'),
          );
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Minh chung giao hang',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  if (proof.imageUrl != null && proof.imageUrl!.isNotEmpty)
                    Image.network(
                      proof.imageUrl!,
                      errorBuilder: (_, _, _) =>
                          const Text('Khong tai duoc anh minh chung.'),
                    )
                  else
                    const Text('Chua co anh minh chung.'),
                  if (proof.otpSignature != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text('Chu ky/OTP: ${proof.otpSignature}'),
                    ),
                  if (proof.time != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Thoi gian: ${proof.time}'),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}
