import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/di/providers.dart';

/// Step 1 answer. Lives as long as the Na-flag screen, so going back from a
/// result keeps it.
final selectedAgencyProvider = StateProvider.autoDispose<Agency?>(
  (ref) => null,
);

/// Step 2 search text.
final violationQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// How many violations to show when the query is empty.
const commonViolationsLimit = 8;

final violationResultsProvider = FutureProvider.autoDispose<List<Fine>>((
  ref,
) async {
  final agency = ref.watch(selectedAgencyProvider);
  if (agency == null) return const [];
  final query = ref.watch(violationQueryProvider).trim();
  final results = await ref
      .watch(finesRepositoryProvider)
      .search(query, agency);
  return query.isEmpty
      ? results.take(commonViolationsLimit).toList(growable: false)
      : results;
});

extension AgencyLabels on Agency {
  String get label => switch (this) {
    Agency.lto => 'LTO',
    Agency.mmda => 'MMDA',
    Agency.city => 'City enforcer',
  };

  String get description => switch (this) {
    Agency.lto => 'Land Transportation Office',
    Agency.mmda => 'Metro Manila Development Authority',
    Agency.city => 'Traffic enforcer ng city / munisipyo',
  };

  /// For sentences: "Na-flag ako ng `inSentence`".
  String get inSentence => switch (this) {
    Agency.lto => 'LTO',
    Agency.mmda => 'MMDA',
    Agency.city => 'city enforcer',
  };
}

/// ₱1,000 · ₱12,500 · ₱1,500.50
String formatPeso(num amount) {
  final parts = amount.toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return parts[1] == '00' ? '₱$whole' : '₱$whole.${parts[1]}';
}

String officerMessage(Fine fine) =>
    'Magandang araw po. Ayon sa ${fine.legalBasis}, ang multa sa '
    '${fine.violation} ay ${formatPeso(fine.amount)}. Maaari po bang '
    'mabigyan ng official ticket? Salamat po.';

String unknownViolationQuestion(Agency agency) =>
    'Na-flag ako ng ${agency.inSentence}, ano ang posibleng violation?';
