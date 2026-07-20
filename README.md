# edge_ai

A Flutter plugin for **on-device** generative AI. It wraps Apple's Foundation
Models (iOS) and Google's Gemini Nano via ML Kit GenAI (Android) behind one
Dart API, so everything is generated fully on-device — no network calls, no
cloud API keys, no data leaving the phone.

## Features

Each feature is its own small class, because on Android each one is a
distinct ML Kit GenAI client with its own independent availability and
download lifecycle. Every class exposes `checkAvailability()` and
`downloadModel()` alongside its task method:

| Class | Task | Details |
| --- | --- | --- |
| `EdgeGenAIPrompt` | `generateContent()` | Streams the model's response to a free-form prompt as it's generated, with optional `temperature` / `maxOutputTokens` controls, an optional image input, optional per-instance conversation memory, and optional tool (function) calling. |
| `EdgeGenAISummarizer` | `summarize()` | Summarizes text as bullet points. |
| `EdgeGenAIProofreader` | `proofread()` | Fixes grammar, spelling, and punctuation without changing the text's meaning. |
| `EdgeGenAIRewriter` | `rewrite()` | Rewrites text in a chosen `EdgeGenAIRewriteStyle` (rephrase, elaborate, emojify, shorten, friendly, professional). |
| `EdgeGenAIImageDescriber` | `describeImage()` | Describes an image. |

On Android the four task-specific features map to ML Kit GenAI's dedicated,
fine-tuned APIs (Summarization, Proofreading, Rewriting, Image Description);
on iOS they're implemented as task-specific prompts to the same system
Foundation Model that backs `EdgeGenAIPrompt`.

### Availability + download

`checkAvailability()` reports whether the on-device feature is ready,
downloadable, not yet enabled, or unsupported. `downloadModel()` streams
download progress on Android (Gemini Nano via AICore); on iOS there's
nothing to download — Apple Intelligence is a system-wide Setting — so it
completes immediately.

### Conversation memory

