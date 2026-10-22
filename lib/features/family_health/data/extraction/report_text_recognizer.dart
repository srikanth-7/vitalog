import 'package:flutter/services.dart';

/// Reads the text of a report image or PDF on-device. iOS uses Apple Vision
/// (see `ReportOcrPlugin` in ios/Runner/AppDelegate.swift); Android is not
/// implemented yet and throws [UnsupportedError].
///
/// Takes the document's bytes rather than a path so the decrypted original
/// only ever exists in memory.
class ReportTextRecognizer {
  static const _channel = MethodChannel('vitalog/report_ocr');

  /// One string per printed row, top to bottom.
  Future<List<String>> recognize(Uint8List bytes, {required bool isPdf}) async {
    try {
      final lines = await _channel.invokeListMethod<String>(
          'recognizeData', {'data': bytes, 'pdf': isPdf});
      return lines ?? const [];
    } on MissingPluginException {
      throw UnsupportedError(
          'On-device text recognition is not available on this platform yet.');
    }
  }
}
