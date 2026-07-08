import Flutter
import UIKit
#if canImport(FoundationModels)
  import FoundationModels
#endif

public class EdgeAiPlugin: NSObject, FlutterPlugin, EdgeAiHostApi {
  private var pendingPrompt: String?
  private var pendingOptions: EdgeAiGenerationOptions?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = EdgeAiPlugin()
    EdgeAiHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    DownloadProgressStreamHandler.register(
      with: registrar.messenger(), streamHandler: EdgeAiDownloadProgressStreamHandler())
    GenerateContentChunkStreamHandler.register(
      with: registrar.messenger(),
      streamHandler: EdgeAiGenerateContentStreamHandler { [weak instance] in
        guard let prompt = instance?.pendingPrompt else { return nil }
        return (prompt, instance?.pendingOptions)
      })
  }

  func checkAvailability(completion: @escaping (Result<EdgeAiAvailability, Error>) -> Void) {
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

  func startGenerateContent(prompt: String, options: EdgeAiGenerationOptions?) throws {
    pendingPrompt = prompt
    pendingOptions = options
  }
}

/// There's nothing for the app to download on iOS — Apple Intelligence is
/// enabled system-wide in Settings — so this immediately reports completion.
private class EdgeAiDownloadProgressStreamHandler: DownloadProgressStreamHandler {
  override func onListen(
    withArguments arguments: Any?, sink: PigeonEventSink<EdgeAiDownloadProgress>
  ) {
    sink.success(EdgeAiDownloadProgress(status: .completed, bytesDownloaded: nil))
    sink.endOfStream()
  }
}

/// Starts generation for the prompt/options stashed via `startGenerateContent` when Flutter
/// starts listening, and streams the cumulative response text as it's generated.
private class EdgeAiGenerateContentStreamHandler: GenerateContentChunkStreamHandler {
  private let takePendingRequest: () -> (String, EdgeAiGenerationOptions?)?

  init(takePendingRequest: @escaping () -> (String, EdgeAiGenerationOptions?)?) {
    self.takePendingRequest = takePendingRequest
    super.init()
  }

  override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<String>) {
    guard let (prompt, options) = takePendingRequest() else {
      sink.error(
        code: "no_prompt", message: "startGenerateContent must be called before listening.",
        details: nil)
      return
    }
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        Task {
          do {
            let generationOptions = GenerationOptions(
              temperature: options?.temperature,
              maximumResponseTokens: options?.maxOutputTokens.map { Int($0) })
            let session = LanguageModelSession()
            let stream = session.streamResponse(to: prompt, options: generationOptions)
            for try await snapshot in stream {
              sink.success(snapshot.content)
            }
            sink.endOfStream()
          } catch {
            sink.error(code: "generate_content_failed", message: error.localizedDescription, details: nil)
          }
        }
        return
      }
    #endif
    sink.error(
      code: "unavailable", message: "The on-device model isn't available.", details: nil)
  }
}
