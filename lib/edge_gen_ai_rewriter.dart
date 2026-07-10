import 'edge_gen_ai_availability.dart';
import 'edge_gen_ai_download_progress.dart';
import 'edge_gen_ai_platform_interface.dart';
import 'edge_gen_ai_rewrite_style.dart';

/// The on-device text rewriting feature: rewrites text in a chosen
/// [EdgeGenAIRewriteStyle].
///
/// Backed by ML Kit GenAI's Rewriting API on Android and by a
/// task-specific Foundation Models prompt on iOS.
class EdgeGenAIRewriter {
  /// Checks whether the on-device rewriting feature is available.
  Future<EdgeGenAIAvailability> checkAvailability() {
    return EdgeGenAIPlatform.instance.checkAvailability(
      EdgeGenAIFeature.rewriting,
    );
  }

  /// Triggers the rewriting model download (if one is needed) and streams
  /// progress updates until it completes or fails.
  ///
  /// On iOS, Apple Intelligence must be enabled by the person in Settings —
  /// there's nothing for the app to trigger, so this immediately completes.
  Stream<EdgeGenAIDownloadProgress> downloadModel() {
    return EdgeGenAIPlatform.instance.downloadModel(EdgeGenAIFeature.rewriting);
  }

  /// Rewrites [text] in the given [style] and returns the rewritten text.
  Future<String> rewrite(String text, {required EdgeGenAIRewriteStyle style}) {
    return EdgeGenAIPlatform.instance.rewrite(text, style: style);
  }
}
