import 'edge_gen_ai_availability.dart';
import 'edge_gen_ai_download_progress.dart';
import 'edge_gen_ai_platform_interface.dart';

/// The on-device proofreading feature: fixes grammar, spelling, and
/// punctuation without changing the text's meaning.
///
/// Backed by ML Kit GenAI's Proofreading API on Android and by a
/// task-specific Foundation Models prompt on iOS.
class EdgeGenAIProofreader {
  /// Checks whether the on-device proofreading feature is available.
  Future<EdgeGenAIAvailability> checkAvailability() {
    return EdgeGenAIPlatform.instance.checkAvailability(
      EdgeGenAIFeature.proofreading,
    );
  }

  /// Triggers the proofreading model download (if one is needed) and
  /// streams progress updates until it completes or fails.
  ///
  /// On iOS, Apple Intelligence must be enabled by the person in Settings —
  /// there's nothing for the app to trigger, so this immediately completes.
  Stream<EdgeGenAIDownloadProgress> downloadModel() {
    return EdgeGenAIPlatform.instance.downloadModel(
      EdgeGenAIFeature.proofreading,
    );
  }

  /// Proofreads [text] and returns the corrected text.
  Future<String> proofread(String text) {
    return EdgeGenAIPlatform.instance.proofread(text);
  }
}
