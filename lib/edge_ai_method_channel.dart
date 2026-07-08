import 'package:flutter/foundation.dart';

import 'edge_ai_platform_interface.dart';
import 'src/messages.g.dart';

class MethodChannelEdgeAi extends EdgeAiPlatform {
  @visibleForTesting
  final hostApi = EdgeAiHostApi();

  @override
  Future<EdgeAiAvailability> checkAvailability() {
    return hostApi.checkAvailability();
  }

  @override
  Stream<EdgeAiDownloadProgress> downloadModel() {
    return downloadProgress();
  }

  @override
  Stream<String> generateContent(
    String prompt, {
    EdgeAiGenerationOptions? options,
  }) async* {
    await hostApi.startGenerateContent(prompt, options);
    yield* generateContentChunk();
  }
}