`EdgeGenAIPrompt(useMemory: true)` remembers prior turns across
`generateContent()` calls; `resetConversation()` starts over. Calls are
stateless by default, and every `EdgeGenAIPrompt` instance keeps its own
isolated conversation. iOS reuses a native `LanguageModelSession` per
instance; Android manually prepends prior turns to each prompt (bounded by
the model's ~4000-token input limit), since ML Kit's Prompt API has no
native session.

### Image input

`generateContent(image: ...)` and `describeImage()` accept a single encoded
image (e.g. PNG or JPEG bytes) — one image per call, which is the honest
common denominator: Android's `GenerateContentRequest` accepts at most one
image regardless of what iOS could support. On iOS, image input requires
iOS 27+ (Foundation Models' `Attachment`, currently Beta) and building with
Xcode 27+; on earlier OS/SDK versions the image features report unavailable.

### Tool (function) calling

Give an `EdgeGenAIPrompt` instance a list of `EdgeGenAITool`s and the model
can call back into your Dart code while generating. Tools are fixed per
instance (not per call) because iOS binds them to the native session that
carries the conversation. On iOS this uses Foundation Models' native `Tool`
protocol; on Android it's emulated with prompting (see the note below) —
the model is asked to reply with a tool-call JSON object, the plugin runs
your Dart function, feeds the result back, and returns the final answer.
On Android the final answer arrives as a single event rather than
streaming, since intermediate rounds are tool-call JSON.

```dart
final assistant = EdgeGenAIPrompt(
  tools: [
    EdgeGenAITool(
      name: 'get_weather',
      description: 'Gets the current weather for a city.',
      parameters: [
        EdgeGenAIToolParameter(
          name: 'city',
          description: 'The city to get the weather for.',
        ),
      ],
      onCall: (arguments) async {
        return lookUpWeather(arguments['city'] as String? ?? '');
      },
    ),
  ],
);

await for (final chunk in assistant.generateContent(
  'Should I bring an umbrella in Oslo today?',
)) {
  print(chunk);
}
```

Beyond plain typed parameters, `EdgeGenAIToolSchema` describes richer
argument shapes — string enums, numeric ranges, arrays with length bounds,
and nested objects — mirroring what Foundation Models'
`DynamicGenerationSchema` can *enforce natively* on iOS (the model
literally cannot produce arguments outside the schema there). On Android
the same schema is embedded in the prompt as JSON Schema text for the
model to follow:

```dart
EdgeGenAITool(
  name: 'create_reminder',
  description: 'Creates a reminder.',
  parameters: [
    EdgeGenAIToolParameter(
      name: 'title',
      description: 'The reminder title.',
    ),
    EdgeGenAIToolParameter(
      name: 'priority',
      description: 'How urgent the reminder is.',
      schema: EdgeGenAIToolSchema.string(
        enumValues: ['low', 'medium', 'high'],
      ),
      isRequired: false,
    ),
    EdgeGenAIToolParameter(
      name: 'minutesFromNow',
      description: 'When the reminder should fire.',
      schema: EdgeGenAIToolSchema.integer(minimum: 1, maximum: 1440),
    ),
    EdgeGenAIToolParameter(
      name: 'tags',
      description: 'Labels for the reminder.',
      schema: EdgeGenAIToolSchema.array(
        items: EdgeGenAIToolSchema.string(),
        maxItems: 5,
      ),
      isRequired: false,
    ),
  ],
  onCall: (arguments) async => createReminder(arguments),
)
```

## Beta / stability notes

- **Android's backend is Beta.** ML Kit's GenAI APIs are explicitly
  documented as *"offered in beta, and not subject to any SLA or
  deprecation policy — changes may be made that break backward
  compatibility."*
  See [ML Kit GenAI](https://developers.google.com/ml-kit/genai).
- **iOS requires iOS 26+ with Apple Intelligence enabled.** Foundation
  Models' core APIs used here (`LanguageModelSession`,
  `GenerationOptions`) are stable; image input additionally uses
  `Attachment`, which is iOS 27+ and still marked Beta by Apple.
  See [Foundation Models](https://developer.apple.com/documentation/foundationmodels).
- **Tool calling on Android is emulated, and best-effort.** Apple's
  Foundation Models supports tool calling natively via the `Tool`
  protocol, and that's what iOS uses. Google's ML Kit GenAI Prompt API
  (Gemini Nano) has no native support — confirmed by direct testing,
  including with Google's
  [Agent Development Kit](https://developer.android.com/ai/adk), which
  correctly sends a tool schema to the model but the model never
  actually invokes it. On Android this plugin therefore *emulates* tool
  calling by instructing the model to reply with a tool-call JSON object
  and looping tool results back into the prompt; the small on-device
  model may still answer directly instead of calling a tool, so treat
  Android tool calling as experimental.

## Platform requirements

- **iOS**: iOS 26+ with Apple Intelligence enabled in Settings (iOS 27+
  for image input). On older OS versions, unsupported devices, or with
  Apple Intelligence disabled, `checkAvailability()` reports why.
- **Android**: API 26+ on a device with Gemini Nano support via AICore
  (e.g. Pixel 8+, Samsung S23+). Devices without AICore support, or with
  an unlocked bootloader, report unavailable. Each feature's model
  downloads separately.

## Usage

```dart
import 'package:edge_ai/edge_ai.dart';

final prompt = EdgeGenAIPrompt();

// 1. Check whether the on-device feature is ready.
final availability = await prompt.checkAvailability();

// 2. If needed, download it (no-op on iOS).
if (availability == EdgeGenAIAvailability.downloadable) {
  await for (final progress in prompt.downloadModel()) {
    print('${progress.status}: ${progress.bytesDownloaded ?? ''}');
  }
}

// 3. Generate content. Each event is the full text generated so far.
await for (final chunk in prompt.generateContent(
  'Write a 3 sentence story about a magical dog.',
  options: EdgeGenAIGenerationOptions(temperature: 0.8, maxOutputTokens: 256),
)) {
  print(chunk);
}

// Optionally attach a single image (encoded bytes, e.g. PNG or JPEG).
await for (final chunk in prompt.generateContent(
  'What is in this picture?',
  image: imageBytes,
)) {
  print(chunk);
}
```

Hold a memory-enabled conversation across calls:

```dart
final chat = EdgeGenAIPrompt(useMemory: true);
await for (final chunk in chat.generateContent('My name is Alex.')) {}
await for (final chunk in chat.generateContent('What is my name?')) {
  print(chunk); // remembers "Alex"
}
await chat.resetConversation(); // start fresh
```

Use the task-specific features (each has its own `checkAvailability()` /
`downloadModel()`, exactly like `EdgeGenAIPrompt`):

```dart
final summary = await EdgeGenAISummarizer().summarize(longArticle);

final corrected = await EdgeGenAIProofreader().proofread('the quick brown fox jumsp');

final formal = await EdgeGenAIRewriter().rewrite(
  'hey, meeting is off',
  style: EdgeGenAIRewriteStyle.professional,
);

final description = await EdgeGenAIImageDescriber().describeImage(imageBytes);
```

See the [example app](example/lib/main.dart) for a chat UI and a text-tools
demo built on top of this API.
