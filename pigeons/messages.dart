import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut: 'android/src/main/kotlin/com/example/edge_ai/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.example.edge_ai'),
    swiftOut: 'ios/Classes/Messages.g.swift',
    dartPackageName: 'edge_ai',
  ),
)
/// The availability of an on-device generative AI feature.
enum EdgeGenAIAvailability {
  /// The feature is available and ready to use.
  available,

  /// The device supports the feature, but it still needs to download (for
  /// example, Android's Gemini Nano feature is downloadable/downloading).
  downloadable,

  /// The device supports the feature, but the user hasn't enabled the
  /// OS-level AI feature yet (for example, Apple Intelligence is turned
  /// off).
  notYetReady,

  /// The device or OS version doesn't support the on-device feature.
  unavailable,
}

/// The on-device generative AI features exposed by this plugin.
///
/// On Android each feature is a distinct ML Kit GenAI client with its own
/// independent availability/download lifecycle; on iOS they all map to the
/// single system Foundation Models availability.
enum EdgeGenAIFeature {
  /// The general-purpose prompt feature (`EdgeGenAIPrompt`).
  prompt,

  /// The text summarization feature (`EdgeGenAISummarizer`).
  summarization,

  /// The proofreading feature (`EdgeGenAIProofreader`).
  proofreading,

  /// The text rewriting feature (`EdgeGenAIRewriter`).
  rewriting,

  /// The image description feature (`EdgeGenAIImageDescriber`).
  imageDescription,
}

/// The style `EdgeGenAIRewriter` rewrites text into.
///
/// Matches the output types of Android's ML Kit GenAI Rewriting API; on iOS
/// each style becomes a task-specific instruction to the system model.
enum EdgeGenAIRewriteStyle {
  /// Rephrases the text while keeping its meaning and length.
  rephrase,

  /// Expands on the text with more detail.
  elaborate,

  /// Adds fitting emoji to the text.
  emojify,

  /// Shortens the text while keeping its meaning.
  shorten,

  /// Rewrites the text in a casual, friendly tone.
  friendly,

  /// Rewrites the text in a formal, professional tone.
  professional,
}

/// Optional parameters controlling how the model generates its response.
///
/// Only fields supported by both Android and iOS are exposed here.
class EdgeGenAIGenerationOptions {
  EdgeGenAIGenerationOptions({this.temperature, this.maxOutputTokens});

  /// Controls the randomness of the output. Higher values produce more
  /// creative (less predictable) responses.
  final double? temperature;

  /// The maximum number of tokens the model may generate in its response.
  final int? maxOutputTokens;
}

@HostApi()
abstract class EdgeGenAIHostApi {
  @async
  EdgeGenAIAvailability checkAvailability(EdgeGenAIFeature feature);

  /// Stores the request for the next `generateContentChunk` event channel
  /// subscription to use.
  ///
  /// [sessionId] identifies the `EdgeGenAIPrompt` instance making the call,
  /// so each instance gets its own isolated conversation when [useMemory]
  /// is true; when false, it's a stateless, one-off call that neither reads
  /// nor updates that instance's remembered conversation. [image] is an
  /// optional encoded image (for example PNG or JPEG bytes) sent to the
  /// model alongside [prompt].
  ///
  /// Event channels can't carry parameters, so callers must invoke this
  /// immediately before listening to the `generateContentChunk` stream.
  void startGenerateContent(
    String sessionId,
    String prompt,
    EdgeGenAIGenerationOptions? options,
    bool useMemory,
    Uint8List? image,
  );

  /// Clears the conversation history remembered for [sessionId] so that
  /// instance's next `generateContent` call starts a fresh conversation.
  void resetConversation(String sessionId);

  /// Summarizes [text] and returns the summary.
  @async
  String summarize(String text);

  /// Proofreads [text] and returns the corrected text.
  @async
  String proofread(String text);

  /// Rewrites [text] in the given [style] and returns the rewritten text.
  @async
  String rewrite(String text, EdgeGenAIRewriteStyle style);

  /// Describes the image encoded in [imageBytes] (for example PNG or JPEG
  /// bytes) and returns the description.
  @async
  String describeImage(Uint8List imageBytes);
}

/// The status of an on-device model download.
enum EdgeGenAIDownloadStatus {
  /// The download has started.
  started,

  /// The download is in progress.
  inProgress,

  /// The download finished and the model is ready to use.
  completed,
}

/// A single download progress update.
class EdgeGenAIDownloadProgress {
  EdgeGenAIDownloadProgress({required this.status, this.bytesDownloaded});

  /// The current status of the download.
  final EdgeGenAIDownloadStatus status;

  /// The total number of bytes downloaded so far. Only populated when
  /// [status] is [EdgeGenAIDownloadStatus.inProgress].
  final int? bytesDownloaded;
}

/// Each method below is a separate event channel, so downloads of different
/// features can run (and report progress) independently.
///
/// On iOS there's nothing for the app to download — Apple Intelligence is
/// enabled system-wide in Settings — so every download stream immediately
/// emits a single `completed` event.
@EventChannelApi()
abstract class EdgeGenAIEventApi {
  /// Triggers the prompt feature's model download (if one is needed) and
  /// streams progress updates until it completes or fails.
  EdgeGenAIDownloadProgress promptDownloadProgress();

  /// Same as [promptDownloadProgress], for the summarization feature.
  EdgeGenAIDownloadProgress summarizationDownloadProgress();

  /// Same as [promptDownloadProgress], for the proofreading feature.
  EdgeGenAIDownloadProgress proofreadingDownloadProgress();

  /// Same as [promptDownloadProgress], for the rewriting feature.
  EdgeGenAIDownloadProgress rewritingDownloadProgress();

  /// Same as [promptDownloadProgress], for the image description feature.
  EdgeGenAIDownloadProgress imageDescriptionDownloadProgress();

  /// Streams the response set up via `startGenerateContent`.
  ///
  /// Each event is the full response text generated so far (not just the
  /// newly-added chunk), so UI code can simply display the latest event.
  String generateContentChunk();
}
