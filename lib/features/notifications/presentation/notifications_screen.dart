import 'package:flutter/material.dart';

import '../../../shared/widgets/app_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    appBar: PageHeader('Thông báo'),
    bottomNavigationBar: AppNav(2),
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Chưa có thông báo. Backend hiện chưa cung cấp API thông báo.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
