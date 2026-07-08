import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut:
        'android/src/main/kotlin/com/example/edge_genai/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.example.edge_genai'),
    swiftOut: 'ios/Classes/Messages.g.swift',
    dartPackageName: 'edge_genai',
  ),
)

/// The availability of the on-device generative AI model.
enum EdgeGenaiAvailability {
  /// The model is available and ready to use.
  available,

  /// The device supports the model, but it still needs to download (for
  /// example, Android's Gemini Nano feature is downloadable/downloading).
  downloadable,

  /// The device supports the model, but the user hasn't enabled the
  /// OS-level AI feature yet (for example, Apple Intelligence is turned
  /// off).
  notYetReady,

  /// The device or OS version doesn't support the on-device model.
  unavailable,
}

/// Optional parameters controlling how the model generates its response.
///
/// Only fields supported by both Android and iOS are exposed here.
class EdgeGenaiGenerationOptions {
  EdgeGenaiGenerationOptions({this.temperature, this.maxOutputTokens});

  /// Controls the randomness of the output. Higher values produce more
  /// creative (less predictable) responses.
  final double? temperature;

  /// The maximum number of tokens the model may generate in its response.
  final int? maxOutputTokens;
}

@HostApi()
abstract class EdgeGenaiHostApi {
  @async
  EdgeGenaiAvailability checkAvailability();

  /// Stores [prompt] and [options] for the next `generateContentChunk` event
  /// channel subscription to use.
  ///
  /// Event channels can't carry parameters, so callers must invoke this
  /// immediately before listening to the `generateContentChunk` stream.
  void startGenerateContent(String prompt, EdgeGenaiGenerationOptions? options);
}

/// The status of an on-device model download.
enum EdgeGenaiDownloadStatus {
  /// The download has started.
  started,

  /// The download is in progress.
  inProgress,

  /// The download finished and the model is ready to use.
  completed,
}

/// A single download progress update.
class EdgeGenaiDownloadProgress {
  EdgeGenaiDownloadProgress({required this.status, this.bytesDownloaded});

  /// The current status of the download.
  final EdgeGenaiDownloadStatus status;

  /// The total number of bytes downloaded so far. Only populated when
  /// [status] is [EdgeGenaiDownloadStatus.inProgress].
  final int? bytesDownloaded;
}

@EventChannelApi()
abstract class EdgeGenaiEventApi {
  /// Triggers the on-device model download (if one is needed) and streams
  /// progress updates until it completes or fails.
  ///
  /// On iOS there's nothing for the app to download — Apple Intelligence is
  /// enabled system-wide in Settings — so this immediately emits a single
  /// `completed` event.
  EdgeGenaiDownloadProgress downloadProgress();

  /// Streams the response set up via `startGenerateContent`.
  ///
  /// Each event is the full response text generated so far (not just the
  /// newly-added chunk), so UI code can simply display the latest event.
  String generateContentChunk();
}