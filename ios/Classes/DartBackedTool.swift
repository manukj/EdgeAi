import Flutter
import Foundation

#if canImport(FoundationModels)
  import FoundationModels

  /// A Foundation Models `Tool` whose implementation lives in Dart.
  ///
  /// The schema shown to the model is built at runtime from the Dart-side
  /// tool definition via `DynamicGenerationSchema`; when the model calls the
  /// tool, the arguments are forwarded to the matching Dart executor through
  /// `EdgeGenAIToolExecutorApi` and its result is handed back to the model.
  @available(iOS 26.0, *)
  final class DartBackedTool: Tool {
    typealias Arguments = GeneratedContent
    typealias Output = String

    let name: String
    let description: String
    let parameters: GenerationSchema

    private let sessionId: String
    private let toolExecutorApi: EdgeGenAIToolExecutorApi

    /// Fails only if the parameter list can't be turned into a
    /// `GenerationSchema` (for example, duplicate parameter names).
    init?(
      definition: EdgeGenAIToolDefinition,
      sessionId: String,
      toolExecutorApi: EdgeGenAIToolExecutorApi
    ) {
      self.name = definition.name
      self.description = definition.descriptionText
      self.sessionId = sessionId
      self.toolExecutorApi = toolExecutorApi
      let properties = definition.parameters.map { parameter in
        DynamicGenerationSchema.Property(
          name: parameter.name,
          description: parameter.descriptionText,
          schema: Self.schema(for: parameter.type),
          isOptional: !parameter.isRequired)
      }
      let root = DynamicGenerationSchema(
        name: definition.name, description: definition.descriptionText, properties: properties)
      guard let schema = try? GenerationSchema(root: root, dependencies: []) else {
        return nil
      }
      self.parameters = schema
    }

    private static func schema(for type: EdgeGenAIToolParameterType) -> DynamicGenerationSchema {
      switch type {
      case .string:
        return DynamicGenerationSchema(type: String.self, guides: [])
      case .number:
        return DynamicGenerationSchema(type: Double.self, guides: [])
      case .integer:
        return DynamicGenerationSchema(type: Int.self, guides: [])
      case .boolean:
        return DynamicGenerationSchema(type: Bool.self, guides: [])
      }
    }

    func call(arguments: GeneratedContent) async throws -> String {
      let argumentsJson = arguments.jsonString
      // Pigeon channels must be used from the platform (main) thread, while
      // the model invokes tools from its own concurrency context.
      return try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.main.async {
          self.toolExecutorApi.callTool(
            sessionId: self.sessionId, toolName: self.name, argumentsJson: argumentsJson
          ) { result in
            continuation.resume(with: result)
          }
        }
      }
    }
  }
#endif
