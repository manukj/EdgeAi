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

@HostApi()
abstract class EdgeGenaiHostApi {
  @async
  EdgeGenaiAvailability checkAvailability();

  /// Sends [prompt] to the on-device model and returns its generated text
  /// response.
  @async
  String generateContent(String prompt);
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
abstract class EdgeGenaiDownloadEventApi {
  /// Triggers the on-device model download (if one is needed) and streams
  /// progress updates until it completes or fails.
  ///
  /// On iOS there's nothing for the app to download \u2014 Apple Intelligence is
  /// enabled system-wide in Settings \u2014 so this immediately emits a single
  /// `completed` event.
  EdgeGenaiDownloadProgress downloadProgress();
}
