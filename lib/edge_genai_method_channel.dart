import 'package:flutter/foundation.dart';

import 'edge_genai_platform_interface.dart';
import 'src/messages.g.dart';

class MethodChannelEdgeGenai extends EdgeGenaiPlatform {
  @visibleForTesting
  final hostApi = EdgeGenaiHostApi();

  @override
  Future<EdgeGenaiAvailability> checkAvailability() {
    return hostApi.checkAvailability();
  }
}
