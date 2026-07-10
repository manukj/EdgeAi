import 'dart:typed_data';

import 'edge_gen_ai_availability.dart';
import 'edge_gen_ai_download_progress.dart';
import 'edge_gen_ai_platform_interface.dart';

/// The on-device image description feature.
///
/// Backed by ML Kit GenAI's Image Description API on Android and by a
/// task-specific Foundation Models prompt on iOS (which requires iOS 27+).
class EdgeGenAIImageDescriber {
  /// Checks whether the on-device image description feature is available.
  Future<EdgeGenAIAvailability> checkAvailability() {
    return EdgeGenAIPlatform.instance.checkAvailability(
      EdgeGenAIFeature.imageDescription,
    );
  }

  /// Triggers the image description model download (if one is needed) and
  /// streams progress updates until it completes or fails.
  ///
  /// On iOS, Apple Intelligence must be enabled by the person in Settings —
  /// there's nothing for the app to trigger, so this immediately completes.
  Stream<EdgeGenAIDownloadProgress> downloadModel() {
    return EdgeGenAIPlatform.instance.downloadModel(
      EdgeGenAIFeature.imageDescription,
    );
  }

  /// Describes the image encoded in [imageBytes] (for example PNG or JPEG
  /// bytes) and returns the description.
  Future<String> describeImage(Uint8List imageBytes) {
    return EdgeGenAIPlatform.instance.describeImage(imageBytes);
  }
}
