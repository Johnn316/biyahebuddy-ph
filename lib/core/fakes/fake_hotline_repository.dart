import '../contracts/contracts.dart';

/// SAMPLE hotlines — verify every number (see docs/SOURCES.md).
class FakeHotlineRepository implements HotlineRepository {
  static const _hotlines = [
    Hotline(name: 'National Emergency Hotline', number: '911'),
    Hotline(name: 'Philippine Red Cross', number: '143'),
    Hotline(name: 'MMDA Metrobase', number: '136', zone: 'NCR'),
    Hotline(name: 'NLEX Hotline', number: '1-35000', zone: 'NLEX'),
  ];

  @override
  Future<List<Hotline>> forZone(String? zone) async => _hotlines
      .where((h) => h.zone == null || (zone != null && h.zone == zone))
      .toList(growable: false);
}
