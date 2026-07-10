# edge_ai

A Flutter plugin for **on-device** generative AI. It wraps Apple's Foundation
Models (iOS) and Google's Gemini Nano via ML Kit GenAI (Android) behind one
Dart API, so prompts are generated fully on-device — no network calls, no
cloud API keys, no data leaving the phone.

## Features

| Feature | API | Details |
| --- | --- | --- |
| Availability check | `checkAvailability()` | Reports whether the on-device model is ready, downloadable, not yet enabled, or unsupported. |
| Model download | `downloadModel()` | Streams download progress on Android (Gemini Nano via AICore). On iOS there's nothing to download — Apple Intelligence is a system-wide Setting — so this completes immediately. |
| Streaming text generation | `generateContent()` | Streams the model's response as it's generated, with optional `temperature` / `maxOutputTokens` controls. |
| Optional conversation memory | `generateContent(useMemory: true)`, `resetConversation()` | Model remembers prior turns when `useMemory` is true; calls are stateless by default. iOS reuses a native `LanguageModelSession`; Android manually prepends prior turns to each prompt (bounded by the model's ~4000-token input limit), since ML Kit's Prompt API has no native session. |

## Beta / stability notes

- **Android's backend is Beta.** ML Kit's GenAI Prompt API is explicitly
  documented as *"offered in beta, and not subject to any SLA or
  deprecation policy — changes may be made that break backward
  compatibility."*
  See [ML Kit GenAI Prompt API](https://developers.google.com/ml-kit/genai/prompt/android).
- **iOS requires iOS 26+ with Apple Intelligence enabled.** Foundation
  Models' core APIs used here (`LanguageModelSession`, `Tool`,
  `GenerationOptions`) are stable, though some ancillary APIs in the
  framework (e.g. session token-usage stats) are still marked Beta by
  Apple and aren't used by this plugin.
  See [Foundation Models](https://developer.apple.com/documentation/foundationmodels).
- **No function/tool calling yet.** This was investigated for both
  platforms: Apple's Foundation Models supports it natively via the
  `Tool` protocol, but Google's ML Kit GenAI Prompt API (Gemini Nano) does
  not — confirmed by direct testing, including with Google's
  [Agent Development Kit](https://developer.android.com/ai/adk), which
  correctly sends a tool schema to the model but the model never
  actually invokes it. Not implemented in this plugin.

## Platform requirements

- **iOS**: iOS 26+ with Apple Intelligence enabled in Settings. On older
  OS versions, unsupported devices, or with Apple Intelligence disabled,
  `checkAvailability()` reports why.
- **Android**: API 26+ on a device with Gemini Nano support via AICore
  (e.g. Pixel 8+, Samsung S23+). Devices without AICore support, or with
  an unlocked bootloader, report unavailable.

## Usage

```dart
import 'package:edge_ai/edge_ai.dart';

final edgeAi = EdgeAi();

// 1. Check whether the on-device model is ready.
final availability = await edgeAi.checkAvailability();

// 2. If needed, download it (no-op on iOS).
if (availability == EdgeAiAvailability.downloadable) {
  await for (final progress in edgeAi.downloadModel()) {
    print('${progress.status}: ${progress.bytesDownloaded ?? ''}');
  }
}

// 3. Generate content. Each event is the full text generated so far.
await for (final chunk in edgeAi.generateContent(
  'Write a 3 sentence story about a magical dog.',
  options: EdgeAiGenerationOptions(temperature: 0.8, maxOutputTokens: 256),
)) {
  print(chunk);
}

// 4. Optionally, hold a memory-enabled conversation across calls.
await for (final chunk in edgeAi.generateContent(
  'My name is Alex.',
  useMemory: true,
)) {
  print(chunk);
}
await for (final chunk in edgeAi.generateContent(
  'What is my name?',
  useMemory: true,
)) {
  print(chunk); // remembers "Alex"
}

// Start a fresh conversation.
await edgeAi.resetConversation();
```

See the [example app](example/lib/main.dart) for a full chat UI built on
top of this API.

