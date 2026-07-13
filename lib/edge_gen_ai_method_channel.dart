import 'package:flutter/foundation.dart';

import 'edge_gen_ai_platform_interface.dart';
import 'src/messages.g.dart';

class MethodChannelEdgeGenAI extends EdgeGenAIPlatform {
  @visibleForTesting
  final hostApi = EdgeGenAIHostApi();

  @override
  Future<EdgeGenAIAvailability> checkAvailability(EdgeGenAIFeature feature) {
    return hostApi.checkAvailability(feature);
  }

  @override
  Stream<EdgeGenAIDownloadProgress> downloadModel(EdgeGenAIFeature feature) {
    switch (feature) {
      case EdgeGenAIFeature.prompt:
        return promptDownloadProgress();
      case EdgeGenAIFeature.summarization:
        return summarizationDownloadProgress();
      case EdgeGenAIFeature.proofreading:
        return proofreadingDownloadProgress();
      case EdgeGenAIFeature.rewriting:
        return rewritingDownloadProgress();
      case EdgeGenAIFeature.imageDescription:
        return imageDescriptionDownloadProgress();
    }
  }

  @override
  Stream<String> generateContent(
    String sessionId,
    String prompt, {
    EdgeGenAIGenerationOptions? options,
    bool useMemory = false,
    Uint8List? image,
  }) async* {
    await hostApi.startGenerateContent(
      sessionId,
      prompt,
      options,
      useMemory,
      image,
    );
    yield* generateContentChunk();
  }

  @override
  Future<void> resetConversation(String sessionId) {
    return hostApi.resetConversation(sessionId);
  }

  @override
  Future<String> summarize(String text) {
    return hostApi.summarize(text);
  }

  @override
  Future<String> proofread(String text) {
    return hostApi.proofread(text);
  }

  @override
  Future<String> rewrite(String text, {required EdgeGenAIRewriteStyle style}) {
    return hostApi.rewrite(text, style);
  }

  @override
  Future<String> describeImage(Uint8List imageBytes) {
    return hostApi.describeImage(imageBytes);
  }
}
