import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';

// PLACEHOLDER — Fines lookup + Kalma muna guidance.
class ViolationScreen extends StatelessWidget {
  const ViolationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: const Text('Na-flag ako'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Fines lookup + Kalma muna guidance\n\n(coming soon)',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
