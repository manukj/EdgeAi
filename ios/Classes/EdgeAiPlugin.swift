import Flutter
import UIKit
#if canImport(FoundationModels)
  import FoundationModels
#endif

public class EdgeAiPlugin: NSObject, FlutterPlugin, EdgeAiHostApi {
  private var pendingPrompt: String?
  private var pendingOptions: EdgeAiGenerationOptions?
  private var pendingUseMemory = false

  /// The in-progress conversation, reused across `generateContent` calls
  /// that opt into memory, so the model remembers prior turns. Holds a
  /// `LanguageModelSession` (iOS 26+) once one has been created;
  /// type-erased so this property can exist on OS versions where that type
  /// isn't available.
  private var session: Any?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = EdgeAiPlugin()
    EdgeAiHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    
    // NOT NEEDED: The download progress stream is only relevant on Android, but we still register it so that the Flutter side can listen to it without crashing.
    DownloadProgressStreamHandler.register(
      with: registrar.messenger(), streamHandler: DefaultDownloadProgressStreamHandler())

    // The generate content stream is used to stream the model's response back to Flutter as it's generated.
    GenerateContentChunkStreamHandler.register(
      with: registrar.messenger(),
      streamHandler: GenerateContentStreamHandler(
        takePendingRequest: { [weak instance] in
          guard let prompt = instance?.pendingPrompt else { return nil }
          return (prompt, instance?.pendingOptions, instance?.pendingUseMemory ?? false)
        },
        takeSession: { [weak instance] useMemory in
          #if canImport(FoundationModels)
            if #available(iOS 26.0, *) {
              guard useMemory else { return LanguageModelSession() }
              let session = FoundationModelsBridge.getOrCreateSession(instance?.session)
              instance?.session = session
              return session
            }
          #endif
          return nil
        }))
  }

  func checkAvailability(completion: @escaping (Result<EdgeAiAvailability, Error>) -> Void) {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        completion(.success(FoundationModelsBridge.checkAvailability()))
        return
      }
    #endif
    completion(.success(.unavailable))
  }

  func startGenerateContent(
    prompt: String, options: EdgeAiGenerationOptions?, useMemory: Bool
  ) throws {
    pendingPrompt = prompt
    pendingOptions = options
    pendingUseMemory = useMemory
  }

  func resetConversation() throws {
    session = nil
  }
}
