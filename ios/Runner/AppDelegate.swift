import Flutter
import PDFKit
import SwiftyTesseract
import UIKit

private struct TessDataSource: LanguageModelDataSource {
  let pathToTrainedData: String
}

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
    registerOcrChannel(registry: engineBridge.pluginRegistry)
  }

  // MARK: – OCR Method Channel

  private func registerOcrChannel(registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "DocScannerOcr") else { return }
    let channel = FlutterMethodChannel(
      name: "doc_scanner/ocr",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGS", message: "Arguments are required", details: nil))
        return
      }

      if call.method == "recognizeText" {
        guard let imagePath = args["imagePath"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "imagePath is required", details: nil))
          return
        }
        guard let dataPath = args["dataPath"] as? String,
              let language = args["language"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "OCR dataPath and language are required", details: nil))
          return
        }
        self?.recognizeText(imagePath: imagePath, dataPath: dataPath, language: language, result: result)
      } else if call.method == "recognizePdfText" {
        guard let pdfPath = args["pdfPath"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "pdfPath is required", details: nil))
          return
        }
        guard let dataPath = args["dataPath"] as? String,
              let language = args["language"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "OCR dataPath and language are required", details: nil))
          return
        }
        self?.recognizePdfText(pdfPath: pdfPath, dataPath: dataPath, language: language, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func recognizeText(
    imagePath: String,
    dataPath: String,
    language: String,
    result: @escaping FlutterResult
  ) {
    guard let image = UIImage(contentsOfFile: imagePath) else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Could not load image at path", details: imagePath))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let text = try self.recognizeText(image: image, dataPath: dataPath, language: language)
        DispatchQueue.main.async {
          result(text)
        }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "OCR_ERROR", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private func recognizePdfText(
    pdfPath: String,
    dataPath: String,
    language: String,
    result: @escaping FlutterResult
  ) {
    guard let document = PDFDocument(url: URL(fileURLWithPath: pdfPath)) else {
      result(FlutterError(code: "INVALID_PDF", message: "Could not load PDF at path", details: pdfPath))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      var pageTexts: [String] = []

      for pageIndex in 0..<document.pageCount {
        guard let page = document.page(at: pageIndex),
              let image = self.renderPdfPage(page) else {
          continue
        }

        do {
          let text = try self.recognizeText(image: image, dataPath: dataPath, language: language)
          if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            pageTexts.append(text)
          }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "OCR_ERROR", message: error.localizedDescription, details: nil))
          }
          return
        }
      }

      DispatchQueue.main.async {
        result(pageTexts.joined(separator: "\n\n"))
      }
    }
  }

  private func renderPdfPage(_ page: PDFPage) -> UIImage? {
    let pageBounds = page.bounds(for: .mediaBox)
    let scale: CGFloat = 4
    let imageSize = CGSize(width: pageBounds.width * scale, height: pageBounds.height * scale)
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1

    let image = UIGraphicsImageRenderer(size: imageSize, format: format).image { context in
      UIColor.white.set()
      context.fill(CGRect(origin: .zero, size: imageSize))

      context.cgContext.saveGState()
      context.cgContext.scaleBy(x: scale, y: scale)
      context.cgContext.translateBy(x: 0, y: pageBounds.height)
      context.cgContext.scaleBy(x: 1, y: -1)
      context.cgContext.translateBy(x: -pageBounds.origin.x, y: -pageBounds.origin.y)
      page.draw(with: .mediaBox, to: context.cgContext)
      context.cgContext.restoreGState()
    }

    return image
  }

  private func recognizeText(image: UIImage, dataPath: String, language: String) throws -> String {
    try validateTessData(dataPath: dataPath, language: language)

    let tesseract = SwiftyTesseract(
      languages: recognitionLanguages(from: language),
      dataSource: TessDataSource(pathToTrainedData: dataPath),
      engineMode: .lstmOnly
    )
    tesseract.preserveInterwordSpaces = true

    switch tesseract.performOCR(on: image) {
    case let .success(text):
      return text.trimmingCharacters(in: .whitespacesAndNewlines)
    case let .failure(error):
      throw error
    }
  }

  private func recognitionLanguages(from language: String) -> [RecognitionLanguage] {
    let languages = language
      .split(separator: "+")
      .map(String.init)
      .map { code -> RecognitionLanguage in
        switch code {
        case "khm":
          return .centralKhmer
        case "eng":
          return .english
        default:
          return .custom(code)
        }
      }

    return languages.isEmpty ? [.centralKhmer, .english] : languages
  }

  private func validateTessData(dataPath: String, language: String) throws {
    for code in language.split(separator: "+").map(String.init) {
      let filePath = URL(fileURLWithPath: dataPath).appendingPathComponent("\(code).traineddata").path
      if !FileManager.default.fileExists(atPath: filePath) {
        throw NSError(
          domain: "DocScannerOcr",
          code: 1,
          userInfo: [
            NSLocalizedDescriptionKey: "Missing OCR language file: \(code).traineddata"
          ]
        )
      }
    }
  }
}
