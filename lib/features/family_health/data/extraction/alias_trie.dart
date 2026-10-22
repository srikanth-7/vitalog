import 'lab_test_catalog.dart';

/// A test-name match in a report row: which test, and where its name sits.
class AliasHit {
  const AliasHit(this.definition, this.alias, this.start, this.end);
  final LabTestDefinition definition;
  final String alias;
  final int start;
  final int end;
  int get length => end - start;
}

/// Prefix tree over every catalog alias (≈300), so a row is matched in one
/// pass instead of one regex per alias: O(row length × longest alias)
/// rather than O(aliases × row length).
class AliasTrie {
  AliasTrie(List<LabTestDefinition> catalog) {
    for (final (index, definition) in catalog.indexed) {
      for (final alias in definition.aliases) {
        var node = _root;
        for (final unit in alias.codeUnits) {
          node = node.next.putIfAbsent(unit, _Node.new);
        }
        // First definition wins a shared alias, as catalog order did before.
        node.end ??= (index, definition, alias);
      }
    }
  }

  final _root = _Node();

  /// The longest alias in [lower] that stands as whole words and starts the
  /// row (after at most [maxPrefix] characters with no digits, e.g. "S.").
  /// Ties go to the earlier catalog entry.
  AliasHit? longestMatch(String lower, {int maxPrefix = 20}) {
    AliasHit? best;
    var bestIndex = 0;
    for (var start = 0; start <= maxPrefix && start < lower.length; start++) {
      if (start > 0 && _isDigit(lower.codeUnitAt(start - 1))) break;
      if (start > 0 && _isWordChar(lower.codeUnitAt(start - 1))) continue;
      var node = _root;
      for (var i = start; i < lower.length; i++) {
        final child = node.next[lower.codeUnitAt(i)];
        if (child == null) break;
        node = child;
        final end = node.end;
        if (end == null) continue;
        final boundary =
            i + 1 == lower.length || !_isWordChar(lower.codeUnitAt(i + 1));
        if (!boundary) continue;
        final (index, definition, alias) = end;
        final length = i + 1 - start;
        if (best == null ||
            length > best.length ||
            (length == best.length && index < bestIndex)) {
          best = AliasHit(definition, alias, start, i + 1);
          bestIndex = index;
        }
      }
    }
    return best;
  }

  static bool _isDigit(int c) => c >= 0x30 && c <= 0x39;
  static bool _isWordChar(int c) => _isDigit(c) || (c >= 0x61 && c <= 0x7a);
}

class _Node {
  final next = <int, _Node>{};
  (int, LabTestDefinition, String)? end;
}
