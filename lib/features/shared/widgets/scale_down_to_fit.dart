import 'package:flutter/material.dart';

/// Lays [child] out at the full available width (so text wraps normally),
/// then scales it down only if it's taller than the space — no overflow on
/// short screens or with the largest system font.
class ScaleDownToFit extends StatelessWidget {
  const ScaleDownToFit({
    super.key,
    required this.child,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: SizedBox(width: box.maxWidth, child: child),
      ),
    );
  }
}
