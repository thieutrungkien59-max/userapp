import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

const appRed = AppColors.red;

class PageHeader extends StatelessWidget implements PreferredSizeWidget {
  const PageHeader(this.title, {super.key, this.fallbackRoute = '/home'});
  final String title, fallbackRoute;
  @override
  Size get preferredSize => const Size.fromHeight(64);
  @override
  Widget build(BuildContext context) => AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () =>
          context.canPop() ? context.pop() : context.go(fallbackRoute),
    ),
    title: Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        color: appRed,
        fontWeight: FontWeight.bold,
        fontSize: 21,
      ),
    ),
  );
}

class CardBox extends StatelessWidget {
  const CardBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(13),
    ),
    child: child,
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
    this.label, {
    super.key,
    this.onTap,
    this.outline = false,
    this.icon,
  });
  final String label;
  final VoidCallback? onTap;
  final bool outline;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 50,
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: icon == null ? const SizedBox() : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        foregroundColor: outline ? appRed : Colors.white,
        backgroundColor: outline ? Colors.transparent : appRed,
        side: BorderSide(color: outline ? AppColors.line : appRed),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    ),
  );
}

class InputBox extends StatelessWidget {
  const InputBox(
    this.label,
    this.hint, {
    super.key,
    this.icon,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.readOnly = false,
    this.onTap,
  });
  final String label, hint;
  final IconData? icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool readOnly;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
      ),
      const SizedBox(height: 7),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: icon == null ? null : Icon(icon),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.line),
          ),
        ),
      ),
    ],
  );
}

class Brand extends StatelessWidget {
  const Brand({super.key, this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: large ? 68 : 55,
        height: large ? 68 : 55,
        decoration: BoxDecoration(
          color: appRed,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.local_shipping, color: Colors.white, size: 32),
      ),
      const SizedBox(height: 12),
      Text(
        'LogiRoute',
        style: GoogleFonts.spaceGrotesk(
          fontSize: large ? 26 : 22,
          fontWeight: FontWeight.bold,
          color: appRed,
        ),
      ),
    ],
  );
}

class AppNav extends StatelessWidget {
  const AppNav(this.index, {super.key});
  final int index;
  @override
  Widget build(BuildContext context) {
    final tabs = [
      (Icons.home_outlined, 'Trang ch\u1ee7', '/home'),
      (Icons.inventory_2_outlined, '\u0110\u01a1n h\u00e0ng', '/orders'),
      (Icons.notifications_none, 'Th\u00f4ng b\u00e1o', '/notifications'),
      (Icons.person_outline, 'H\u1ed3 s\u01a1', '/profile'),
    ];
    return BottomNavigationBar(
      currentIndex: index,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: appRed,
      onTap: (i) => context.go(tabs[i].$3),
      items: tabs
          .map((e) => BottomNavigationBarItem(icon: Icon(e.$1), label: e.$2))
          .toList(),
    );
  }
}

class Badge extends StatelessWidget {
  const Badge(this.label, {super.key, this.color = appRed});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
    ),
  );
}
