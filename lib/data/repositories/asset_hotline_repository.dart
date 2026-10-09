import 'dart:convert';

import '../../core/contracts/contracts.dart';

/// Hotlines from assets/data/hotlines.json (small, kept in memory).
class AssetHotlineRepository implements HotlineRepository {
  AssetHotlineRepository(this._hotlines);

  factory AssetHotlineRepository.fromJson(String json) =>
      AssetHotlineRepository(
        (jsonDecode(json) as List<dynamic>)
            .map((e) => Hotline.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  final List<Hotline> _hotlines;

  /// Zone-specific hotlines first, then nationwide (zone == null).
  @override
  Future<List<Hotline>> forZone(String? zone) async {
    final z = zone?.trim().toLowerCase();
    final local = z == null || z.isEmpty
        ? const <Hotline>[]
        : _hotlines.where((h) => h.zone?.toLowerCase() == z);
    final nationwide = _hotlines.where((h) => h.zone == null);
    return [...local, ...nationwide];
  }
}
