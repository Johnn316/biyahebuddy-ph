import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/grouped.dart';
import '../controllers/violation_controller.dart';
import '../widgets/agency_picker.dart';
import '../widgets/violation_search_field.dart';
import 'fine_result_screen.dart';

/// "Na-flag ako" tab: 1) pick agency → 2) tap a violation → result.
/// Max 2 taps. Back from step 2 returns to step 1.
class ViolationScreen extends ConsumerStatefulWidget {
  const ViolationScreen({super.key});

  @override
  ConsumerState<ViolationScreen> createState() => _ViolationScreenState();
}

class _ViolationScreenState extends ConsumerState<ViolationScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _selectAgency(Agency? agency) {
    // Back to step 1 starts fresh (query state is disposed with step 2).
    if (agency == null) _search.clear();
    ref.read(selectedAgencyProvider.notifier).state = agency;
  }

  @override
  Widget build(BuildContext context) {
    final agency = ref.watch(selectedAgencyProvider);

    return PopScope(
      canPop: agency == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _selectAgency(null);
      },
      child: Scaffold(
        appBar: agency == null
            ? null
            : AppBar(
                leading: BackButton(onPressed: () => _selectAgency(null)),
                title: const Text('Na-flag ako'),
              ),
        body: SafeArea(
          top: agency == null,
          child: ContentWidth(
            child: agency == null
                ? AgencyPickerLarge(onSelected: _selectAgency)
                : _ViolationStep(agency: agency, search: _search),
          ),
        ),
      ),
    );
  }
}

class _ViolationStep extends ConsumerWidget {
  const _ViolationStep({required this.agency, required this.search});

  final Agency agency;
  final TextEditingController search;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(violationResultsProvider);
    final query = ref.watch(violationQueryProvider).trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AgencyPickerCompact(
            selected: agency,
            onSelected: (a) =>
                ref.read(selectedAgencyProvider.notifier).state = a,
          ),
          const SizedBox(height: 12),
          ViolationSearchField(controller: search),
          Expanded(
            child: results.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (_, _) => Center(
                child: Text(
                  'Hindi ma-load ang listahan.',
                  style: context.text.titleLarge,
                ),
              ),
              data: (fines) => fines.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Walang nahanap para sa "$query".\n'
                          'Subukan ang ibang salita o pindutin ang '
                          '"Hindi ko alam" sa ibaba.',
                          textAlign: TextAlign.center,
                          style: context.text.titleMedium?.copyWith(
                            color: context.palette.muted,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 12),
                      children: [
                        GroupedSection(
                          header: query.isEmpty
                              ? 'Karaniwang violation'
                              : 'Resulta',
                          margin: const EdgeInsets.only(top: 18),
                          children: [
                            for (final (i, f) in fines.indexed)
                              _FineTile(index: i, fine: f),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
          FilledButton.tonalIcon(
            key: const Key('unknown-violation'),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.surface,
              foregroundColor: context.colors.primary,
              textStyle: context.text.titleMedium,
            ),
            onPressed: () => context.go(
              Uri(
                path: Routes.chat,
                queryParameters: {'q': unknownViolationQuestion(agency)},
              ).toString(),
            ),
            icon: const Icon(CupertinoIcons.question_circle_fill),
            label: const Text('Hindi ko alam ang violation'),
          ),
        ],
      ),
    );
  }
}

class _FineTile extends StatelessWidget {
  const _FineTile({required this.index, required this.fine});

  final int index;
  final Fine fine;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GroupedTile(
      tapKey: Key('fine-$index'),
      title: fine.violation,
      onTap: () => FineResultScreen.open(context, fine),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: p.accent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          formatPeso(fine.amount),
          style: context.text.titleSmall?.copyWith(color: p.onAccent),
        ),
      ),
    );
  }
}
