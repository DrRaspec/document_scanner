import Flutter
import UIKit
import Vision

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
      guard call.method == "recognizeText" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
            let imagePath = args["imagePath"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "imagePath is required", details: nil))
        return
      }
      self?.recognizeText(imagePath: imagePath, result: result)
    }
  }

  private func recognizeText(imagePath: String, result: @escaping FlutterResult) {
    guard #available(iOS 13.0, *) else {
      result(FlutterError(code: "UNSUPPORTED", message: "OCR requires iOS 13+", details: nil))
      return
    }

    guard let image = UIImage(contentsOfFile: imagePath),
          let cgImage = image.cgImage else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Could not load image at path", details: imagePath))
      return
    }

    let request = VNRecognizeTextRequest { request, error in
      if let error = error {
        result(FlutterError(code: "OCR_ERROR", message: error.localizedDescription, details: nil))
        return
      }
      let text = (request.results as? [VNRecognizedTextObservation])?
        .compactMap { $0.topCandidates(1).first?.string }
        .joined(separator: "\n") ?? ""
      result(text)
    }

    // Use accurate mode for best quality; falls back to fast on older devices
    request.recognitionLevel = .accurate
    // Recognise both English and Khmer scripts where available
    request.recognitionLanguages = ["en-US", "km-KH"]
    request.usesLanguageCorrection = true

    DispatchQueue.global(qos: .userInitiated).async {
      let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
      do {
        try handler.perform([request])
      } catch {
        result(FlutterError(code: "OCR_ERROR", message: error.localizedDescription, details: nil))
      }
    }
  }
}
