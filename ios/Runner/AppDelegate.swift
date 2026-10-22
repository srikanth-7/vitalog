import UIKit
import Flutter
import PDFKit
import Vision
import ImageIO

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ReportOcrPlugin") {
      ReportOcrPlugin.register(with: registrar)
    }
  }
}

/// On-device text recognition for lab reports (Apple Vision; nothing leaves
/// the phone). Returns one string per printed row, top to bottom, with the
/// row's columns separated by two spaces.
class ReportOcrPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "vitalog/report_ocr", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(ReportOcrPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "recognizeData",
          let args = call.arguments as? [String: Any],
          let data = (args["data"] as? FlutterStandardTypedData)?.data else {
      result(FlutterMethodNotImplemented)
      return
    }
    let isPdf = args["pdf"] as? Bool ?? false
    // Ask iOS for extra time so a report keeps reading if the user switches
    // apps mid-scan; the app shows a "ready" notice when they come back.
    var task = UIBackgroundTaskIdentifier.invalid
    let finish = {
      if task != .invalid { UIApplication.shared.endBackgroundTask(task); task = .invalid }
    }
    task = UIApplication.shared.beginBackgroundTask(withName: "ReportOcr", expirationHandler: finish)
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let lines = try Self.recognize(data: data, isPdf: isPdf)
        DispatchQueue.main.async { result(lines); finish() }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "ocr_failed", message: error.localizedDescription, details: nil))
          finish()
        }
      }
    }
  }

  /// Works on the decrypted bytes in memory; nothing readable touches disk.
  private static func recognize(data: Data, isPdf: Bool) throws -> [String] {
    if isPdf {
      guard let document = PDFDocument(data: data) else {
        throw NSError(domain: "ReportOcr", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not open PDF"])
      }
      var lines: [String] = []
      for index in 0..<document.pageCount {
        guard let page = document.page(at: index), let image = render(page) else { continue }
        lines += try rows(from: VNImageRequestHandler(cgImage: image))
      }
      return lines
    }
    return try rows(from: VNImageRequestHandler(data: data, orientation: orientation(of: data)))
  }

  /// The photo's EXIF orientation, so sideways camera shots read correctly.
  private static func orientation(of data: Data) -> CGImagePropertyOrientation {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let raw = props[kCGImagePropertyOrientation] as? UInt32,
          let value = CGImagePropertyOrientation(rawValue: raw) else { return .up }
    return value
  }

  /// Renders a PDF page at ~3x so small table text stays legible to OCR.
  private static func render(_ page: PDFPage) -> CGImage? {
    let bounds = page.bounds(for: .mediaBox)
    let scale: CGFloat = 3
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
    let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
      UIColor.white.setFill()
      ctx.fill(CGRect(origin: .zero, size: size))
      ctx.cgContext.translateBy(x: 0, y: size.height)
      ctx.cgContext.scaleBy(x: scale, y: -scale)
      page.draw(with: .mediaBox, to: ctx.cgContext)
    }
    return image.cgImage
  }

  private static func rows(from handler: VNImageRequestHandler) throws -> [String] {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    // Language correction "fixes" units and test codes (mg/dL, T3) into words.
    request.usesLanguageCorrection = false
    // Without this, Vision may guess another script for short tokens and read
    // "mg/dL" as Cyrillic. Lab reports here are printed in English.
    if #available(iOS 16.0, *) { request.automaticallyDetectsLanguage = false }
    request.recognitionLanguages = ["en-US"]
    try handler.perform([request])
    let observations = (request.results ?? []).compactMap { obs -> (box: CGRect, text: String)? in
      guard let text = obs.topCandidates(1).first?.string else { return nil }
      return (obs.boundingBox, text)
    }
    // Vision's origin is bottom-left: sort top-to-bottom, then group pieces
    // whose vertical centres line up into one printed row.
    let sorted = observations.sorted { $0.box.midY > $1.box.midY }
    var rows: [[(box: CGRect, text: String)]] = []
    for item in sorted {
      if let last = rows.last?.first,
         abs(last.box.midY - item.box.midY) < min(last.box.height, item.box.height) * 0.6 {
        rows[rows.count - 1].append(item)
      } else {
        rows.append([item])
      }
    }
    return rows.map { row in
      row.sorted { $0.box.minX < $1.box.minX }.map(\.text).joined(separator: "  ")
    }
  }
}
