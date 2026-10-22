import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'report_text_recognizer.dart';

/// A file the app can't get report text out of (video, zip, old .doc…).
class UnsupportedDocument implements Exception {
  const UnsupportedDocument(this.kind);
  final String kind;
  @override
  String toString() => 'Unsupported document: $kind';
}

/// Turns any uploaded file into report rows: one string per printed row, top
/// to bottom, columns joined by two spaces (the format [LabReportParser]
/// reads). The type is decided from the bytes, not the file name.
///
/// - Photos (JPEG, PNG, HEIC, WebP…) and PDFs → on-device OCR.
/// - Word (.docx), Excel (.xlsx), CSV/TSV, plain text and HTML → read
///   directly, exactly as written; table cells become columns.
/// - Email (.eml) → its HTML or text body, or an attached PDF/photo report.
class DocumentReader {
  DocumentReader(this._ocr);
  final ReportTextRecognizer _ocr;

  Future<List<String>> read(Uint8List bytes, {required String fileName}) async {
    if (_isPdf(bytes)) return _ocr.recognize(bytes, isPdf: true);
    if (_isImage(bytes)) return _ocr.recognize(bytes, isPdf: false);
    if (_startsWith(bytes, const [0x50, 0x4B, 0x03, 0x04])) {
      return _office(bytes);
    }
    if (_startsWith(bytes, const [0xD0, 0xCF, 0x11, 0xE0])) {
      throw const UnsupportedDocument(
          'legacy-office'); // .doc / .xls (pre-2007)
    }
    final text = _decodeText(bytes);
    if (text == null) throw const UnsupportedDocument('binary');
    if (_looksLikeEmail(text)) return _email(text);
    if (_looksLikeHtml(text)) return htmlRows(text);
    return textRows(text, fileName: fileName);
  }

  // ---- detection ------------------------------------------------------------

  static bool _isPdf(Uint8List b) =>
      _startsWith(b, const [0x25, 0x50, 0x44, 0x46]);

  static bool _isImage(Uint8List b) =>
      _startsWith(b, const [0xFF, 0xD8, 0xFF]) || // JPEG
      _startsWith(b, const [0x89, 0x50, 0x4E, 0x47]) || // PNG
      _startsWith(b, const [0x47, 0x49, 0x46, 0x38]) || // GIF
      _startsWith(b, const [0x42, 0x4D]) || // BMP
      _startsWith(b, const [0x49, 0x49, 0x2A, 0x00]) || // TIFF (LE)
      _startsWith(b, const [0x4D, 0x4D, 0x00, 0x2A]) || // TIFF (BE)
      (b.length > 12 && // WebP: RIFF....WEBP
          _startsWith(b, const [0x52, 0x49, 0x46, 0x46]) &&
          ascii.decode(b.sublist(8, 12), allowInvalid: true) == 'WEBP') ||
      (b.length > 12 && // HEIC / HEIF / AVIF: ....ftyp
          ascii.decode(b.sublist(4, 8), allowInvalid: true) == 'ftyp');

  /// UTF-8 (or Latin-1) text that is mostly printable; null for binary data.
  static String? _decodeText(Uint8List b) {
    if (b.isEmpty) return null;
    String text;
    try {
      text = utf8.decode(b);
    } on FormatException {
      text = latin1.decode(b);
    }
    final sample = text.length > 4000 ? text.substring(0, 4000) : text;
    final control = sample.codeUnits
        .where((c) => c < 0x20 && c != 0x09 && c != 0x0A && c != 0x0D)
        .length;
    return control > sample.length * .02 ? null : text;
  }

  static final _emailHeader = RegExp(
      r'^(from|to|subject|date|mime-version|received|return-path|message-id):',
      caseSensitive: false,
      multiLine: true);
  static bool _looksLikeEmail(String t) {
    final head = t.length > 2000 ? t.substring(0, 2000) : t;
    return _emailHeader.allMatches(head).length >= 2;
  }

  static bool _looksLikeHtml(String t) =>
      RegExp(r'<(html|body|table|tr|td|div|p)\b', caseSensitive: false)
          .hasMatch(t);

  // ---- plain text, CSV, TSV --------------------------------------------------

  static List<String> textRows(String text, {String fileName = ''}) {
    final lines = const LineSplitter().convert(text);
    final lower = fileName.toLowerCase();
    final tsv = lower.endsWith('.tsv') ||
        lines.take(5).where((l) => l.contains('\t')).length >= 2;
    final csv = !tsv &&
        (lower.endsWith('.csv') ||
            lines.take(5).where((l) => ','.allMatches(l).length >= 2).length >=
                2);
    return [
      for (final line in lines)
        if (line.trim().isNotEmpty)
          tsv
              ? _joinCells(line.split('\t'))
              : csv
                  ? _joinCells(_csvCells(line))
                  : line.trim()
    ];
  }

