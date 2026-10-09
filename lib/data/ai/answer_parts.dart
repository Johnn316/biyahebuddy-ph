import '../../core/contracts/contracts.dart';

/// The parts of a Buddy answer that are written by code, not the LLM:
/// headers, the calm opener, the cited law, the steps, and fallbacks.
/// Headers match CLAUDE.md "AI answer-format rules" (the chat UI parses them).
abstract final class AnswerParts {
  static const kalmaHeader = '**Kalma muna**';
  static const batasHeader = '**Ano ang sinasabi ng batas**';
  static const pagsusuriHeader = '**Pagsusuri**';
  static const gagawinHeader = '**Ano ang gagawin**';

  static const _injuryWords = [
    'nasaktan', 'sugatan', 'sugat', 'dugo', 'duguan', 'injured', 'injury',
    'hurt', 'bleeding', 'patay', 'namatay', 'nahimatay', 'walang malay',
    'ospital', 'hospital', 'bali', 'nasagasaan', 'masakit',
  ];

  static const _fineWords = [
    'multa', 'magkano', 'fine', 'penalty', 'parusa', 'huli', 'nahuli',
    'flag', 'na-flag', 'naflag', 'tiket', 'ticket', 'tinikitan', 'violation',
  ];

  static const _accidentWords = [
    'bangga', 'nabangga', 'nagkabanggaan', 'banggaan', 'aksidente',
    'accident', 'sumalpok', 'nasagi', 'gasgas', 'collision',
  ];

  static bool _has(String text, List<String> words) {
    final t = text.toLowerCase();
    return words.any(t.contains);
  }

  static bool mentionsInjury(String text) => _has(text, _injuryWords);
  static bool asksAboutFine(String text) => _has(text, _fineWords);
  static bool mentionsAccident(String text) => _has(text, _accidentWords);

  static String kalma({required bool injury, bool twoSides = false}) {
    final open = twoSides
        ? 'Huminga muna nang malalim. Titingnan natin ang dalawang panig '
              'nang patas.'
        : 'Kalma lang, nandito ako. Tingnan natin ang sinasabi ng batas.';
    final safety = injury || twoSides
        ? '\nKung may nasaktan, tumawag agad sa 911.'
        : '';
    return '$kalmaHeader\n$open$safety\n\n';
  }

  /// "RA 10054 (Motorcycle Helmet Act of 2009)" + "Sec. 7" → "RA 10054 Sec. 7".
  static String citation(LawChunk c) =>
      '${c.source.split(' (').first.trim()} ${c.section}'.trim();

  /// "RA 10054 (Motorcycle Helmet Act of 2009)" → "Motorcycle Helmet Act of 2009".
  static String? actName(LawChunk c) =>
      RegExp(r'\(([^)]+)\)').firstMatch(c.source)?.group(1);

  static String excerpt(String text, int maxChars) {
    final t = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length <= maxChars) return t;
    final cut = t.lastIndexOf(' ', maxChars);
    return '${t.substring(0, cut > maxChars ~/ 2 ? cut : maxChars)}…';
  }

  static String peso(num amount) {
    final whole = amount.round().toString();
    final grouped = whole.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '₱$grouped';
  }

  /// The law section, built only from retrieved rows, verbatim with citation.
  static String batas(List<LawChunk> laws, List<Fine> fines) {
    final b = StringBuffer('$batasHeader\n');
    if (laws.isEmpty && fines.isEmpty) {
      b.write(
        'Walang malinaw na batas para dito sa offline na datos ni Buddy.\n\n',
      );
      return '$b';
    }
    for (final c in laws) {
      final act = actName(c);
      b.write('• ${citation(c)} — ${c.title}${act == null ? '' : ' ($act)'}\n');
      b.write('  "${excerpt(c.text, 350)}"\n');
    }
    for (final f in fines) {
      b.write(
        '• Multa (${f.agency.name.toUpperCase()}): ${peso(f.amount)} — '
        '${f.violation}. Batayan: ${f.legalBasis}\n',
      );
    }
    b.write('\n');
    return '$b';
  }

  /// Law + fines as compact context for the LLM prompt. Kept short: on a
  /// phone CPU, reading the prompt is most of the wait.
  static String llmContext(List<LawChunk> laws, List<Fine> fines) {
    final b = StringBuffer();
    for (final c in laws) {
      b.writeln('[${citation(c)} — ${c.title}] ${excerpt(c.text, 400)}');
    }
    for (final f in fines) {
      b.writeln(
        '[${f.legalBasis}] ${f.violation}: multa ${peso(f.amount)} '
        '(${f.agency.name.toUpperCase()})',
      );
    }
    return '$b'.trim();
  }

  static const noMatchAnalysis =
      'Wala akong nakitang batas sa offline na datos na tumutugma sa tanong '
      'mo, kaya hindi ako manghuhula tungkol sa batas o multa.\n\n';

