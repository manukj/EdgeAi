
import 'edge_ai_availability.dart';
import 'edge_ai_download_progress.dart';
import 'edge_ai_generation_options.dart';
import 'edge_ai_platform_interface.dart';

export 'edge_ai_availability.dart' show EdgeAiAvailability;
export 'edge_ai_download_progress.dart'
    show EdgeAiDownloadProgress, EdgeAiDownloadStatus;
export 'edge_ai_generation_options.dart' show EdgeAiGenerationOptions;

class EdgeAi {
  /// Checks whether the on-device generative AI model is available.
  ///
  /// This does not download or enable the model — it only reports the
  /// current state so the app can decide what UI to show.
  Future<EdgeAiAvailability> checkAvailability() {
    return EdgeAiPlatform.instance.checkAvailability();
  }

  /// Triggers the on-device model download (if one is needed) and streams
  /// progress updates until it completes or fails.
  ///
  /// On iOS, Apple Intelligence must be enabled by the person in Settings —
  /// there's nothing for the app to trigger, so this immediately completes.
  Stream<EdgeAiDownloadProgress> downloadModel() {
    return EdgeAiPlatform.instance.downloadModel();
  }

  /// Sends [prompt] to the on-device model and streams its generated text.
  ///
  /// Each event is the full response text generated so far, not just the
  /// newly-added chunk, so UI code can simply display the latest event.
  Stream<String> generateContent(
    String prompt, {
    EdgeAiGenerationOptions? options,
  }) {
    return EdgeAiPlatform.instance.generateContent(
      prompt,
      options: options,
    );
  }
}
