
import 'edge_genai_availability.dart';
import 'edge_genai_platform_interface.dart';

export 'edge_genai_availability.dart' show EdgeGenaiAvailability;

class EdgeGenai {
  /// Checks whether the on-device generative AI model is available.
  ///
  /// This does not download or enable the model — it only reports the
  /// current state so the app can decide what UI to show.
  Future<EdgeGenaiAvailability> checkAvailability() {
    return EdgeGenaiPlatform.instance.checkAvailability();
  }
}
