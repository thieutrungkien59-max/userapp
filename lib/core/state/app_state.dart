import 'package:flutter/foundation.dart';

final appState = ValueNotifier(AppState());

class AppState {
  AppState({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.defaultAddress = '',
    this.customerId,
  });
  final String name, phone, email, defaultAddress;
  final String? customerId;
  AppState copyWith({
    String? name,
    String? phone,
    String? email,
    String? defaultAddress,
    String? customerId,
  }) => AppState(
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    defaultAddress: defaultAddress ?? this.defaultAddress,
    customerId: customerId ?? this.customerId,
  );
}
