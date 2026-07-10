import Flutter
#if canImport(FoundationModels)
  import FoundationModels
#endif

/// Starts generation for the prompt/options stashed via `startGenerateContent` when Flutter
/// starts listening, and streams the cumulative response text as it's generated.
class GenerateContentStreamHandler: GenerateContentChunkStreamHandler {
  private let takePendingRequest: () -> (String, EdgeAiGenerationOptions?, Bool)?
  private let takeSession: (Bool) -> Any?

  init(
    takePendingRequest: @escaping () -> (String, EdgeAiGenerationOptions?, Bool)?,
    takeSession: @escaping (Bool) -> Any?
  ) {
    self.takePendingRequest = takePendingRequest
    self.takeSession = takeSession
    super.init()
  }

  override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<String>) {
    guard let (prompt, options, useMemory) = takePendingRequest() else {
      sink.error(
        code: "no_prompt", message: "startGenerateContent must be called before listening.",
        details: nil)
      return
    }
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        guard let session = takeSession(useMemory) as? LanguageModelSession else {
          sink.error(
            code: "unavailable", message: "The on-device model isn't available.", details: nil)
          return
        }
        Task {
          do {
            try await FoundationModelsBridge.streamResponse(
              session: session, prompt: prompt, options: options
            ) { chunk in
              sink.success(chunk)
            }
            sink.endOfStream()
          } catch {
            sink.error(
              code: "generate_content_failed", message: error.localizedDescription, details: nil)
          }
        }
        return
      }
    #endif
    sink.error(
      code: "unavailable", message: "The on-device model isn't available.", details: nil)
  }
}
