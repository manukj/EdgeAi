#if canImport(FoundationModels)
  import FoundationModels

  /// Bridges Apple's Foundation Models framework to the plugin.
  ///
  /// Everything that touches `FoundationModels` types lives here, gated once
  /// at the type level with `@available`, so callers elsewhere only need a
  /// single `if #available(iOS 26.0, *)` check to cross into this API
  /// instead of repeating framework-specific logic inline at every call site.
  @available(iOS 26.0, *)
  enum FoundationModelsBridge {
    /// Maps the system model's availability to the plugin's cross-platform enum.
    static func checkAvailability() -> EdgeAiAvailability {
      switch SystemLanguageModel.default.availability {
      case .available:
        return .available
      case .unavailable(.deviceNotEligible):
        return .unavailable
      case .unavailable(.appleIntelligenceNotEnabled):
        return .notYetReady
      case .unavailable(.modelNotReady):
        return .downloadable
      case .unavailable:
        return .unavailable
      }
    }

    /// Reuses `existing` if it's already a `LanguageModelSession`, otherwise
    /// creates a new one.
    ///
    /// Reusing the same session across calls lets the model remember prior
    /// turns in the conversation, since the framework records every prompt
    /// and response into the session's transcript automatically.
    static func getOrCreateSession(_ existing: Any?) -> LanguageModelSession {
      existing as? LanguageModelSession ?? LanguageModelSession()
    }

    /// Streams a response to `prompt` from `session`, invoking `onChunk` with
    /// the cumulative text generated so far on every update.
    static func streamResponse(
      session: LanguageModelSession,
      prompt: String,
      options: EdgeAiGenerationOptions?,
      onChunk: (String) -> Void
    ) async throws {
      let generationOptions = GenerationOptions(
        temperature: options?.temperature,
        maximumResponseTokens: options?.maxOutputTokens.map { Int($0) })
      let stream = session.streamResponse(to: prompt, options: generationOptions)
      for try await snapshot in stream {
        onChunk(snapshot.content)
      }
    }
  }
#endif
