import 'package:flutter/material.dart' hide Badge;
import 'package:go_router/go_router.dart';

import '../../../core/state/app_state.dart';
import '../../../core/state/session_store.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../theme/app_colors.dart';
import '../data/default_pickup_store.dart';
import 'edit_customer_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  DefaultPickupLocation? _defaultPickup;
  bool _loadingPickup = true;

  @override
  void initState() {
    super.initState();
    _loadDefaultPickup();
  }

  Future<void> _loadDefaultPickup() async {
    final customerId = appState.value.customerId;

    if (customerId == null || customerId.isEmpty) {
      if (mounted) {
        setState(() => _loadingPickup = false);
      }
      return;
    }

    final pickup = await defaultPickupStore.load(customerId);

    if (!mounted) return;

    setState(() {
      _defaultPickup = pickup;
      _loadingPickup = false;
    });
  }

  Future<void> _openEditProfile(BuildContext context, AppState state) async {
    final customerId = state.customerId;

    if (customerId == null || customerId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không tìm thấy mã khách hàng. Vui lòng đăng nhập lại.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EditCustomerProfileScreen(
          customerId: customerId,
          fullName: state.name,
          phone: state.phone,
          email: state.email,
          address: state.defaultAddress,
        ),
      ),
    );

    await _loadDefaultPickup();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('Hồ sơ khách hàng'),
    bottomNavigationBar: const AppNav(3),
    body: ValueListenableBuilder<AppState>(
      valueListenable: appState,
      builder: (context, state, child) => ListView(
        padding: const EdgeInsets.all(18),
        children: [
          CardBox(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 42,
                  child: Icon(Icons.person, size: 42),
                ),
                const SizedBox(height: 14),
                Text(
                  state.name.isEmpty ? 'Khách hàng' : state.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Badge(
                  state.phone.isEmpty ? 'Chưa cập nhật SĐT' : state.phone,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          CardBox(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Họ và tên'),
                  subtitle: Text(
                    state.name.isEmpty ? 'Chưa cập nhật' : state.name,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Số điện thoại'),
                  subtitle: Text(
                    state.phone.isEmpty ? 'Chưa cập nhật' : state.phone,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(
                    state.email.isEmpty ? 'Chưa cập nhật' : state.email,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.add_location_alt_outlined),
                  title: const Text('Điểm lấy hàng mặc định'),
                  subtitle: _loadingPickup
                      ? const Text('Đang tải...')
                      : Text(
                          _defaultPickup == null
                              ? 'Chưa thiết lập'
                              : _defaultPickup!.address,
                        ),
                  trailing: _defaultPickup == null
                      ? null
                      : const Icon(Icons.check_circle, color: Colors.green),
                ),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Mã khách hàng'),
                  subtitle: Text(state.customerId ?? 'Không có dữ liệu'),
                  trailing: const Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            'Chỉnh sửa hồ sơ',
            icon: Icons.edit_outlined,
            onTap: () => _openEditProfile(context, state),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            'Đăng xuất',
            outline: true,
            icon: Icons.logout,
            onTap: () async {
              appState.value = AppState();
              await sessionStore.clear();

              if (!context.mounted) return;
              context.go('/login');
            },
          ),
        ],
      ),
    ),
  );
}
