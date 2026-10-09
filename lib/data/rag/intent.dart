/// What kind of question the driver is asking. Decided in code (fast,
/// predictable), used to steer retrieval. A question can have several.
enum Intent { fine, accident, enforcer, rightOfWay, general }

const _fine = [
  'multa',
  'magkano',
  'fine',
  'penalty',
  'parusa',
  'tiket',
  'ticket',
  'tinikitan',
  'babayaran',
  'bayad',
  'how much',
];

const _accident = [
  'bangga',
  'nabangga',
  'banggaan',
  'nagkabanggaan',
  'aksidente',
  'accident',
  'sumalpok',
  'nasagi',
  'sagi',
  'gasgas',
  'collision',
  'crash',
  'tumakas',
  'hit and run',
  'nasaktan',
  'sugatan',
];

const _enforcer = [
  'enforcer',
  'pulis',
  'police',
  'mmda',
  'lto',
  'hpg',
  'traffic aide',
  'checkpoint',
  'flag',
  'na-flag',
  'naflag',
  'hinuli',
  'nahuli',
  'huli',
  'kinumpiska',
  'confiscate',
  'breathalyzer',
  'drug test',
  'alcohol test',
  'pinahinto',
];

const _rightOfWay = [
  'right of way',
  'karapatan',
  'mauuna',
  'nauna',
  'intersection',
  'interseksyon',
  'rotonda',
  'overtake',
  'nag-overtake',
  'singit',
  'sumingit',
  'kumanan',
  'kumaliwa',
  'liko',
  'lumiko',
  'signal',
  'lane',
  'tumatawid',
  'tawiran',
  'pedestrian',
  'u-turn',
  'counterflow',
];

bool _has(String t, List<String> words) => words.any(t.contains);

/// Rule-based intent router.
Set<Intent> classifyIntent(String question) {
  final t = question.toLowerCase();
  final out = <Intent>{
    if (_has(t, _fine)) Intent.fine,
    if (_has(t, _accident)) Intent.accident,
    if (_has(t, _enforcer)) Intent.enforcer,
    if (_has(t, _rightOfWay)) Intent.rightOfWay,
  };
  return out.isEmpty ? {Intent.general} : out;
}

/// Law sections each intent leans toward (RA 4136 traffic rules etc.).
/// A prior, not a filter: fused scores of these get a modest boost.
const intentSections = <Intent, Set<String>>{
  Intent.accident: {
    'ra4136-s55',
    'ra4136-s42',
    'ra4136-s43',
    'ra4136-s44',
    'ra4136-s45',
    'ra4136-s48',
    'ra4136-s35',
    'ra4136-s37',
    'ra4136-s39',
    'ra4136-s41',
    'ra10586-s7',
  },
  Intent.rightOfWay: {
    'ra4136-s37',
    'ra4136-s39',
    'ra4136-s40',
    'ra4136-s41',
    'ra4136-s42',
    'ra4136-s43',
    'ra4136-s44',
    'ra4136-s45',
    'ra4136-s49',
  },
  Intent.enforcer: {
    'ra4136-s24',
    'ra4136-s27',
    'ra4136-s29',
    'ra10586-s6',
    'ra10586-s8',
    'ra10913-s10',
  },
};

/// The one section that always matters for a situation; always a retrieval
/// candidate (still has to win the fusion to be cited).
const intentAnchors = <Intent, List<String>>{
  Intent.accident: ['ra4136-s55'], // Duty of driver in case of accident
  Intent.rightOfWay: ['ra4136-s42'], // Right of way
};

/// "RA 10054 (Motorcycle Helmet Act of 2009), Sec. 7" → ["ra10054-s7"], so a
/// matched fine pulls in the law it cites. Only bases that START with an RA:
/// "Metro Manila Traffic Code …, Sec. 26 (RA 8750)" cites Sec. 26 of the
/// MMDA code, not of RA 8750, so it yields nothing.
List<String> lawIdsInLegalBasis(String basis) {
  final m = RegExp(
    r'^\s*R\.?\s?A\.?\s*(?:No\.?\s*)?(\d{3,5})[^,;]*,\s*Sec(?:tion)?\.?\s*(\d+)',
    caseSensitive: false,
  ).firstMatch(basis);
  return m == null ? const [] : ['ra${m.group(1)}-s${m.group(2)}'];
}
