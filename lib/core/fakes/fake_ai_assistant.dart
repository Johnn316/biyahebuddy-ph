import '../contracts/contracts.dart';

/// Streams canned Taglish answers, word by word, in the 4-section format the
/// chat UI renders (see CLAUDE.md "AI answer-format rules"):
///
///   **Kalma muna** → **Ano ang sinasabi ng batas** (with citation)
///   → **Pagsusuri** → **Ano ang gagawin**
///
/// Picks a canned answer by keyword so different questions look different.
/// SAMPLE content: citations point at real laws but are not legal advice.
class FakeAiAssistant implements AiAssistant {
  FakeAiAssistant({this.tokenDelay = const Duration(milliseconds: 35)});

  /// Delay between streamed words.
  final Duration tokenDelay;

  @override
  Stream<String> ask(String question) {
    final q = question.toLowerCase();
    if (q.contains('bangga') || q.contains('aksidente') || q.contains('mali')) {
      return _stream(_accident);
    }
    if (q.contains('cellphone') ||
        q.contains('phone') ||
        q.contains('text') ||
        q.contains('waze')) {
      return _stream(_phone);
    }
    if (q.contains('flag') || q.contains('multa') || q.contains('magkano')) {
      return _stream(_flagged);
    }
    return _stream(_general);
  }

  @override
  Stream<String> analyzeTwoSides(String driverA, String driverB) => _stream(
    '**Kalma muna**\n'
    'Normal na magkaiba ang kuwento ng dalawang panig. Huwag munang '
    'magtalo — tingnan natin ang batas.\n\n'
    '**Ano ang sinasabi ng batas**\n'
    'Sa intersection na walang traffic light, ang sasakyang naunang '
    'pumasok ang may right of way. Kung sabay, ang nasa kanan ang '
    'pagbibigyan (RA 4136 Sec. 42). Bawal din ang biglang pag-overtake '
    'sa intersection (RA 4136 Sec. 41).\n\n'
    '**Pagsusuri**\n'
    'Panig mo: "$driverA"\n'
    'Kabilang driver: "$driverB"\n'
    'Kung totoo na ikaw ang naunang pumasok sa intersection, mas malakas '
    'ang panig mo. Pero kung ang kabila ay nasa kanan at sabay kayo, '
    'maaaring siya ang may right of way. Ang dashcam, CCTV, at testigo ang '
    'magpapasya nito.\n\n'
    '**Ano ang gagawin**\n'
    '1. Kunan ng litrato ang posisyon ng mga sasakyan bago galawin.\n'
    '2. Hanapin ang CCTV o dashcam footage sa lugar.\n'
    '3. Kumuha ng pangalan at number ng mga testigo.\n'
    '4. Huwag pumirma ng anumang pag-amin; hintayin ang police report.',
  );

  static const _accident =
      '**Kalma muna**\n'
      'Una, siguraduhin na walang nasaktan. Kung may sugatan, tumawag agad '
      'sa 911.\n\n'
      '**Ano ang sinasabi ng batas**\n'
      'Ang driver na nasangkot sa aksidente ay dapat huminto, tumulong sa '
      'nasaktan, at mag-report sa pulis (RA 4136 Sec. 55). Ang may right '
      'of way sa intersection ay ang naunang pumasok (RA 4136 Sec. 42).\n\n'
      '**Pagsusuri**\n'
      'Hindi pa masasabi kung sino ang may mali nang walang detalye. '
      'Karaniwang tinitingnan kung sino ang may right of way, ang bilis ng '
      'bawat sasakyan, at kung may lumabag sa traffic sign.\n\n'
      '**Ano ang gagawin**\n'
      '1. I-on ang hazard lights at ilagay ang early warning device.\n'
      '2. Kunan ng litrato ang eksena at plates BAGO galawin ang sasakyan.\n'
      '3. Magpalitan ng lisensya, plate no., at insurance.\n'
      '4. Huwag umamin ng kasalanan on the spot. Kumuha ng police report.';

  static const _phone =
      '**Kalma muna**\n'
      'Magandang tanong ito — madalas itong ma-flag.\n\n'
      '**Ano ang sinasabi ng batas**\n'
      'Bawal gumamit ng cellphone para tumawag, mag-text, o mag-browse '
      'habang nagmamaneho, kahit naka-stop sa red light (RA 10913 Sec. 4). '
      'Pwede ang hands-free basta hindi nakaharang sa paningin.\n\n'
      '**Pagsusuri**\n'
      'Kung nakalagay ang phone sa mount na hindi lalampas sa dashboard '
      'line at gamit mo lang ang navigation nang hindi hinahawakan, '
      'karaniwang hindi ito violation.\n\n'
      '**Ano ang gagawin**\n'
      '1. Gumamit ng phone mount na mababa sa dashboard line.\n'
      '2. I-set ang Waze o maps bago umandar.\n'
      '3. Kung kailangang tumawag, tumabi muna sa ligtas na lugar.';

  static const _flagged =
      '**Kalma muna**\n'
      'Huminga nang malalim. Maging magalang sa enforcer — mas mabilis '
      'matatapos ito.\n\n'
      '**Ano ang sinasabi ng batas**\n'
      'Ang multa ay dapat nakasulat sa official ticket o Temporary '
      "Operator's Permit, at binabayaran sa opisina o accredited na "
      'payment center — hindi sa kalsada (LTO JAO 2014-01). Para sa '
      'MMDA, may sariling schedule ng multa (MMDA Reg. 96-005).\n\n'
      '**Pagsusuri**\n'
      'Kung hindi malinaw ang violation, may karapatan kang magtanong '
      'kung ano ito at anong batas ang nilabag.\n\n'
      '**Ano ang gagawin**\n'
      '1. Itabi ang sasakyan sa ligtas na lugar at i-on ang hazard.\n'
      '2. Itanong nang mahinahon ang violation at legal basis.\n'
      '3. Humingi ng official ticket. Huwag magbayad on the spot nang '
      'walang resibo.';

  static const _general =
      '**Kalma muna**\n'
      'Nandito ako para tumulong, kahit walang signal.\n\n'
      '**Ano ang sinasabi ng batas**\n'
      'Dapat magmaneho sa ligtas at makatwirang bilis ayon sa kondisyon '
      'ng kalsada at trapiko (RA 4136 Sec. 35).\n\n'
      '**Pagsusuri**\n'
      'Para mas tiyak ang sagot, sabihin kung saan ito nangyari (lungsod o '
      'highway) at sino ang enforcer (LTO, MMDA, o city).\n\n'
      '**Ano ang gagawin**\n'
      '1. Ibigay ang buong detalye ng sitwasyon.\n'
      '2. Kung na-flag ka, gamitin ang "Na-flag ako" sa Home.';

  Stream<String> _stream(String text) async* {
    final words = text.split(' ');
    for (var i = 0; i < words.length; i++) {
      await Future<void>.delayed(tokenDelay);
      yield i == words.length - 1 ? words[i] : '${words[i]} ';
    }
  }
}
