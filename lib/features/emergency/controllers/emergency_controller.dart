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

/// SOS SMS text. Status sentence is left out until "Ligtas ka ba?" is answered.
String buildSosMessage(({double lat, double lng})? location, bool? injured) {
  final where = location == null
      ? 'Lokasyon: hindi makuha ang GPS.'
      : 'Lokasyon: https://maps.google.com/?q='
            '${location.lat.toStringAsFixed(6)},'
            '${location.lng.toStringAsFixed(6)}.';
  final status = switch (injured) {
    true => ' May sugatan',
    false => ' Ligtas ako',
    null => '',
  };
  return 'Naaksidente ako. $where$status';
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
      await sos.smsContacts(contacts, buildSosMessage(location, injured));
    });
    return !state.hasError;
  }
}

final sosSmsControllerProvider =
    AsyncNotifierProvider.autoDispose<SosSmsController, void>(
      SosSmsController.new,
    );
