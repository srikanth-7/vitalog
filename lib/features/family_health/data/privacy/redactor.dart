/// Strips personal and contact details out of text read from a report, so
/// only what the app needs is stored or synced. Applied when a report is
/// read and again before sync.
abstract final class Redactor {
  static final _phone = RegExp(r'\+?\d[\d\s\-().]{6,}\d');
  static final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');
  static final _url = RegExp(r'(https?://|www\.)\S+|\b\S+\.(com|in|org|net)\b',
      caseSensitive: false);

  /// Where a lab's name ends and its address or contact block begins.
  static final _addressStart = RegExp(
      r'[,|;]|\s-\s|\d{3,}|\b(ph|phone|tel|mob|mobile|cell|email|e-mail|fax|website|web|address|addr|road|rd|street|nagar|lane|sector|floor|opp|pin|pincode|near)\b',
      caseSensitive: false);

  /// The lab or hospital name alone: "Sunrise Lab, 12 MG Road, Ph 98…" →
  /// "Sunrise Lab".
  static String labName(String raw) {
    final cut = _addressStart.firstMatch(raw);
    return _tidy(text(cut == null ? raw : raw.substring(0, cut.start)));
  }

  /// Any free text with phone numbers, emails and web addresses removed.
  static String text(String raw) => _tidy(raw
      .replaceAll(_email, ' ')
      .replaceAll(_url, ' ')
      .replaceAll(_phone, ' '));

  static String _tidy(String s) => s
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .replaceAll(RegExp(r'^[\s:.\-–]+|[\s:,.\-–]+$'), '')
      .trim();
}
