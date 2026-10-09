import '../contracts/contracts.dart';

/// Streams a canned answer in the required format:
/// Kalma muna → Batas (with citation) → Pagsusuri → Gagawin.
class FakeAiAssistant implements AiAssistant {
  @override
  Stream<String> ask(String question) => _stream(
    '**Kalma muna.** Huminga nang malalim — nandito ako para tumulong.\n\n'
    '**Batas:** [SAMPLE] Dapat magmaneho nang may ingat at sa ligtas na '
    'bilis. (RA 4136, Sec. 35)\n\n'
    '**Pagsusuri:** Tungkol sa tanong mo: "$question" — sample na sagot '
    'ito mula sa fake assistant.\n\n'
    '**Gagawin:**\n1. Itabi ang sasakyan kung ligtas.\n'
    '2. Hingin ang pangalan at ID ng enforcer.\n'
    '3. Itala ang oras at lugar.',
  );

  @override
  Stream<String> analyzeTwoSides(String driverA, String driverB) => _stream(
    '**Kalma muna.** Mag-usap tayo nang mahinahon.\n\n'
    '**Batas:** [SAMPLE] Right of way sa intersection. (RA 4136, Sec. 42)\n\n'
    '**Pagsusuri:**\n- Driver A: $driverA\n- Driver B: $driverB\n'
    'Sample na pagsusuri lamang ito.\n\n'
    '**Gagawin:**\n1. Kunan ng litrato ang mga sasakyan at lugar.\n'
    '2. Magpalitan ng impormasyon at insurance.\n'
    '3. Tumawag sa 911 kung may nasaktan.',
  );

  Stream<String> _stream(String text) async* {
    for (final word in text.split(' ')) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
      yield '$word ';
    }
  }
}
