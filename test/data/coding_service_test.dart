import 'package:biyahebuddy_ph/data/coding/asset_coding_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _json = '''
{
  "scheme": "TEST",
  "hours": [{"start": "07:00", "end": "10:00"}, {"start": "17:00", "end": "20:00"}],
  "days": {"1": [1, 2], "2": [3, 4], "3": [5, 6], "4": [7, 8], "5": [9, 0]},
  "notes": "test"
}
''';

void main() {
  final coding = AssetCodingService.fromJson(_json);
  // 2026-10-05 is a Monday.
  DateTime mon(int h, [int m = 0]) => DateTime(2026, 10, 5, h, m);

  test('coded digit inside a window is coding', () {
    final s = coding.statusFor('NAB 1231', mon(8));
    expect(s.isCoding, isTrue);
    expect(s.message, 'CODING ka ngayon (7AM–10AM, 5PM–8PM)');
  });

  test('window start is inclusive, end is exclusive', () {
    expect(coding.statusFor('ABC 1232', mon(7)).isCoding, isTrue);
    expect(coding.statusFor('ABC 1232', mon(9, 59)).isCoding, isTrue);
    expect(coding.statusFor('ABC 1232', mon(10)).isCoding, isFalse);
    expect(coding.statusFor('ABC 1232', mon(17)).isCoding, isTrue);
  });

  test('coded digit outside the windows warns but is not coding', () {
    final s = coding.statusFor('NAB 1231', mon(12));
    expect(s.isCoding, isFalse);
    expect(s.message, startsWith('Coding day mo ngayon'));
  });

  test('other digit is not coding', () {
    final s = coding.statusFor('NAB 1235', mon(8));
    expect(s.isCoding, isFalse);
    expect(s.message, 'Hindi ka coding ngayon');
  });

  test('digit 0 is coded on Friday; weekends are free', () {
    expect(
      coding.statusFor('XYZ 990', DateTime(2026, 10, 9, 8)).isCoding,
      isTrue,
    );
    expect(
      coding.statusFor('XYZ 991', DateTime(2026, 10, 10, 8)).isCoding,
      isFalse,
    );
  });

  test('uses the last digit, ignoring letters and spaces', () {
    expect(coding.statusFor('12-34AB', mon(8)).isCoding, isFalse); // 4 = Tue
    expect(coding.statusFor('NAB 1232 ', mon(8)).isCoding, isTrue);
  });

  test('plate without digits', () {
    final s = coding.statusFor('ABC', mon(8));
    expect(s.isCoding, isFalse);
    expect(s.message, 'Walang plate number');
  });
}
