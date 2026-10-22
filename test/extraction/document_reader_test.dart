import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:vitalog/features/family_health/data/extraction/document_reader.dart';
import 'package:vitalog/features/family_health/data/extraction/report_text_recognizer.dart';
import 'package:flutter_test/flutter_test.dart';

class _Ocr extends ReportTextRecognizer {
  bool? sawPdf;
  @override
  Future<List<String>> recognize(Uint8List bytes, {required bool isPdf}) async {
    sawPdf = isPdf;
    return ['OCR'];
  }
}

Uint8List _zip(Map<String, String> files) {
  final archive = Archive();
  files.forEach((name, text) {
    final bytes = utf8.encode(text);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  late _Ocr ocr;
  late DocumentReader reader;
  setUp(() {
    ocr = _Ocr();
    reader = DocumentReader(ocr);
  });
  Future<List<String>> read(List<int> bytes, [String name = 'f']) =>
      reader.read(Uint8List.fromList(bytes), fileName: name);

  test('photos and PDFs go to OCR, by content not file name', () async {
    expect(await read([0xFF, 0xD8, 0xFF, 0xE0], 'report.pdf'), ['OCR']);
    expect(ocr.sawPdf, isFalse);
    expect(await read(utf8.encode('%PDF-1.7 ...'), 'scan.jpg'), ['OCR']);
    expect(ocr.sawPdf, isTrue);
  });

  test('CSV and HTML tables become rows with two-space columns', () async {
    expect(
        await read(
            utf8.encode(
                'Test,Result,Unit,Range\n"Hemoglobin",13.2,g/dL,"13.0 - 17.0"\n'),
            'labs.csv'),
        ['Test  Result  Unit  Range', 'Hemoglobin  13.2  g/dL  13.0 - 17.0']);
    expect(
        await read(utf8.encode(
            '<html><body><p>Sunrise Lab</p><table><tr><td>TSH</td><td>3.1</td>'
            '<td>&micro;IU/mL</td><td>0.4 &ndash; 4.0</td></tr></table></body></html>')),
        contains('TSH  3.1  µIU/mL  0.4 – 4.0'));
  });

  test('Word and Excel files are read directly, tables as rows', () async {
    final docx = _zip({
      'word/document.xml': '<w:document xmlns:w="w"><w:body>'
          '<w:p><w:r><w:t>Sunrise Lab</w:t></w:r></w:p>'
          '<w:tbl><w:tr><w:tc><w:p><w:r><w:t>Creatinine</w:t></w:r></w:p></w:tc>'
          '<w:tc><w:p><w:r><w:t>0.9</w:t></w:r></w:p></w:tc>'
          '<w:tc><w:p><w:r><w:t>mg/dL</w:t></w:r></w:p></w:tc></w:tr></w:tbl>'
          '</w:body></w:document>',
    });
    expect(await read(docx), ['Sunrise Lab', 'Creatinine  0.9  mg/dL']);

    final xlsx = _zip({
      'xl/workbook.xml': '<workbook/>',
      'xl/sharedStrings.xml':
          '<sst><si><t>HbA1c</t></si><si><t>%</t></si></sst>',
      'xl/worksheets/sheet1.xml': '<worksheet><sheetData><row>'
          '<c t="s"><v>0</v></c><c><v>5.9</v></c><c t="s"><v>1</v></c>'
          '</row></sheetData></worksheet>',
    });
    expect(await read(xlsx), ['HbA1c  5.9  %']);
  });

  test('an emailed report is read from its PDF attachment', () async {
    final pdf = base64.encode(utf8.encode('%PDF-1.4 report'));
    final eml = 'From: lab@example.com\r\nTo: me@example.com\r\n'
        'Subject: Your report\r\nMIME-Version: 1.0\r\n'
        'Content-Type: multipart/mixed; boundary="b1"\r\n\r\n'
        '--b1\r\nContent-Type: text/plain\r\n\r\nPlease find attached.\r\n'
        '--b1\r\nContent-Type: application/pdf\r\n'
        'Content-Transfer-Encoding: base64\r\n\r\n$pdf\r\n--b1--\r\n';
    expect(await read(utf8.encode(eml), 'report.eml'), ['OCR']);
    expect(ocr.sawPdf, isTrue);
  });

  test('files with no report text are rejected clearly', () async {
    expect(read([0xD0, 0xCF, 0x11, 0xE0, 0, 0]),
        throwsA(isA<UnsupportedDocument>())); // old .doc
    expect(read(_zip({'song.mp3': 'x'})), throwsA(isA<UnsupportedDocument>()));
    expect(read([0, 1, 2, 3, 0, 0, 7, 8]), throwsA(isA<UnsupportedDocument>()));
  });
}
