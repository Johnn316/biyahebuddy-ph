import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import 'pressable.dart';

/// Quick-action tile for the Home grid (docs/DESIGN.md §8 "Action tile").
/// Regular: tinted icon square on top, title, one-line subtitle.
/// Compact (short screens): icon + title in one row.
/// The whole tile is one button: press scale 0.97 + light haptic.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.subtitle,
    this.compact = false,
    this.tapKey,
    this.semanticsLabel,
    this.width,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool compact;

  /// Key on the tappable surface (tests and deep links).
  final Key? tapKey;

  /// Full name for screen readers when [title] is a short label.
  final String? semanticsLabel;

  /// Tile width, if known — used to decide whether the subtitle fits.
  /// (No LayoutBuilder: tiles sit in IntrinsicHeight rows.) null = no
  /// subtitle.
  final double? width;

  /// Whether [subtitle] fits on one line in a tile of [tileWidth].
  static bool subtitleFits(
    BuildContext context,
    String subtitle,
    double tileWidth, {
    required bool compact,
  }) {
    final textWidth =
        tileWidth - 2 * (AppSpace.sm + 2) - (compact ? 36 + AppSpace.sm : 0);
    final painter = TextPainter(
      text: TextSpan(text: subtitle, style: _subtitleStyle(context)),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: textWidth);
    final fits = !painter.didExceedMaxLines;
    painter.dispose();
    return fits;
  }

  static TextStyle? _subtitleStyle(BuildContext context) => context
      .text
      .labelSmall
      ?.copyWith(color: context.palette.muted, fontSize: 13);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(AppRadius.lg);
    final iconSquare = Container(
      width: compact ? 36 : 44,
      height: compact ? 36 : 44,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, size: compact ? 20 : 24, color: iconColor),
    );
    // Short labels never truncate: at extreme font sizes they shrink.
    final titleText = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(title, maxLines: 1, style: context.text.titleMedium),
    );
    // width != null means the grid checked that every subtitle fits.
    final sub = subtitle == null || width == null
        ? null
        : Text(subtitle!, maxLines: 1, style: _subtitleStyle(context));
    Widget texts() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [titleText, ?sub],
    );

    return Semantics(
      button: true,
      label: [semanticsLabel ?? title, ?subtitle].join('. '),
      excludeSemantics: true,
      child: Pressable(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: radius,
            boxShadow: p.cardShadow,
            border: Border(top: BorderSide(color: p.highlight, width: 0.5)),
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: tapKey,
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.sm + 2),
                child: compact
                    ? Row(
                        children: [
                          iconSquare,
                          const SizedBox(width: AppSpace.sm),
                          Expanded(child: texts()),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          iconSquare,
                          const SizedBox(height: AppSpace.sm),
                          texts(),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
