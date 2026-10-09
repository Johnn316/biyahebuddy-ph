import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';

/// Citation chip, e.g. "RA 4136 Sec. 44" (docs/DESIGN.md §8 "Law pill"):
/// amber fill, dark text, book icon, tabular figures. Grows at most 1.4×.
class LawPill extends StatelessWidget {
  const LawPill(this.citation, {super.key});

  final String citation;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Batas: $citation',
      excludeSemantics: true,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.4,
        child: Container(
          constraints: const BoxConstraints(minHeight: 26),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: p.accent,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.book_fill, size: 14, color: p.onAccent),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  citation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelMedium?.copyWith(
                    color: p.onAccent,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
