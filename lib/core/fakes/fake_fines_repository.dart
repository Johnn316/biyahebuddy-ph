import '../contracts/contracts.dart';

/// SAMPLE fines — amounts/legal bases must be verified (see docs/SOURCES.md).
class FakeFinesRepository implements FinesRepository {
  static const _fines = [
    Fine(
      violation: 'Driving without a valid license',
      agency: Agency.lto,
      amount: 3000,
      legalBasis: 'SAMPLE — LTO JAO 2014-01',
      aliases: ['walang lisensya', 'no license'],
    ),
    Fine(
      violation: 'Failure to wear seatbelt (driver, 1st offense)',
      agency: Agency.lto,
      amount: 1000,
      legalBasis: 'SAMPLE — RA 8750, Sec. 11',
      aliases: ['seatbelt', 'walang seatbelt'],
    ),
    Fine(
      violation: 'Using mobile phone while driving',
      agency: Agency.lto,
      amount: 5000,
      legalBasis: 'SAMPLE — RA 10913, Sec. 4',
      aliases: ['cellphone', 'texting', 'distracted driving'],
    ),
    Fine(
      violation: 'Disregarding traffic signs',
      agency: Agency.mmda,
      amount: 1000,
      legalBasis: 'SAMPLE — MMDA Regulation',
      aliases: ['beating the red light', 'no left turn', 'swerving'],
    ),
    Fine(
      violation: 'Number coding (UVVRP) violation',
      agency: Agency.mmda,
      amount: 300,
      legalBasis: 'SAMPLE — MMDA Reg. 96-005',
      aliases: ['coding', 'number coding'],
    ),
    Fine(
      violation: 'Illegal parking (attended)',
      agency: Agency.city,
      amount: 1000,
      legalBasis: 'SAMPLE — City ordinance',
      aliases: ['parking', 'bawal pumarada'],
    ),
  ];

  @override
  Future<List<Fine>> search(String query, Agency agency) async {
    final q = query.trim().toLowerCase();
    return _fines
        .where((f) => f.agency == agency)
        .where(
          (f) =>
              q.isEmpty ||
              f.violation.toLowerCase().contains(q) ||
              f.aliases.any((a) => a.toLowerCase().contains(q)),
        )
        .toList(growable: false);
  }
}
