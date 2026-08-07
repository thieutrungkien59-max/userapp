class PeakHourConfig {
  const PeakHourConfig({
    required this.maCd,
    required this.gioBatDau,
    required this.gioKetThuc,
    required this.heSoPhi,
    required this.isActive,
    required this.cacNgayApDung,
    this.moTa,
  });

  final String maCd;
  final String gioBatDau;
  final String gioKetThuc;
  final double heSoPhi;
  final String? moTa;
  final bool isActive;

  /// Chuỗi 7 ký tự theo thứ tự T2 -> CN.
  /// Ví dụ: 1111100 = áp dụng từ Thứ 2 đến Thứ 6.
  final String cacNgayApDung;

  factory PeakHourConfig.fromJson(Map<String, dynamic> json) {
    final rawDays = json['cacNgayApDung']?.toString().trim() ?? '0000000';

    return PeakHourConfig(
      maCd: (json['maCd'] ?? json['MaCd'] ?? '').toString().trim(),
      gioBatDau: (json['gioBatDau'] ?? json['GioBatDau'] ?? '00:00:00')
          .toString(),
      gioKetThuc: (json['gioKetThuc'] ?? json['GioKetThuc'] ?? '00:00:00')
          .toString(),
      heSoPhi: _parseDouble(json['heSoPhi'] ?? json['HeSoPhi'], fallback: 1),
      moTa: (json['moTa'] ?? json['MoTa'])?.toString(),
      isActive: _parseBool(
        json['isActive'] ?? json['IsActive'],
        // Không tự bật cảnh báo nếu backend cũ chưa trả field IsActive.
        fallback: false,
      ),
      // Không tự áp dụng ngày nào nếu backend thiếu CacNgayApDung.
      cacNgayApDung: rawDays.length == 7 ? rawDays : '0000000',
    );
  }

  bool isActiveAt(DateTime now) {
    if (!isActive) return false;
    if (cacNgayApDung.length != 7) return false;

    final start = _minutesFromTimeString(gioBatDau);
    final end = _minutesFromTimeString(gioKetThuc);
    final current = now.hour * 60 + now.minute;

    // DateTime.weekday:
    // Monday = 1 ... Sunday = 7
    final currentDayIndex = now.weekday - 1;

    // Khung giờ cùng ngày, ví dụ 07:30 -> 19:30
    if (start <= end) {
      return _isDayEnabled(currentDayIndex) &&
          current >= start &&
          current <= end;
    }

    // Khung giờ qua nửa đêm, ví dụ 22:00 -> 05:00.
    if (current >= start) {
      return _isDayEnabled(currentDayIndex);
    }

    if (current <= end) {
      final previousDayIndex = (currentDayIndex + 6) % 7;
      return _isDayEnabled(previousDayIndex);
    }

    return false;
  }

  bool _isDayEnabled(int index) {
    if (index < 0 || index >= cacNgayApDung.length) return false;
    return cacNgayApDung[index] == '1';
  }

  String get displayTimeRange =>
      '${_shortTime(gioBatDau)} - ${_shortTime(gioKetThuc)}';

  String get displayMultiplier {
    final rounded = heSoPhi.roundToDouble();

    if (heSoPhi == rounded) {
      return 'x${rounded.toInt()}';
    }

    return 'x$heSoPhi';
  }

  static int _minutesFromTimeString(String value) {
    final parts = value.trim().split(':');
    if (parts.length < 2) return 0;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    return hour * 60 + minute;
  }

  static String _shortTime(String value) {
    final parts = value.trim().split(':');

    if (parts.length < 2) return value;

    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }
}

double _parseDouble(dynamic value, {required double fallback}) {
  if (value is num) return value.toDouble();

  if (value is String) {
    return double.tryParse(value.trim()) ?? fallback;
  }

  return fallback;
}

bool _parseBool(dynamic value, {required bool fallback}) {
  if (value is bool) return value;

  if (value is num) {
    return value != 0;
  }

  if (value is String) {
    final normalized = value.trim().toLowerCase();

    if (normalized == 'true' || normalized == '1') {
      return true;
    }

    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }

  return fallback;
}
