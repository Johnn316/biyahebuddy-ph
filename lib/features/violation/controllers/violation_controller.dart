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

/// Empty query → every fine of the agency; otherwise the search results
/// (best first).
final violationResultsProvider = FutureProvider.autoDispose<List<Fine>>((
  ref,
) async {
  final agency = ref.watch(selectedAgencyProvider);
  if (agency == null) return const [];
  final query = ref.watch(violationQueryProvider).trim();
  return ref.watch(finesRepositoryProvider).search(query, agency);
});

/// How many violations each agency has (agency picker).
final agencyCountProvider = FutureProvider.autoDispose.family<int, Agency>(
  (ref, agency) async =>
      (await ref.watch(finesRepositoryProvider).search('', agency)).length,
);

/// Groups for the full list (empty search), in display order.
enum FineCategory {
  license('Lisensya & Rehistro'),
  safety('Helmet & Seatbelt'),
  signs('Signs & Signals'),
  parking('Parking & Obstruction'),
  distracted('Distracted / Drunk'),
  coding('Coding & Truck ban'),
  other('Iba pa');

  const FineCategory(this.label);

  final String label;
}

/// Category of [fine] from its violation name and aliases.
FineCategory fineCategory(Fine fine) {
  final t = [fine.violation, ...fine.aliases].join(' ').toLowerCase();
  bool has(List<String> words) => words.any(t.contains);
  if (has(['distracted', 'mobile phone', 'cellphone', 'influence', 'drunk'])) {
    return FineCategory.distracted;
  }
  if (has(['license', 'lisensya', 'permit', 'registration', 'plate'])) {
    return FineCategory.license;
  }
  if (has(['helmet', 'seatbelt', 'seat belt', 'child', 'dress code'])) {
    return FineCategory.safety;
  }
  if (has(['coding', 'uvvrp', 'truck ban', 'tricycle ban'])) {
    return FineCategory.coding;
  }
  if (has(['parking', 'obstruction', 'loading', 'unloading'])) {
    return FineCategory.parking;
  }
  if (has([
    'traffic sign',
    'red light',
    'signal',
    'counterflow',
    'overspeeding',
    'reckless',
    'swerving',
  ])) {
    return FineCategory.signs;
  }
  return FineCategory.other;
}

/// [fines] grouped by [FineCategory] (empty groups left out), keeping the
/// original order inside each group.
List<(FineCategory, List<Fine>)> groupFines(List<Fine> fines) => [
  for (final c in FineCategory.values)
    if (fines.where((f) => fineCategory(f) == c).toList() case final list
        when list.isNotEmpty)
      (c, list),
];

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
