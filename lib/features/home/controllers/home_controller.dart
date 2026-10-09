import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/di/providers.dart';

/// Ticks every minute so the coding status and greeting flip on time.
final minuteTickProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

typedef HomeStatus = ({
  String plateNo,
  String name,
  String firstName,
  String vehicleType,
  CodingStatus coding,
  String greeting,
});

/// 4:00–11:59 AM umaga · 12:00–5:59 PM hapon · 6:00 PM–3:59 AM gabi.
String greetingFor(DateTime now) => switch (now.hour) {
  < 4 => 'Magandang gabi',
  < 12 => 'Magandang umaga',
  < 18 => 'Magandang hapon',
  _ => 'Magandang gabi',
};

/// Greeting, plate and MMDA coding status for the Home header.
/// null = no profile saved yet.
final homeStatusProvider = FutureProvider.autoDispose<HomeStatus?>((ref) async {
  final now = ref.watch(minuteTickProvider).valueOrNull ?? DateTime.now();
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return null;
  final coding = ref
      .watch(codingServiceProvider)
      .statusFor(profile.plateNo, now);
  return (
    plateNo: profile.plateNo,
    name: profile.name.trim(),
    firstName: profile.name.trim().split(RegExp(r'\s+')).first,
    vehicleType: profile.vehicleType,
    coding: coding,
    greeting: greetingFor(now),
  );
});

/// One law section to show as "Tip ng araw".
typedef LawTip = ({String citation, String title, String text});

/// Sections that make good tips: traffic rules a driver can act on, not
/// definitions, fees or legal boilerplate.
final _tipBoilerplate = RegExp(
  r'title|scope|short title|declaration|definition|words and phrases|'
  r'commission|fees?\b|appropriat|separability|repeal|effectivity|'
  r'implementing|information campaign|review|transitory|lien|collection|'
  r'clerks|disposal|final provisions|acquisition|deputation|education',
  caseSensitive: false,
);

/// Picks the tip for [day] from laws.json (same tip all day, new one daily).
LawTip? pickTip(List<dynamic> laws, DateTime day) {
  final candidates = [
    for (final l in laws.cast<Map<String, dynamic>>())
      if (!_tipBoilerplate.hasMatch(l['title'] as String) &&
          (l['title'] as String).length <= 40 && // a short rule fits the sign
          !(l['id'] as String).contains('-p') &&
          (l['text'] as String).length >= 120)
        l,
  ];
  if (candidates.isEmpty) return null;
  final dayOfYear = day.difference(DateTime(day.year)).inDays;
  final l = candidates[dayOfYear % candidates.length];
  return (
    citation: '${(l['source'] as String).split(' (').first} ${l['section']}',
    title: l['title'] as String,
    text: (l['text'] as String).replaceAll(RegExp(r'\s+'), ' ').trim(),
  );
}

/// "Tip ng araw" from the bundled laws.json (offline asset, not lib/data).
final tipOfDayProvider = FutureProvider.autoDispose<LawTip?>((ref) async {
  try {
    // load + decode here (not loadString, which hands files > 50 KB to an
    // isolate); laws.json is small enough to decode on the UI thread once.
    final bytes = await rootBundle.load('assets/data/laws.json');
    final json = utf8.decode(bytes.buffer.asUint8List());
    return pickTip(jsonDecode(json) as List<dynamic>, DateTime.now());
  } on Object {
    return null; // tip is optional; Home works without it
  }
});

/// GPS status chip: true = fix available, false = none, loading = checking.
final locationReadyProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    return await ref.watch(sosServiceProvider).currentLocation() != null;
  } on Object {
    return false;
  }
});
