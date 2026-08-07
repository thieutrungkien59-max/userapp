import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/app_state.dart';
import '../../../core/state/session_store.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../theme/app_colors.dart';
import '../data/auth_api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phone = TextEditingController(), password = TextEditingController();
  bool obscure = true;
  bool submitting = false;
  @override
  void dispose() {
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (phone.text.length != 10 || password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'S\u1ed1 \u0111i\u1ec7n tho\u1ea1i ph\u1ea3i \u0111\u1ee7 10 s\u1ed1 v\u00e0 m\u1eadt kh\u1ea9u t\u1ed1i thi\u1ec3u 6 k\u00fd t\u1ef1.',
          ),
        ),
      );
      return;
    }
    setState(() => submitting = true);
    try {
      final session = await authApi.login(
        username: phone.text.trim(),
        password: password.text,
      );
      appState.value = appState.value.copyWith(
        customerId: session.customerId,
        name: session.name,
        phone: session.phone,
        email: session.email,
        defaultAddress: session.defaultAddress,
      );
      await sessionStore.save(appState.value);
      if (mounted) context.go('/home');
    } catch (error) {
      if (mounted) _showApiError(context, error);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Spacer(flex: 2),
            const Brand(large: true),
            const SizedBox(height: 10),
            const Text(
              'H\u1ec7 th\u1ed1ng qu\u1ea3n l\u00fd v\u1eadn h\u00e0nh',
              style: TextStyle(color: AppColors.muted),
            ),
            const Spacer(),
            InputBox(
              'S\u1ed1 \u0111i\u1ec7n tho\u1ea1i',
              'Nh\u1eadp S\u0110T 10 s\u1ed1',
              controller: phone,
              icon: Icons.phone_android,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'M\u1eadt kh\u1ea9u',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 7),
                TextField(
                  controller: password,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    hintText: 'Nh\u1eadp m\u1eadt kh\u1ea9u',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              '\u0110\u0103ng nh\u1eadp',
              icon: Icons.login,
              onTap: submitting ? null : login,
            ),
            const SizedBox(height: 22),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text(
                'Ch\u01b0a c\u00f3 t\u00e0i kho\u1ea3n? \u0110\u0103ng k\u00fd',
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    ),
  );
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController(),
      phone = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  bool accepted = false;
  bool submitting = false;
  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final validEmail =
        email.text.isEmpty ||
        (email.text.contains('@') && email.text.contains('.'));
    if (name.text.trim().isEmpty ||
        phone.text.length != 10 ||
        password.text.length < 6 ||
        !accepted ||
        !validEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui l\u00f2ng nh\u1eadp h\u1ecd t\u00ean, S\u0110T \u0111\u1ee7 10 s\u1ed1, email h\u1ee3p l\u1ec7 v\u00e0 \u0111\u1ed3ng \u00fd \u0111i\u1ec1u kho\u1ea3n.',
          ),
        ),
      );
      return;
    }
    setState(() => submitting = true);
    try {
      // The phone number doubles as the username because this UI asks users
      // to sign in with their phone number.
      final session = await authApi.registerCustomer(
        username: phone.text.trim(),
        password: password.text,
        name: name.text.trim(),
        phone: phone.text.trim(),
        email: email.text.trim().isEmpty ? null : email.text.trim(),
      );
      appState.value = appState.value.copyWith(
        customerId: session.customerId,
        name: session.name,
        phone: session.phone,
        email: session.email,
        defaultAddress: session.defaultAddress,
      );
      await sessionStore.save(appState.value);
      if (mounted) context.go('/home');
    } catch (error) {
      if (mounted) _showApiError(context, error);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('\u0110\u0103ng k\u00fd t\u00e0i kho\u1ea3n'),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Brand(),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Tham gia m\u1ea1ng l\u01b0\u1edbi giao h\u00e0ng th\u00f4ng minh',
          ),
        ),
        const SizedBox(height: 34),
        CardBox(
          child: Column(
            children: [
              InputBox(
                'H\u1ecd v\u00e0 t\u00ean',
                'Nh\u1eadp h\u1ecd v\u00e0 t\u00ean c\u1ee7a b\u1ea1n',
                controller: name,
              ),
              const SizedBox(height: 17),
              InputBox(
                'S\u1ed1 \u0111i\u1ec7n tho\u1ea1i',
                '+84 | 09xx xxx xxx',
                controller: phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              const SizedBox(height: 17),
              InputBox(
                'Email (Kh\u00f4ng b\u1eaft bu\u1ed9c)',
                'example@email.com',
                controller: email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              InputBox(
                'M\u1eadt kh\u1ea9u',
                'T\u1ed1i thi\u1ec3u 6 k\u00fd t\u1ef1',
                controller: password,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: accepted,
                    activeColor: appRed,
                    onChanged: (value) =>
                        setState(() => accepted = value ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'T\u00f4i \u0111\u1ed3ng \u00fd v\u1edbi \u0110i\u1ec1u kho\u1ea3n d\u1ecbch v\u1ee5 v\u00e0 Ch\u00ednh s\u00e1ch b\u1ea3o m\u1eadt',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                'Ti\u1ebfp t\u1ee5c',
                icon: Icons.arrow_forward,
                onTap: submitting ? null : submit,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

void _showApiError(BuildContext context, Object error) {
  final message = error is FormatException
      ? error.message.toString()
      : 'Không thể kết nối máy chủ hoặc dữ liệu không hợp lệ. $error';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
