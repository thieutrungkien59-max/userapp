import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:userapp/features/orders/data/orders_api.dart';

import '../../../core/state/app_state.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<CustomerNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<CustomerNotification>> _load() {
    final customerId = appState.value.customerId;

    if (customerId == null || customerId.isEmpty) {
      return Future.value([]);
    }

    return ordersApi.notificationsForCustomer(customerId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });

    await _future;
  }

  String _titleFor(String status) {
    switch (status.toLowerCase()) {
      case 'choxacnhan':
        return 'Đơn hàng đang chờ phân công';
      case 'choshipperxacnhan':
        return 'Đã tìm thấy tài xế';
      case 'daxacnhan':
        return 'Tài xế đã nhận đơn';
      case 'danggiao':
      case 'dangvanchuyen':
        return 'Đơn hàng đang được giao';
      case 'dagiao':
      case 'hoanthanh':
        return 'Giao hàng thành công';
      case 'giaothatbai':
        return 'Giao hàng thất bại';
      case 'dahuy':
        return 'Đơn hàng đã hủy';
      default:
        return 'Cập nhật đơn hàng';
    }
  }

  IconData _iconFor(String status) {
    switch (status.toLowerCase()) {
      case 'dagiao':
      case 'hoanthanh':
        return Icons.check_circle_outline;
      case 'danggiao':
      case 'dangvanchuyen':
        return Icons.local_shipping_outlined;
      case 'giaothatbai':
      case 'dahuy':
        return Icons.error_outline;
      default:
        return Icons.notifications_none;
    }
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';

    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return raw;

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(date.hour)}:${two(date.minute)} '
        '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageHeader('Thông báo'),
      bottomNavigationBar: const AppNav(2),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<CustomerNotification>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 160),
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 52,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Không tải được thông báo.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _future = _load());
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ),
                ],
              );
            }

            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 160),
                  Icon(Icons.notifications_none, size: 56, color: Colors.grey),
                  SizedBox(height: 14),
                  Text(
                    'Chưa có thông báo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: item.orderId.isEmpty
                      ? null
                      : () => context.push('/orders/${item.orderId}/status'),
                  child: CardBox(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: appRed.withOpacity(0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_iconFor(item.status), color: appRed),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _titleFor(item.status),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (item.orderId.isNotEmpty)
                                Text(
                                  'Đơn ${item.orderId}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                customerHistoryDescription(
                                  item.status,
                                  backendNote: item.note,
                                ),
                                style: const TextStyle(color: AppColors.muted),
                              ),
                              if (_formatTime(item.time).isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _formatTime(item.time),
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