  /// One CSV line → cells, honouring "quoted, cells" and "" escapes.
  static List<String> _csvCells(String line) {
    final cells = <String>[];
    final cell = StringBuffer();
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (quoted) {
        if (ch == '"' && i + 1 < line.length && line[i + 1] == '"') {
          cell.write('"');
          i++;
        } else if (ch == '"') {
          quoted = false;
        } else {
          cell.write(ch);
        }
      } else if (ch == '"') {
        quoted = true;
      } else if (ch == ',') {
        cells.add(cell.toString());
        cell.clear();
      } else {
        cell.write(ch);
      }
    }
    cells.add(cell.toString());
    return cells;
  }

  static String _joinCells(Iterable<String> cells) =>
      cells.map((c) => c.trim()).where((c) => c.isNotEmpty).join('  ');

  // ---- HTML --------------------------------------------------------------------

  static List<String> htmlRows(String html) {
    var s = html
        .replaceAll(
            RegExp(r'<(script|style|head)\b.*?</\1>',
                caseSensitive: false, dotAll: true),
            ' ')
        .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    s = s
        // Cells become columns; rows, paragraphs and breaks become lines.
        .replaceAll(RegExp(r'</t[dh]\s*>', caseSensitive: false), '  ')
        .replaceAll(
            RegExp(r'</(tr|p|div|li|h[1-6]|table)\s*>|<br\s*/?>',
                caseSensitive: false),
            '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '');
    return [
      for (final line in const LineSplitter().convert(_entities(s)))
        if (line.trim().isNotEmpty)
          line.trim().replaceAll(RegExp(r' {3,}'), '  ')
    ];
  }

  static String _entities(String s) => s
      .replaceAllMapped(RegExp(r'&#(x?)([0-9a-fA-F]+);'), (m) {
        final code = int.tryParse(m[2]!, radix: m[1]!.isEmpty ? 10 : 16);
        return code == null ? '' : String.fromCharCode(code);
      })
      .replaceAllMapped(
          RegExp(
              r'&(micro|mu|ndash|mdash|minus|deg|plusmn|le|ge|times|middot);'),
          (m) => _named[m[1]]!)
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&');

  /// Entities lab reports actually use (units, ranges).
  static const _named = {
    'micro': 'µ',
    'mu': 'µ',
    'ndash': '–',
    'mdash': '—',
    'minus': '−',
    'deg': '°',
    'plusmn': '±',
    'le': '≤',
    'ge': '≥',
    'times': '×',
    'middot': '·',
  };

  // ---- Word / Excel ------------------------------------------------------------

  static List<String> _office(Uint8List bytes) {
    final zip = ZipDecoder().decodeBytes(bytes);
    String? entry(String name) {
      final f = zip.findFile(name);
      return f == null ? null : utf8.decode(f.content, allowMalformed: true);
    }

    final word = entry('word/document.xml');
    if (word != null) return docxRows(word);
    if (zip.findFile('xl/workbook.xml') != null) {
      final sheets = [
        for (final f in zip.files)
          if (RegExp(r'^xl/worksheets/sheet\d+\.xml$').hasMatch(f.name)) f
      ]..sort((a, b) => _sheetNumber(a.name).compareTo(_sheetNumber(b.name)));
      return xlsxRows(entry('xl/sharedStrings.xml'), [
        for (final s in sheets) utf8.decode(s.content, allowMalformed: true)
      ]);
    }
    throw const UnsupportedDocument('zip');
  }

  static int _sheetNumber(String name) =>
      int.parse(RegExp(r'(\d+)\.xml$').firstMatch(name)!.group(1)!);

  /// Paragraphs are lines; each table row is a line with its cells as columns.
  static List<String> docxRows(String documentXml) {
    final body = XmlDocument.parse(documentXml).findAllElements('w:body').first;
    final rows = <String>[];
    String textOf(XmlElement e) =>
        e.findAllElements('w:t').map((t) => t.innerText).join();
    for (final block in body.childElements) {
      if (block.name.qualified == 'w:p') {
        final line = textOf(block).trim();
        if (line.isNotEmpty) rows.add(line);
      } else if (block.name.qualified == 'w:tbl') {
        for (final tr in block.findAllElements('w:tr')) {
          final line = _joinCells(tr.findElements('w:tc').map(textOf));
          if (line.isNotEmpty) rows.add(line);
        }
      }
    }
    return rows;
  }

  /// Every sheet's rows in order, cells as columns.
  static List<String> xlsxRows(
      String? sharedStringsXml, List<String> sheetsXml) {
    final shared = sharedStringsXml == null
        ? const <String>[]
        : [
            for (final si
                in XmlDocument.parse(sharedStringsXml).findAllElements('si'))
              si.findAllElements('t').map((t) => t.innerText).join()
          ];
    final rows = <String>[];
    for (final sheet in sheetsXml) {
      for (final row in XmlDocument.parse(sheet).findAllElements('row')) {
        final cells = row.findElements('c').map((c) {
          final type = c.getAttribute('t');
          if (type == 'inlineStr') {
            return c.findAllElements('t').map((t) => t.innerText).join();
          }
          final v = c.getElement('v')?.innerText ?? '';
          if (type == 's') {
            final i = int.tryParse(v);
            return i != null && i < shared.length ? shared[i] : '';
          }
          return v;
        });
        final line = _joinCells(cells);
        if (line.isNotEmpty) rows.add(line);
      }
    }
    return rows;
  }

  // ---- email ---------------------------------------------------------------------

  /// Prefers an attached PDF or photo (labs usually email the report as an
  /// attachment), then the HTML body, then the plain-text body.
  Future<List<String>> _email(String raw) async {
    final parts = _mimeParts(raw);
    for (final p in parts) {
      final type = p.type;
      if (type == 'application/pdf' || type.startsWith('image/')) {
        final bytes = p.bytes;
        if (_isPdf(bytes) || _isImage(bytes)) {
          return _ocr.recognize(bytes, isPdf: _isPdf(bytes));
        }
      }
    }
    final html = parts.where((p) => p.type == 'text/html').firstOrNull;
    if (html != null) {
      return htmlRows(utf8.decode(html.bytes, allowMalformed: true));
    }
    final plain = parts.where((p) => p.type == 'text/plain').firstOrNull;
    if (plain != null) {
      return textRows(utf8.decode(plain.bytes, allowMalformed: true));
    }
    throw const UnsupportedDocument('email');
  }

  /// Leaf MIME parts of a message, decoded (base64 / quoted-printable).
  static List<_MimePart> _mimeParts(String raw) {
    final split = raw.indexOf(RegExp(r'\r?\n\r?\n'));
    if (split < 0) return const [];
    final headers = _headers(raw.substring(0, split));
    final body = raw.substring(split).replaceFirst(RegExp(r'^\r?\n\r?\n'), '');
    final type = headers['content-type'] ?? 'text/plain';
    final boundary = RegExp(r'boundary="?([^";\r\n]+)"?', caseSensitive: false)
        .firstMatch(type)
        ?.group(1);
    if (type.toLowerCase().startsWith('multipart/') && boundary != null) {
      return [
        for (final chunk in body.split('--$boundary'))
          if (chunk.trim().isNotEmpty && !chunk.startsWith('--'))
            ..._mimeParts(chunk.replaceFirst(RegExp(r'^\r?\n'), ''))
      ];
    }
    final encoding =
        (headers['content-transfer-encoding'] ?? '').toLowerCase().trim();
    final Uint8List bytes;
    if (encoding == 'base64') {
      bytes = base64.decode(body.replaceAll(RegExp(r'\s'), ''));
    } else if (encoding == 'quoted-printable') {
      bytes = _quotedPrintable(body);
    } else {
      bytes = Uint8List.fromList(utf8.encode(body));
    }
    return [_MimePart(type.split(';').first.trim().toLowerCase(), bytes)];
  }

  static Map<String, String> _headers(String block) {
    final unfolded = block.replaceAll(RegExp(r'\r?\n[ \t]+'), ' ');
    return {
      for (final line in const LineSplitter().convert(unfolded))
        if (line.contains(':'))
          line.substring(0, line.indexOf(':')).trim().toLowerCase():
              line.substring(line.indexOf(':') + 1).trim()
    };
  }

  static Uint8List _quotedPrintable(String s) {
    final soft = s.replaceAll(RegExp(r'=\r?\n'), '');
    final out = <int>[];
    for (var i = 0; i < soft.length; i++) {
      if (soft[i] == '=' && i + 2 < soft.length) {
        final code = int.tryParse(soft.substring(i + 1, i + 3), radix: 16);
        if (code != null) {
          out.add(code);
          i += 2;
          continue;
        }
      }
      out.addAll(utf8.encode(soft[i]));
    }
    return Uint8List.fromList(out);
  }

  static bool _startsWith(Uint8List b, List<int> prefix) {
    if (b.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (b[i] != prefix[i]) return false;
    }
    return true;
  }
}

class _MimePart {
  const _MimePart(this.type, this.bytes);
  final String type;
  final Uint8List bytes;
}
