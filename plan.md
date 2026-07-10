# Plan: multi-feature architecture (Prompt, Summarization, Proofreading, Rewriting, Image Description)

Status: **design only — not yet implemented.**

## Decision

Dedicated Dart class per feature, not one god `EdgeAi` class. Reason: each
ML Kit GenAI feature (Summarization, Proofreading, Rewriting, Image
Description) has its own independent availability/download lifecycle on
Android — folding that into one shared `checkAvailability()` would be
ambiguous ("availability of what?"). Each class stays small and only
carries the options relevant to it.

## Naming

Prefix: **`EdgeGenAI`** for all classes documented here (e.g.
`EdgeGenAIPrompt`, `EdgeGenAISummarizer`).

Note: the currently-released class is `EdgeAi`, and pigeon-generated types
also use the `EdgeAi` prefix (`EdgeAiAvailability`, `EdgeAiHostApi`, etc.).
Renaming those to `EdgeGenAI*` is a breaking change and a separate piece of
work — not done yet. This plan documents the target shape for new classes
going forward.

## Class shapes

### `EdgeGenAIPrompt` (replaces today's `EdgeAi`)

```dart
class EdgeGenAIPrompt {
  EdgeGenAIPrompt({bool useMemory = false});
  Future<EdgeAiAvailability> checkAvailability();
  Stream<EdgeAiDownloadProgress> downloadModel();
  Stream<String> generateContent(String prompt, {EdgeAiGenerationOptions? options, Uint8List? image});
  Future<void> resetConversation();
}
```

### `EdgeGenAISummarizer`

```dart
class EdgeGenAISummarizer {
  Future<EdgeAiAvailability> checkAvailability();
  Stream<EdgeAiDownloadProgress> downloadModel();
  Future<String> summarize(String text);
}
```

### `EdgeGenAIProofreader`

```dart
class EdgeGenAIProofreader {
  Future<EdgeAiAvailability> checkAvailability();
  Stream<EdgeAiDownloadProgress> downloadModel();
  Future<String> proofread(String text);
}
```

### `EdgeGenAIRewriter`

```dart
class EdgeGenAIRewriter {
  Future<EdgeAiAvailability> checkAvailability();
  Stream<EdgeAiDownloadProgress> downloadModel();
  Future<String> rewrite(String text, {required EdgeGenAIRewriteStyle style});
}
```

### `EdgeGenAIImageDescriber`

```dart
class EdgeGenAIImageDescriber {
  Future<EdgeAiAvailability> checkAvailability();
  Stream<EdgeAiDownloadProgress> downloadModel();
  Future<String> describeImage(Uint8List imageBytes);
}
```

## Platform backing

- **iOS (Foundation Models)**: no dedicated classes exist natively. All
  four new features are implemented as `LanguageModelSession.respond(to:)`
  calls with a task-specific prompt — the same underlying mechanism as
  `EdgeGenAIPrompt.generateContent()`, just with a canned instruction per
  feature.
