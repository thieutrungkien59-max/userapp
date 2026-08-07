import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';

class SessionStore {
  static const _customerId = 'customer_id';
  static const _name = 'customer_name';
  static const _phone = 'customer_phone';
  static const _email = 'customer_email';
  static const _address = 'customer_address';

  Future<bool> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getString(_customerId);
    if (customerId == null || customerId.isEmpty) return false;
    appState.value = AppState(
      customerId: customerId,
      name: prefs.getString(_name) ?? '',
      phone: prefs.getString(_phone) ?? '',
      email: prefs.getString(_email) ?? '',
      defaultAddress: prefs.getString(_address) ?? '',
    );
    return true;
  }

  Future<void> save(AppState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customerId, state.customerId ?? '');
    await prefs.setString(_name, state.name);
    await prefs.setString(_phone, state.phone);
    await prefs.setString(_email, state.email);
    await prefs.setString(_address, state.defaultAddress);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_customerId),
      prefs.remove(_name),
      prefs.remove(_phone),
      prefs.remove(_email),
      prefs.remove(_address),
    ]);
  }
}

final sessionStore = SessionStore();
