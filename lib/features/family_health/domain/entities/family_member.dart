import '../reference/reference_range.dart';

class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    required this.initials,
    required this.colorValue,
    required this.age,
    this.sex,
  });

  final String id;
  final String name;
  final String relation;
  final String initials;
  final int colorValue;
  final int age;

  /// Needed for sex-specific usual ranges (haemoglobin, creatinine, ferritin…).
  /// Unknown → those ranges aren't applied, rather than guessing.
  final Sex? sex;

  static String initialsOf(String name) {
    final words = _words(name);
    final initials = [for (final w in words.take(2)) w[0]].join();
    final trimmed = name.trim();
    return (initials.isNotEmpty || trimmed.isEmpty
            ? initials
            : String.fromCharCode(trimmed.runes.first))
        .toUpperCase();
  }

  /// Whether a patient name printed on a report could be this person. The
  /// first name must appear among the printed words (any order: some labs
  /// print the surname first); a shared surname alone isn't enough, since
  /// family members usually share one.
  // ponytail: exact word match; add edit-distance if OCR typos cause false
  // warnings.
  bool matchesPrintedName(String printed) {
    final words = _words(printed).where((w) => !_titles.contains(w)).toSet();
    final first = firstNameOf(name);
    return words.isEmpty || first == null || words.contains(first);
  }

  /// The word a report must contain to match this name (lowercase), or null.
  static String? firstNameOf(String name) =>
      _words(name).where((w) => !_titles.contains(w)).firstOrNull;

  /// "Dad", "Amma", "Me"… : what family call someone, never what labs print.
  static bool looksLikeNickname(String name) {
    final first = firstNameOf(name);
    return first != null && _nicknames.contains(first);
  }

  static const _nicknames = {
    'dad',
    'daddy',
    'papa',
    'pappa',
    'pa',
    'father',
    'mom',
    'mommy',
    'mum',
    'mummy',
    'mother',
    'ma',
    'maa',
    'amma',
    'appa',
    'nanna',
    'nana',
    'nani',
    'dadi',
    'dada',
    'baba',
    'bapu',
    'ammi',
    'abba',
    'grandpa',
    'grandma',
    'granny',
    'bro',
    'brother',
    'sis',
    'sister',
    'wife',
    'husband',
    'hubby',
    'son',
    'daughter',
    'me',
    'myself',
    'self',
    'beta',
    'beti',
    'chotu',
    'munna',
    'munni',
    'pinky',
    'bunty'
  };

  static List<String> _words(String text) => RegExp(r'\p{L}{2,}', unicode: true)
      .allMatches(text.toLowerCase())
      .map((m) => m[0]!)
      .toList();

  static const _titles = {
    'mr',
    'mrs',
    'ms',
    'miss',
    'master',
    'mast',
    'baby',
    'dr',
    'smt',
    'shri',
    'sri',
    'kumari',
    'kum',
    'mstr',
    'md',
    'late',
    'patient',
    'name'
  };
}