- **Android (ML Kit GenAI)**: each feature maps to a distinct, purpose-built
  client/package (Summarization, Proofreading, Rewriting, Image
  Description), separate from the general Prompt API's `GenerativeModel`.
  Chosen over reusing `GenerativeModel` everywhere because these are
  fine-tuned for their specific task (per Google's own docs) at roughly the
  same integration cost. Each has its own `checkFeatureStatus()`/
  `download()` — mirrors the dedicated Dart classes 1:1.

## Android native API reference (verified)

Verified against Google's official sample app
([`googlesamples/mlkit`](https://github.com/googlesamples/mlkit), under
`android/genai/app`) — the reference doc pages 404'd, so this comes from
real sample code instead. All four features share the same shape as the
`Generation`/`GenerativeModel` this plugin already wraps: a static
`getClient(options)` factory, `checkFeatureStatus()`/`downloadFeature()`,
`runInference(request)` (or the streaming overload with a
`StreamingCallback`), and `close()`.

| Feature | Package | Client | Options | Request | Result |
| --- | --- | --- | --- | --- | --- |
| Summarization | `com.google.mlkit.genai.summarization` | `Summarization.getClient(options)` → `Summarizer` | `SummarizerOptions.builder(context)` — `.setInputType(ARTICLE\|CONVERSATION)`, `.setOutputType(ONE_BULLET\|TWO_BULLETS\|THREE_BULLETS)`, `.setLanguage(...)` | `SummarizationRequest.builder(text).build()` | `SummarizationResult.summary` |
| Proofreading | `com.google.mlkit.genai.proofreading` | `Proofreading.getClient(options)` → `Proofreader` | `ProofreaderOptions.builder(context)` — `.setInputType(KEYBOARD\|VOICE)`, `.setLanguage(...)` | `ProofreadingRequest.builder(text).build()` | `ProofreadingResult.results` (`List<ProofreadingSuggestion>`, each `.text`) |
| Rewriting | `com.google.mlkit.genai.rewriting` | `Rewriting.getClient(options)` → `Rewriter` | `RewriterOptions.builder(context)` — `.setOutputType(ELABORATE\|EMOJIFY\|SHORTEN\|FRIENDLY\|PROFESSIONAL\|...)`, `.setLanguage(...)` | `RewritingRequest.builder(text).build()` | `RewritingResult.results` (`List<RewritingSuggestion>`, each `.text`) |
| Image description | `com.google.mlkit.genai.imagedescription` | `ImageDescription.getClient(options)` → `ImageDescriber` | `ImageDescriberOptions.builder(context).build()` | `ImageDescriptionRequest.builder(bitmap).build()` | `ImageDescriptionResult.description` |

Shared types across all four: `com.google.mlkit.genai.common` —
`FeatureStatus`, `DownloadCallback`, `GenAiException`, `StreamingCallback`.

## Multimedia (image) support

Both platforms natively support image + text multimodal input in their
general prompt API — decision: add it to `EdgeGenAIPrompt.generateContent()`
as an optional single image, **one image per call on both platforms** (see
rationale below). No audio/video support exists in either platform's
general prompt API today, so out of scope.

- **iOS (Foundation Models)**: real support via `Attachment` in the prompt
  builder, accepts `CGImage`/`CIImage`/`CVPixelBuffer`/image URL, and
  natively supports *multiple* attachments in one prompt:
  ```swift
  let response = try await session.respond {
      "Compare these two images by using three bullet points:"
      Attachment(imageOne)
      Attachment(imageTwo, orientation: .right)
  }
  ```
  `Attachment`, `ImageAttachmentContent`, `ImageReference` are marked Beta
  by Apple.
- **Android (ML Kit GenAI Prompt API)**: `ImagePart(bitmap)` bundled with
  `TextPart(text)` in one `generateContentRequest()` — same
  `GenerativeModel` this plugin already wraps, no new dependency.
  ```kotlin
  generativeModel.generateContent(generateContentRequest(ImagePart(bitmap), TextPart(text)) { ... })
  ```
  Verified (via `googlesamples/mlkit`) that despite one sample activity's
  docstring claiming "multiple images," the actual
  `GenerateContentRequest.Builder` constructor only accepts a single
  `ImagePart` + single `TextPart` — the sample's own multi-image loop
  overwrites the bitmap each iteration, so only the last image is ever
  sent. Android's real capability today is **one image per request**.
- **Decision**: expose one image per call on both platforms — the honest
  common denominator, since Android can't do more than that regardless of
  what iOS could support.

## Next steps

1. Rename the existing `EdgeAi` class and the pigeon `EdgeAi*` type prefix
   to `EdgeGenAI*` (breaking change, since all classes documented here use
   that prefix).
2. Give `EdgeGenAIPrompt` per-instance session isolation. `generateContent`
   is the only feature here that maintains a conversation, so this only
   applies to that class (the other four are one-shot, stateless calls).
   Today there's a single native session/history per app process, not
   scoped per Dart instance. Plumb a `sessionId` through
   `startGenerateContent`/`resetConversation`:
   - Pigeon: add a `sessionId` string param to both methods.
   - iOS: replace the single `session: Any?` with a `[String: Any]` map
     keyed by `sessionId`.
   - Android: replace the single `history: MutableList<Pair<String, String>>`
     with a `MutableMap<String, MutableList<Pair<String, String>>>` keyed
     by `sessionId`.
   - Dart: `EdgeGenAIPrompt` generates a unique id per instance (a simple
     static incrementing counter — no new dependency needed) and passes it
     on every call, transparently to the caller.
3. Implement `EdgeGenAISummarizer`, `EdgeGenAIProofreader`,
   `EdgeGenAIRewriter`, `EdgeGenAIImageDescriber` against the verified
   Android APIs above, with iOS backed by `generateContent()`-style
   prompting per feature.
4. Add single-image support to `EdgeGenAIPrompt.generateContent()` (see
   "Multimedia (image) support" above): iOS wraps the image bytes in an
   `Attachment`, Android decodes them into a `Bitmap` for `ImagePart`.

