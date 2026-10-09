import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/violation_controller.dart';

/// Full-screen, high-contrast message to show the officer at arm's length:
/// greeting · violation · fine (huge, amber) · legal basis · request.
/// Always light text on dark (dark theme forced), portrait or landscape.
///
/// Uses the full width (24dp sides) and picks the largest font size at which
/// the whole message fits without scrolling. Lines wrap only at spaces —
/// a size where any single word would not fit is rejected.
class OfficerMessageScreen extends StatefulWidget {
  const OfficerMessageScreen({super.key, required this.fine});

  final Fine fine;

  static Future<void> open(BuildContext context, Fine fine) =>
      // Root navigator: full screen above the tab bar.
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => OfficerMessageScreen(fine: fine),
        ),
      );

  /// Smallest base (medium-line) size in portrait; below this the message
  /// scrolls. Landscape is short but wide, so it may go a bit smaller.
  static const minBase = 22.0;
  static const minBaseLandscape = 16.0;
  static const maxBase = 64.0;

  @override
  State<OfficerMessageScreen> createState() => _OfficerMessageScreenState();
}

/// The five blocks, top to bottom.
typedef OfficerLine = ({String text, double scale, FontWeight weight});

List<OfficerLine> officerLines(Fine fine) => [
  (text: 'Magandang araw po.', scale: 1.0, weight: FontWeight.w600),
  (text: fine.violation, scale: 1.3, weight: FontWeight.w800),
  (text: formatPeso(fine.amount), scale: 2.2, weight: FontWeight.w900),
  (text: fine.legalBasis, scale: 0.72, weight: FontWeight.w500),
  (
    text: 'Maaari po bang mabigyan ng official ticket? Salamat po.',
    scale: 1.0,
    weight: FontWeight.w600,
  ),
];

/// Gap between blocks, relative to the base size.
const _gapFactor = 0.55;

/// Largest base size (step 1) at which [lines] fit in [width] × [height]
/// without breaking a word. Falls back to [minBase] (the screen then
/// scrolls).
double fitOfficerBase(
  List<OfficerLine> lines,
  TextStyle style,
  double width,
  double height, {
  double minBase = OfficerMessageScreen.minBase,
}) {
  bool fits(double base) {
    var total = 0.0;
    for (final l in lines) {
      final s = style.copyWith(fontSize: base * l.scale, fontWeight: l.weight);
      // Every word must fit on a line by itself (no mid-word breaks).
      for (final word in l.text.split(RegExp(r'\s+'))) {
        final w = TextPainter(
          text: TextSpan(text: word, style: s),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        final tooWide = w.width > width;
        w.dispose();
        if (tooWide) return false;
      }
      final p = TextPainter(
        text: TextSpan(text: l.text, style: s),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: width);
      total += p.height;
      p.dispose();
    }
    total += base * _gapFactor * (lines.length - 1);
    return total <= height;
  }

  var lo = minBase;
  var hi = OfficerMessageScreen.maxBase;
  if (!fits(lo)) return lo;
  while (hi - lo > 1) {
    final mid = (lo + hi) / 2;
    if (fits(mid)) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return lo.floorToDouble();
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
    final lines = officerLines(widget.fine);
    return Theme(
      data: AppTheme.dark,
      child: Builder(
        builder: (context) {
          final scheme = context.colors;
          final p = context.palette;
          final style = (context.text.bodyLarge ?? const TextStyle()).copyWith(
            height: 1.2,
            letterSpacing: 0,
            color: scheme.onSurface,
          );
          return Scaffold(
            backgroundColor: scheme.surfaceContainerLowest,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final base = fitOfficerBase(
                            lines,
                            style,
                            box.maxWidth,
                            box.maxHeight,
                            minBase: box.maxWidth > box.maxHeight
                                ? OfficerMessageScreen.minBaseLandscape
                                : OfficerMessageScreen.minBase,
                          );
                          final colors = [
                            scheme.onSurface,
                            scheme.onSurface,
                            p.accent, // fine: amber (never red)
                            p.muted,
                            scheme.onSurface,
                          ];
                          final message = Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final (i, l) in lines.indexed) ...[
                                if (i > 0) SizedBox(height: base * _gapFactor),
                                Text(
                                  l.text,
                                  key: Key('officer-line-$i'),
                                  textAlign: TextAlign.center,
                                  // Size is chosen above; system text
                                  // scaling would break the fit.
                                  textScaler: TextScaler.noScaling,
                                  style: style.copyWith(
                                    fontSize: base * l.scale,
                                    fontWeight: l.weight,
                                    color: colors[i],
                                  ),
                                ),
                              ],
                            ],
                          );
                          return Semantics(
                            key: const Key('officer-message'),
                            label: officerMessage(widget.fine),
                            excludeSemantics: true,
                            // Scrolls only if even the minimum size can't fit.
                            child: SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: box.maxHeight,
                                ),
                                child: message,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('officer-done'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Tapos na'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
