
import 'edge_genai_availability.dart';
import 'edge_genai_download_progress.dart';
import 'edge_genai_platform_interface.dart';

export 'edge_genai_availability.dart' show EdgeGenaiAvailability;
export 'edge_genai_download_progress.dart'
    show EdgeGenaiDownloadProgress, EdgeGenaiDownloadStatus;

class EdgeGenai {
  /// Checks whether the on-device generative AI model is available.
  ///
  /// This does not download or enable the model — it only reports the
  /// current state so the app can decide what UI to show.
  Future<EdgeGenaiAvailability> checkAvailability() {
    return EdgeGenaiPlatform.instance.checkAvailability();
  }

  /// Triggers the on-device model download (if one is needed) and streams
  /// progress updates until it completes or fails.
  ///
  /// On iOS, Apple Intelligence must be enabled by the person in Settings —
  /// there's nothing for the app to trigger, so this immediately completes.
  Stream<EdgeGenaiDownloadProgress> downloadModel() {
    return EdgeGenaiPlatform.instance.downloadModel();
  }
}
