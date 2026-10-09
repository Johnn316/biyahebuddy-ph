import '../contracts/contracts.dart';

/// SAMPLE MMDA UVVRP ("number coding") rule: last plate digit by weekday,
/// 7:00–10:00 AM and 5:00–8:00 PM. Real rules come from assets/data/coding.json.
class FakeCodingService implements CodingService {
  static const _digitsByWeekday = {
    DateTime.monday: [1, 2],
    DateTime.tuesday: [3, 4],
    DateTime.wednesday: [5, 6],
    DateTime.thursday: [7, 8],
    DateTime.friday: [9, 0],
  };

  @override
  CodingStatus statusFor(String plateNo, DateTime now) {
    final digits = plateNo.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const CodingStatus(
        isCoding: false,
        message: 'Walang plate number',
      );
    }
    final last = int.parse(digits[digits.length - 1]);
    final codingDigits = _digitsByWeekday[now.weekday];
    if (codingDigits == null || !codingDigits.contains(last)) {
      return const CodingStatus(
        isCoding: false,
        message: 'Hindi ka coding ngayon',
      );
    }
    final minutes = now.hour * 60 + now.minute;
    final inWindow =
        (minutes >= 7 * 60 && minutes < 10 * 60) ||
        (minutes >= 17 * 60 && minutes < 20 * 60);
    return CodingStatus(
      isCoding: inWindow,
      message: inWindow
          ? 'CODING ka ngayon (7–10AM, 5–8PM)'
          : 'Coding day mo ngayon — iwas 7–10AM at 5–8PM',
    );
  }
}
