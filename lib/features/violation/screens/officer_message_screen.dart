import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/contracts/contracts.dart';
import '../controllers/violation_controller.dart';

/// Full-screen, high-contrast message to show the officer. Works in portrait
/// and landscape; the text scales to fill the screen.
class OfficerMessageScreen extends StatefulWidget {
  const OfficerMessageScreen({super.key, required this.fine});

  final Fine fine;

  static Future<void> open(BuildContext context, Fine fine) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => OfficerMessageScreen(fine: fine),
        ),
      );

  @override
  State<OfficerMessageScreen> createState() => _OfficerMessageScreenState();
}

class _OfficerMessageScreenState extends State<OfficerMessageScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values, // show status + nav bars again
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  // Lay out at full width with very large text, then shrink to
                  // fit the height: the message always fills the screen.
                  builder: (context, box) => FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: box.maxWidth,
                      child: Text(
                        officerMessage(widget.fine),
                        key: const Key('officer-message'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('officer-done'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tapos na'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
