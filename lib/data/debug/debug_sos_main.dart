// SOS debug app (backend only). Separate entrypoint, never in the real app:
//
//   flutter run -t lib/data/debug/debug_sos_main.dart
//
// Checks every SOS path on the device, incl. a Wi-Fi-only tablet (no SIM)
// and phones without Google Play Services.

import 'package:flutter/material.dart';

import '../../core/contracts/contracts.dart';
import '../sos/android_sos_service.dart';
import '../sos/sos_platform.dart';

void main() => runApp(
  const MaterialApp(title: 'debug-sos', home: DebugSosScreen()),
);

class DebugSosScreen extends StatefulWidget {
  const DebugSosScreen({super.key});

  @override
  State<DebugSosScreen> createState() => _DebugSosScreenState();
}

class _DebugSosScreenState extends State<DebugSosScreen> {
  final _number = TextEditingController();
  late final _sos = AndroidSosService(
    platform: ChannelSosPlatform(),
    loadContacts: () async => [
      if (_number.text.trim().isNotEmpty)
        EmergencyContact(name: 'Test', phone: _number.text.trim()),
    ],
  );
  final _log = <String>[];

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _run(String label, Future<Object?> Function() action) async {
    final sw = Stopwatch()..start();
    String line;
    try {
      final result = await action();
      line = '$label → ${result ?? 'OK'} (${sw.elapsedMilliseconds} ms)';
    } on SosUnavailable catch (e) {
      line = '$label → SosUnavailable: ${e.message}';
    } on Object catch (e) {
      line = '$label → CRASH-WORTHY ERROR: $e';
    }
    setState(() => _log.insert(0, line));
  }

  @override
  Widget build(BuildContext context) {
    final buttons = <(String, Future<Object?> Function())>[
      ('canSendSms / canCall',
          () async => 'sms=${await _sos.canSendSms()} call=${await _sos.canCall()}'),
      ('Location (LocationManager)', () => _sos.currentLocation()),
      ('Send test SMS',
          () => _sos.smsContacts(
                [EmergencyContact(name: 'Test', phone: _number.text.trim())],
                'BiyaheBuddy SOS test — hindi ito emergency.',
              )),
      ('Open dialer 911', () => _sos.openDialer('911')),
      ('Enable volume trigger', () => _sos.enableVolumeTrigger()),
      ('Trigger status', () => _sos.isVolumeTriggerOn()),
      ('Debug trigger (5 s countdown)', () => _sos.debugTrigger()),
      ('Disable volume trigger', () => _sos.disableVolumeTrigger()),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('/debug-sos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _number,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Test contact number (your own phone)',
            ),
          ),
          const SizedBox(height: 8),
          for (final (label, action) in buttons)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton(
                onPressed: () => _run(label, action),
                child: Text(label),
              ),
            ),
          const Divider(),
          for (final line in _log) SelectableText(line),
        ],
      ),
    );
  }
}
