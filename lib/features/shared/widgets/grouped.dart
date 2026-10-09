import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

/// iOS "inset grouped" section: optional small header, a rounded card with
/// hairline separators between rows, optional footer.
class GroupedSection extends StatelessWidget {
  const GroupedSection({
    super.key,
    required this.children,
    this.header,
    this.headerTrailing,
    this.footer,
    this.margin = const EdgeInsets.only(top: 22),
    this.separatorIndent = 16,
  });

  final List<Widget> children;
  final String? header;

  /// Small widget at the right end of the header (e.g. a counter).
  final Widget? headerTrailing;
  final String? footer;
  final EdgeInsetsGeometry margin;

  /// Left inset of the separators (align with row text).
  final double separatorIndent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      header!.toUpperCase(),
                      style: context.text.labelMedium?.copyWith(
                        color: context.palette.muted,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  ?headerTrailing,
                ],
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radius),
              boxShadow: context.palette.cardShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radius),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, child) in children.indexed) ...[
                      if (i > 0) Divider(indent: separatorIndent),
                      child,
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: Text(footer!, style: context.text.bodySmall),
            ),
        ],
      ),
    );
  }
}

/// Settings-style colored icon square.
class IconSquare extends StatelessWidget {
  const IconSquare(this.icon, {super.key, required this.color, this.size = 34});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSizes.radiusIcon),
      ),
      child: Icon(icon, size: size * 0.62, color: onColor),
    );
  }
}

/// One row in a [GroupedSection]: leading, title/subtitle, trailing,
/// chevron when tappable.
class GroupedTile extends StatelessWidget {
  const GroupedTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.tapKey,
    this.chevron,
    this.titleStyle,
    this.minHeight = 60,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Key? tapKey;

  /// Defaults to true when [onTap] is set.
  final bool? chevron;
  final TextStyle? titleStyle;
  final double minHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final showChevron = chevron ?? onTap != null;
    return InkWell(
      key: tapKey,
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 14)],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: titleStyle ?? context.text.titleMedium),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle!, style: context.text.bodySmall),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
              if (showChevron) ...[
                const SizedBox(width: 6),
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 20,
                  color: context.palette.muted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Centers content at a readable width on tablets.
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = AppSizes.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    // heightFactor 1: only as tall as the child (so it also works inside
    // bottom bars); a Column child still fills a bounded parent.
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// iOS large title (+ optional subtitle) at the top of a tab screen.
class LargeTitle extends StatelessWidget {
  const LargeTitle(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.displaySmall),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle!,
                style: context.text.titleMedium?.copyWith(
                  color: context.palette.muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Cupertino action sheet for confirmations. Returns true if confirmed.
Future<bool> confirmWithSheet(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  bool destructive = true,
}) async {
  HapticFeedback.mediumImpact();
  final ok = await showCupertinoModalPopup<bool>(
    context: context,
    builder: (sheet) => CupertinoActionSheet(
      title: Text(title),
      message: message == null ? null : Text(message),
      actions: [
        CupertinoActionSheetAction(
          key: const Key('sheet-confirm'),
          isDestructiveAction: destructive,
          onPressed: () => Navigator.of(sheet).pop(true),
          child: Text(confirmLabel),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        key: const Key('sheet-cancel'),
        onPressed: () => Navigator.of(sheet).pop(false),
        child: const Text('Kanselahin'),
      ),
    ),
  );
  return ok ?? false;
}
