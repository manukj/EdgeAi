import Flutter
import UIKit
#if canImport(FoundationModels)
  import FoundationModels
#endif

public class EdgeGenaiPlugin: NSObject, FlutterPlugin, EdgeGenaiHostApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = EdgeGenaiPlugin()
    EdgeGenaiHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
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
}
