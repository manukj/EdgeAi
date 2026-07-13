import 'edge_gen_ai_availability.dart';
import 'edge_gen_ai_download_progress.dart';
import 'edge_gen_ai_platform_interface.dart';

/// The on-device text summarization feature.
///
/// Backed by ML Kit GenAI's Summarization API on Android and by a
/// task-specific Foundation Models prompt on iOS.
class EdgeGenAISummarizer {
  /// Checks whether the on-device summarization feature is available.
  Future<EdgeGenAIAvailability> checkAvailability() {
    return EdgeGenAIPlatform.instance.checkAvailability(
      EdgeGenAIFeature.summarization,
    );
  }

  /// Triggers the summarization model download (if one is needed) and
  /// streams progress updates until it completes or fails.
  ///
  /// On iOS, Apple Intelligence must be enabled by the person in Settings —
  /// there's nothing for the app to trigger, so this immediately completes.
  Stream<EdgeGenAIDownloadProgress> downloadModel() {
    return EdgeGenAIPlatform.instance.downloadModel(
      EdgeGenAIFeature.summarization,
    );
  }

  /// Summarizes [text] and returns the summary as bullet points.
  Future<String> summarize(String text) {
    return EdgeGenAIPlatform.instance.summarize(text);
  }
}
