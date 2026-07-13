## 0.1.0

**Breaking changes**

* Renamed the public API from the `EdgeAi` prefix to `EdgeGenAI`:
  * `EdgeAi` is now `EdgeGenAIPrompt`.
  * `EdgeAiAvailability`, `EdgeAiDownloadProgress`, `EdgeAiDownloadStatus`,
    and `EdgeAiGenerationOptions` are now `EdgeGenAIAvailability`,
    `EdgeGenAIDownloadProgress`, `EdgeGenAIDownloadStatus`, and
    `EdgeGenAIGenerationOptions`.
  * The platform interface (`EdgeGenAIPlatform`) and method channel
    implementation (`MethodChannelEdgeGenAI`) were renamed accordingly, and
    `checkAvailability`/`downloadModel` now take the `EdgeGenAIFeature`
    they apply to.

**New features**

* `EdgeGenAISummarizer`, `EdgeGenAIProofreader`, `EdgeGenAIRewriter`, and
  `EdgeGenAIImageDescriber`: one-shot text summarization, proofreading,
  rewriting (in a chosen `EdgeGenAIRewriteStyle`), and image description.
  Backed by ML Kit GenAI's dedicated APIs on Android and task-specific
  Foundation Models prompts on iOS, each with its own independent
  availability check and model download.
* `EdgeGenAIPrompt.generateContent` accepts an optional single `image`
  (encoded bytes) alongside the prompt. On iOS this requires iOS 27+
  (Foundation Models `Attachment`, Beta) and building with Xcode 27+.
* Conversation memory is now isolated per `EdgeGenAIPrompt` instance
  instead of shared per app process.

## 0.0.1

* Initial release: on-device availability check, model download with
  progress, streaming text generation with optional generation options,
  and optional conversation memory, backed by Apple's Foundation Models
  on iOS and ML Kit GenAI (Gemini Nano) on Android.
