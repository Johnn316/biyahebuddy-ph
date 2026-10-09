import 'dart:convert';

import '../../core/contracts/contracts.dart';

/// MMDA number coding from assets/data/coding.json:
/// `{scheme, hours: [{start, end}], days: {"1": [digits], ...}, notes}`
/// with ISO weekday keys (1 = Monday) and "HH:MM" 24h times.
class AssetCodingService implements CodingService {
  AssetCodingService({required this.digitsByWeekday, required this.windows});

  factory AssetCodingService.fromJson(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    return AssetCodingService(
      digitsByWeekday: {
        for (final e in (m['days'] as Map<String, dynamic>).entries)
          int.parse(e.key): (e.value as List<dynamic>).cast<int>().toSet(),
      },
      windows: [
        for (final h in m['hours'] as List<dynamic>)
          (
            start: _minutes((h as Map<String, dynamic>)['start'] as String),
            end: _minutes(h['end'] as String),
          ),
      ],
    );
  }

  /// ISO weekday (DateTime.monday = 1) → coded last plate digits.
  final Map<int, Set<int>> digitsByWeekday;

  /// Coding hours as minutes since midnight, end exclusive.
  final List<({int start, int end})> windows;

  @override
  CodingStatus statusFor(String plateNo, DateTime now) {
    final digits = plateNo.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const CodingStatus(isCoding: false, message: 'Walang plate number');
    }
    final last = int.parse(digits[digits.length - 1]);
    if (!(digitsByWeekday[now.weekday]?.contains(last) ?? false)) {
      return const CodingStatus(
        isCoding: false,
        message: 'Hindi ka coding ngayon',
      );
    }
    final minute = now.hour * 60 + now.minute;
    final inWindow = windows.any((w) => minute >= w.start && minute < w.end);
    final hours = windows.map((w) => '${_fmt(w.start)}–${_fmt(w.end)}').join(', ');
    return CodingStatus(
      isCoding: inWindow,
      message: inWindow
          ? 'CODING ka ngayon ($hours)'
          : 'Coding day mo ngayon — iwas $hours',
    );
  }

  static int _minutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// 420 → "7AM", 1230 → "8:30PM".
  static String _fmt(int minutes) {
    final h24 = minutes ~/ 60 % 24;
    final m = minutes % 60;
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final mm = m == 0 ? '' : ':${m.toString().padLeft(2, '0')}';
    return '$h12$mm${h24 < 12 ? 'AM' : 'PM'}';
  }
}
