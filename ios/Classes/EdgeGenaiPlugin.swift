import Flutter
import UIKit
#if canImport(FoundationModels)
  import FoundationModels
#endif

public class EdgeGenaiPlugin: NSObject, FlutterPlugin, EdgeGenaiHostApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = EdgeGenaiPlugin()
    EdgeGenaiHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    DownloadProgressStreamHandler.register(
      with: registrar.messenger(), streamHandler: EdgeGenaiDownloadProgressStreamHandler())
  }

  func checkAvailability(completion: @escaping (Result<EdgeGenaiAvailability, Error>) -> Void) {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        switch SystemLanguageModel.default.availability {
        case .available:
          completion(.success(.available))
          return
        case .unavailable(.deviceNotEligible):
          completion(.success(.unavailable))
          return
        case .unavailable(.appleIntelligenceNotEnabled):
          completion(.success(.notYetReady))
          return
        case .unavailable(.modelNotReady):
          completion(.success(.downloadable))
          return
        case .unavailable:
          completion(.success(.unavailable))
          return
        }
      }
    #endif
    completion(.success(.unavailable))
  }

  func generateContent(
    prompt: String, completion: @escaping (Result<String, Error>) -> Void
  ) {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        Task {
          do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            completion(.success(response.content))
          } catch {
            completion(.failure(error))
          }
        }
        return
      }
    #endif
    completion(
      .failure(
        PigeonError(
          code: "unavailable", message: "The on-device model isn't available.", details: nil)))
  }
}

/// There's nothing for the app to download on iOS — Apple Intelligence is
/// enabled system-wide in Settings — so this immediately reports completion.
private class EdgeGenaiDownloadProgressStreamHandler: DownloadProgressStreamHandler {
  override func onListen(
    withArguments arguments: Any?, sink: PigeonEventSink<EdgeGenaiDownloadProgress>
  ) {
    sink.success(EdgeGenaiDownloadProgress(status: .completed, bytesDownloaded: nil))
    sink.endOfStream()
  }
}
