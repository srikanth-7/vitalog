import 'dart:typed_data';

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
    this.photo,
  });

  /// Soft avatar backgrounds, handed out in turn to new members (mint,
  /// blue, peach, lilac); initials sit on them in `onAvatar`.
  static const avatarTints = [0xFFD8EFE5, 0xFFDCE9FA, 0xFFF6E3D4, 0xFFEAE1F6];

  final String id;
  final String name;
  final String relation;
  final String initials;
  final int colorValue;
  final int age;

  /// Their picture, decrypted in memory for the avatar. Phone only: never
  /// in members.json or the sync row (the encrypted file lives apart).
  final Uint8List? photo;

  FamilyMember withPhoto(Uint8List? photo) => FamilyMember(
      id: id,
      name: name,
      relation: relation,
      initials: initials,
      colorValue: colorValue,
      age: age,
      sex: sex,
      photo: photo);

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
  /// print the surname first), as the word or its initial ("D.S. Simmons");
  /// a shared surname alone isn't enough, since family members usually
  /// share one.
  bool matchesPrintedName(String printed) {
    final tokens = _printedTokens(printed);
    final first = firstNameOf(name);
    return tokens.isEmpty ||
        first == null ||
        tokens.any((t) => _sameWord(t, first));
  }

  /// Another member whose name fits [printed] better than this one's, or
  /// null. Needed when first names are shared (a son and "Danial Senior"
  /// his dad both pass [matchesPrintedName]). Score = shared words / all
  /// words, so a missing or an extra word both count against a name.
  FamilyMember? betterMatchIn(Iterable<FamilyMember> family, String printed) {
    final tokens = _printedTokens(printed);
    if (tokens.isEmpty) return null;
    // Whole words claim their name word first, then initials take what's
    // left, so "D.S. Simmons" fits Danial Senior Simmons exactly.
    final ordered = [
      ...tokens.where((t) => t.length > 1),
      ...tokens.where((t) => t.length == 1)
    ];
    double score(FamilyMember m) {
      final left = [
        for (final w in _words(m.name))
          if (!_titles.contains(w)) _suffixes[w] ?? w
      ];
      if (left.isEmpty || !m.matchesPrintedName(printed)) return 0;
      final size = left.length;
      var hit = 0;
      for (final t in ordered) {
        final i = left.indexWhere((w) => _sameWord(t, w));
        if (i < 0) continue;
        left.removeAt(i);
        hit++;
      }
      return hit / (size + tokens.length - hit);
    }

    FamilyMember? best;
    var top = score(this);
    for (final m in family) {
      if (m.id == id) continue;
      final s = score(m);
      if (s > top) (best, top) = (m, s);
    }
    return best;
  }

  /// Printed name words, keeping single-letter initials ("D.S.").
  static List<String> _printedTokens(String text) => [
        for (final m
            in RegExp(r'\p{L}+', unicode: true).allMatches(text.toLowerCase()))
          if (!_titles.contains(m[0])) _suffixes[m[0]] ?? m[0]!
      ];

  /// An initial matches the word it starts; a longer word may carry one OCR
  /// slip ("Simmions"). Short names must match exactly: Ravi isn't Rani.
  static bool _sameWord(String printed, String word) {
    if (printed.length == 1) return word.startsWith(printed);
    if (printed == word) return true;
    return printed.length >= 5 && word.length >= 5 && _oneEdit(printed, word);
  }

  /// At most one inserted, deleted or changed letter.
  static bool _oneEdit(String a, String b) {
    if ((a.length - b.length).abs() > 1) return false;
    var i = 0, j = 0, edits = 0;
    while (i < a.length && j < b.length) {
      if (a[i] == b[j]) {
        i++;
        j++;
        continue;
      }
      if (++edits > 1) return false;
      if (a.length > b.length) {
        i++;
      } else if (b.length > a.length) {
        j++;
      } else {
        i++;
        j++;
      }
    }
    return edits + (a.length - i) + (b.length - j) <= 1;
  }

  /// How labs abbreviate the words that tell a father and son apart.
  static const _suffixes = {
    'sr': 'senior',
    'snr': 'senior',
    'jr': 'junior',
    'jnr': 'junior'
  };

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
