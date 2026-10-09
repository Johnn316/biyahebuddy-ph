import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/app_card.dart';
import '../controllers/violation_controller.dart';
import '../widgets/agency_picker.dart';
import '../widgets/violation_search_field.dart';
import 'fine_result_screen.dart';

/// "Na-flag ako": 1) pick agency → 2) tap a violation → result. Max 2 taps.
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

  void _back() {
    if (ref.read(selectedAgencyProvider) != null) {
      _selectAgency(null); // step 2 → step 1
    } else {
      context.canPop() ? context.pop() : context.go(Routes.home);
    }
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
        appBar: AppBar(
          leading: BackButton(onPressed: _back),
          title: const Text('Na-flag ako'),
        ),
        body: SafeArea(
          top: false,
          child: agency == null
              ? AgencyPickerLarge(onSelected: _selectAgency)
              : _ViolationStep(agency: agency, search: _search),
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
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
          const SizedBox(height: 12),
          Text(
            query.isEmpty ? 'Karaniwang violation' : 'Resulta',
            style: text.titleMedium?.copyWith(color: context.palette.muted),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: results.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Text(
                  'Hindi ma-load ang listahan.',
                  style: text.titleLarge,
                ),
              ),
              data: (fines) => fines.isEmpty
                  ? Center(
                      child: Text(
                        'Walang nahanap para sa "$query".\n'
                        'Subukan ang ibang salita o pindutin ang '
                        '"Hindi ko alam" sa ibaba.',
                        textAlign: TextAlign.center,
                        style: text.titleLarge,
                      ),
                    )
                  : ListView.separated(
                      itemCount: fines.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) =>
                          _FineTile(index: i, fine: fines[i]),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('unknown-violation'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.primary,
              side: BorderSide(color: context.colors.primary, width: 2),
              textStyle: text.titleMedium,
            ),
            onPressed: () => context.push(
              Uri(
                path: Routes.chat,
                queryParameters: {'q': unknownViolationQuestion(agency)},
              ).toString(),
            ),
            icon: const Icon(Icons.help_outline_rounded),
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
    return AppCard(
      tapKey: Key('fine-$index'),
      shadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => FineResultScreen.open(context, fine),
      child: Row(
        children: [
          Expanded(
            child: Text(fine.violation, style: context.text.titleMedium),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: p.accent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              formatPeso(fine.amount),
              style: context.text.titleMedium?.copyWith(color: p.onAccent),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: p.muted),
        ],
      ),
    );
  }
}
