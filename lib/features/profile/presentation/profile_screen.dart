import 'package:flutter/material.dart' hide Badge;
import 'package:go_router/go_router.dart';

import '../../../core/state/app_state.dart';
import '../../../core/state/session_store.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../theme/app_colors.dart';
import '../../auth/data/auth_api.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
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
                Badge(state.phone, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: 18),
          CardBox(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Họ và tên'),
                  subtitle: Text(state.name),
                ),
                ListTile(
                  title: const Text('Số điện thoại'),
                  subtitle: Text(state.phone),
                ),
                ListTile(
                  title: const Text('Email'),
                  subtitle: Text(
                    state.email.isEmpty ? 'Chưa cập nhật' : state.email,
                  ),
                ),
                ListTile(
                  title: const Text('Địa chỉ mặc định'),
                  subtitle: Text(
                    state.defaultAddress.isEmpty
                        ? 'Chưa cập nhật'
                        : state.defaultAddress,
                  ),
                ),
                ListTile(
                  title: const Text('Mã khách hàng'),
                  subtitle: Text(state.customerId ?? 'Không có dữ liệu'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            'Chinh sua ho so',
            icon: Icons.edit_outlined,
            onTap: () => _editProfile(context, state),
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

Future<void> _editProfile(BuildContext context, AppState state) async {
  final name = TextEditingController(text: state.name);
  final phone = TextEditingController(text: state.phone);
  final email = TextEditingController(text: state.email);
  final address = TextEditingController(text: state.defaultAddress);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Chinh sua ho so'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Ho va ten')),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'So dien thoai')),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: address, minLines: 2, maxLines: 3, decoration: const InputDecoration(labelText: 'Dia chi mac dinh')),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Huy')),
        TextButton(
          onPressed: () async {
            final customerId = state.customerId;
            if (customerId == null || name.text.trim().isEmpty || phone.text.trim().isEmpty) return;
            try {
              final session = await authApi.updateCustomer(
                customerId: customerId,
                name: name.text.trim(),
                phone: phone.text.trim(),
                email: email.text.trim().isEmpty ? null : email.text.trim(),
                address: address.text.trim().isEmpty ? null : address.text.trim(),
              );
              appState.value = state.copyWith(
                name: session.name,
                phone: session.phone,
                email: session.email,
                defaultAddress: session.defaultAddress,
              );
              await sessionStore.save(appState.value);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            } catch (error) {
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Khong the cap nhat ho so: $error')),
                );
              }
            }
          },
          child: const Text('Luu'),
        ),
      ],
    ),
  );
  name.dispose(); phone.dispose(); email.dispose(); address.dispose();
}
