import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

/// One law section from `assets/data/laws.json` (parts joined in order).
typedef LawSection = ({
  String source,
  String section,
  String title,
  String text,
  String url,
});

/// laws.json keyed by base id, e.g. `ra4136-s42` (the `-p1`, `-p2` parts of
/// a long section are joined).
final lawSectionsProvider = FutureProvider<Map<String, LawSection>>((
  ref,
) async {
  // load + decode (not loadString: files > 50 KB go to an isolate).
  final bytes = await rootBundle.load('assets/data/laws.json');
  final list =
      jsonDecode(utf8.decode(bytes.buffer.asUint8List())) as List<dynamic>;
  final out = <String, LawSection>{};
  for (final e in list.cast<Map<String, dynamic>>()) {
    final id = (e['id'] as String).replaceFirst(RegExp(r'-p\d+$'), '');
    final prev = out[id];
    out[id] = (
      source: e['source'] as String,
      section: prev?.section ?? e['section'] as String,
      title: e['title'] as String,
      text: prev == null ? e['text'] as String : '${prev.text}\n\n${e['text']}',
      url: e['url'] as String,
    );
  }
  return out;
});

/// "RA 4136 Sec. 42" / "R.A. No. 10913, Section 4" → `ra4136-s42`.
/// null when the citation has no RA number + section (JAO, MMDA, …).
String? lawIdFor(String citation) {
  final m = RegExp(
    r'(?:R\.?\s?A\.?|Republic\s+Act)\s*(?:No\.?\s*)?(\d{3,5}),?\s*'
    r'(?:Sec\.?|Section)\s*(\d+)',
    caseSensitive: false,
  ).firstMatch(citation);
  return m == null ? null : 'ra${m[1]}-s${m[2]}';
}

/// Bottom sheet with the full text of the cited section (offline).
Future<void> showLawSheet(BuildContext context, String citation) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _LawSheet(citation: citation),
  );
}

class _LawSheet extends ConsumerWidget {
  const _LawSheet({required this.citation});

  final String citation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laws = ref.watch(lawSectionsProvider);
    final id = lawIdFor(citation);
    final law = id == null ? null : laws.valueOrNull?[id];
    final p = context.palette;

    return ConstrainedBox(
      key: const Key('law-sheet'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            0,
            AppSpace.lg,
            AppSpace.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpace.xs),
                    decoration: BoxDecoration(
                      color: p.cautionTint,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      CupertinoIcons.book_fill,
                      color: p.cautionText,
                      size: AppIcon.md,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      citation,
                      style: context.text.titleLarge?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              if (laws.isLoading)
                const Padding(
                  padding: EdgeInsets.all(AppSpace.lg),
                  child: Center(child: CupertinoActivityIndicator()),
                )
              else if (law == null)
                Text(
                  'Wala pa sa offline na listahan ang buong teksto nito. '
                  'Tingnan ang opisyal na kopya ng batas.',
                  style: context.text.bodyLarge?.copyWith(color: p.muted),
                )
              else ...[
                Text(
                  '${law.section} · ${law.title}',
                  style: context.text.titleMedium,
                ),
                const SizedBox(height: AppSpace.xxs),
                Text(law.source, style: context.text.bodySmall),
                const SizedBox(height: AppSpace.md),
                SelectableText(
                  law.text,
                  key: const Key('law-sheet-text'),
                  style: context.text.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: AppSpace.md),
                Text('Pinagmulan: ${law.url}', style: context.text.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
