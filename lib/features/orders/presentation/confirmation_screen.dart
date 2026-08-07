import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../../../theme/app_colors.dart';

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Spacer(),
            const CircleAvatar(
              radius: 47,
              backgroundColor: Color(0xFFD7EDE3),
              child: Icon(
                Icons.check_circle_outline,
                size: 52,
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              'Đã gửi yêu cầu tạo đơn',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đơn đã được lưu trên hệ thống. Mã đơn và trạng thái sẽ hiển thị trong danh sách đơn hàng.',
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            PrimaryButton(
              'Xem đơn hàng',
              icon: Icons.inventory_2_outlined,
              onTap: () => context.go('/orders'),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              'Về trang chủ',
              outline: true,
              onTap: () => context.go('/home'),
            ),
          ],
        ),
      ),
    ),
  );
}
