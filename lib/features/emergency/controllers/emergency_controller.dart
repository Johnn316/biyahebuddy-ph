import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/di/providers.dart';

/// "Ligtas ka ba?" answer: true = may sugatan, false = walang sugatan,
/// null = not answered yet.
final injuredProvider = StateProvider.autoDispose<bool?>((ref) => null);

/// Ticked items (indexes into [emergencyChecklist]).
final checklistProvider = StateProvider.autoDispose<Set<int>>((ref) => {});

const emergencyChecklist = [
  'I-on ang hazard lights at ilagay ang early warning device',
  'Kunan ng litrato ang eksena at mga plate BAGO galawin ang sasakyan',
  'Kunin ang lisensya, plate no., at insurer ng kabilang driver',
  'Huwag pumirma o umamin ng kasalanan on the spot',
  'Kumuha ng police report',
];

final emergencyHotlinesProvider = FutureProvider.autoDispose<List<Hotline>>(
  (ref) => ref.watch(hotlineRepositoryProvider).forZone(null),
);

typedef SosCapabilities = ({bool sms, bool call});

/// Can this device text / call? Used to grey out buttons. If a check itself
/// fails we assume yes: the action then reports a clear [SosUnavailable].
final sosCapabilitiesProvider = FutureProvider.autoDispose<SosCapabilities>((
  ref,
) async {
  final sos = ref.watch(sosServiceProvider);
  Future<bool> check(Future<bool> Function() f) async {
    try {
      return await f();
    } catch (_) {
      return true;
    }
  }

  final (sms, call) = await (check(sos.canSendSms), check(sos.canCall)).wait;
  return (sms: sms, call: call);
});

/// Emergency numbers work without a SIM, so these are never greyed out.
const alwaysCallable = {'911', '112'};

/// SOS SMS text: says it's from BiyaheBuddy PH and who needs help, so it
/// doesn't look like spam. Uses whatever profile fields exist (empty ones are
/// skipped, never "null"). The injury line appears once "Ligtas ka ba?" is
/// answered. Plain text, no emojis, no links (PH networks block SMS with
/// URLs); > 160 chars, so the native side sends it as a multipart SMS.
/// Keep in sync with VolumeSosService.sosMessage.
String buildSosMessage(
  ({double lat, double lng})? location,
  bool? injured, {
  Profile? profile,
  DateTime? now,
}) {
  String? clean(String? v) {
    final t = v?.trim() ?? '';
    return t.isEmpty || t == 'null' ? null : t;
  }

  final name = clean(profile?.name);
  final plate = clean(profile?.plateNo);
  final vehicle = clean(profile?.vehicleType);
  final blood = clean(profile?.bloodType);
  final who = [
    name ?? 'Ang driver na ito',
    if (plate != null) '(plate $plate)',
  ].join(' ');
  final car = [
    if (vehicle != null) 'Sasakyan: $vehicle',
    if (blood != null) 'Blood type: $blood',
  ].join(' | ');

  return [
    'BiyaheBuddy PH - SOS ALERT',
    '${name == null ? who : 'Si $who'} ay naaksidente at humihingi ng tulong.',
    if (injured == true) 'May sugatan.',
    if (injured == false) 'Walang sugatan.',
    location == null
        ? 'Lokasyon: hindi makuha ang GPS. Tawagan siya para malaman kung '
              'nasaan siya.'
        // Plain coordinates, NO link: PH networks silently drop P2P
        // texts that contain URLs (anti-scam filtering).
        : 'Lokasyon (GPS): ${location.lat.toStringAsFixed(6)}, '
              '${location.lng.toStringAsFixed(6)}\n'
              'I-paste sa Google Maps o Waze para makita.',
    if (car.isNotEmpty) car,
    'Tawagan siya agad. Kung hindi sumasagot, tumawag sa 911.',
    '- Awtomatikong ipinadala ng BiyaheBuddy PH app '
        '(${sosTime(now ?? DateTime.now())})',
  ].join('\n');
}

/// "7:52 AM, Okt 10" (offline, no intl).
String sosTime(DateTime t) {
  const months = [
    'Ene',
    'Peb',
    'Mar',
    'Abr',
    'May',
    'Hun',
    'Hul',
    'Ago',
    'Set',
    'Okt',
    'Nob',
    'Dis',
  ];
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}, ${months[t.month - 1]} ${t.day}';
}

/// Sends the SOS text (with GPS) to one or more emergency contacts.
class SosSmsController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Returns true on success.
  Future<bool> send(List<EmergencyContact> contacts) async {
    if (contacts.isEmpty || state.isLoading) return false;
    final injured = ref.read(injuredProvider);
    final sos = ref.read(sosServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final location = await sos.currentLocation();
      final profile = await ref
          .read(profileProvider.future)
          .catchError((Object _) => null);
      await sos.smsContacts(
        contacts,
        buildSosMessage(location, injured, profile: profile),
      );
    });
    return !state.hasError;
  }
}

final sosSmsControllerProvider =
    AsyncNotifierProvider.autoDispose<SosSmsController, void>(
      SosSmsController.new,
    );