  static const modelMissingAnalysis =
      'Hindi pa handa ang offline AI ni Buddy (i-download muna ang AI model), '
      'kaya ito muna ang mga batas na pinakamalapit sa tanong mo. Basahin '
      'ang mga ito at itugma sa nangyari.\n\n';

  static const emptyAnalysis =
      'Basahin ang batas sa itaas at itugma sa nangyari sa iyo.\n';

  static const modelFailedNote =
      '\n(Hindi natapos ang pagsusuri ng AI. Basahin ang batas sa itaas.)\n';

  /// Concrete, safe next steps, chosen by the kind of situation.
  static String gagawin({
    bool injury = false,
    bool aboutFine = false,
    bool accident = false,
    bool twoSides = false,
  }) {
    final steps = [
      if (injury || twoSides || accident)
        'Kung may nasaktan, tumawag agad sa 911.',
      if (twoSides || accident) ...[
        'Kunan ng litrato ang mga sasakyan, plaka, at lugar bago galawin.',
        'Magpalitan ng pangalan, lisensya, at insurance.',
        'I-report sa traffic enforcer o pulis para sa opisyal na ulat.',
      ] else if (aboutFine) ...[
        'Manatiling kalmado at magalang sa enforcer.',
        'Itala ang pangalan at ID ng enforcer, oras, at lugar.',
        'Bayaran o i-contest ang tiket sa tamang opisina (LTO, MMDA, o '
            'city hall) sa takdang araw.',
      ] else ...[
        'Sundin ang batas sa itaas habang nagmamaneho.',
        'Kung hindi sigurado, magtanong sa LTO o sa traffic enforcer.',
      ],
    ];
    final list = [
      for (var i = 0; i < steps.length; i++) '${i + 1}. ${steps[i]}',
    ];
    return '$gagawinHeader\n${list.join('\n')}\n';
  }

  static const _rules =
      'Ikaw si Buddy, kalmadong gabay ng mga Pilipinong driver. Sumagot sa '
      'Taglish, maiikling pangungusap. Gamitin LAMANG ang batas na ibinigay; '
      'huwag mag-imbento ng batas, section, o halaga. Kung babanggit ng '
      'citation, kopyahin ito nang eksakto mula sa BATAS sa ibaba. Hindi ito '
      'legal advice.';

  static const askSystem =
      '$_rules\nIsulat LAMANG ang pagsusuri: 2-3 pangungusap kung paano '
      'tumatama ang batas sa tanong ng driver. Huwag ulitin ang mga halaga '
      'ng multa (nakasulat na sa itaas). Walang listahan, walang ibang '
      'heading.';

  static final _faultWords = RegExp(
    r'kasalanan|may\s+sala|nagkamali|nagkakamali|mali\s+(?:si|ang)|may\s+mali'
    r'|at\s+fault|guilty|liable|dapat\s+sisihin|siya\s+ang\s+mali',
    caseSensitive: false,
  );

  // Sentence ends, but not "Sec. 41" / "No. 5".
  static final _sentenceBreak = RegExp(
    r'(?<=[.!?])(?<!\bSec\.)(?<!\bNo\.)(?<!\bBlg\.)\s+',
    caseSensitive: false,
  );

  /// Removes sentences that assign fault (two-sides must stay neutral).
  static String dropFaultSentences(String text) {
    final kept = <String>[];
    for (final line in text.split('\n')) {
      final sentences = line
          .split(_sentenceBreak)
          .where((s) => s.trim().isNotEmpty && !_faultWords.hasMatch(s));
      if (sentences.isNotEmpty) kept.add(sentences.join(' '));
    }
    return kept.isEmpty ? '' : '${kept.join('\n')}\n';
  }

  static const neutralFallback =
      'Itugma ang mga batas sa itaas sa kuwento ng bawat driver. Ang pulis o '
      'korte ang magpapasya kung sino ang may pananagutan.\n';

  /// Code-written neutral frame before the two-sides analysis.
  static const twoSidesFrame =
      'Hindi ito pinal na hatol kung sino ang may sala. Ito ang tinitingnan '
      'ng batas sa kuwento ng bawat isa:\n';

  static const twoSidesSystem =
      '$_rules\nMaging patas sa Driver A at Driver B. Bawal sabihin na may '
      'mali, nagkamali, o may sala ang sinuman. Isulat LAMANG ang pagsusuri, '
      'dalawang pangungusap na ganito ang simula:\n'
      '"Kung totoo ang kuwento ni Driver A, ..." (anong batas ang tumatama)\n'
      '"Kung totoo ang kuwento ni Driver B, ..." (anong batas ang tumatama)\n'
      'Walang listahan, walang ibang heading.';

  static String askUser(String context, String question) =>
      'BATAS:\n$context\n\nTANONG: $question';

  static String twoSidesUser(String context, String a, String b) =>
      'BATAS:\n$context\n\nDRIVER A: $a\nDRIVER B: $b';
}
