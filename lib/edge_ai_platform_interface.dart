import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'edge_ai_availability.dart';
import 'edge_ai_download_progress.dart';
import 'edge_ai_generation_options.dart';
import 'edge_ai_method_channel.dart';

abstract class EdgeAiPlatform extends PlatformInterface {
  /// Constructs a EdgeAiPlatform.
  EdgeAiPlatform() : super(token: _token);

  static final Object _token = Object();

  static EdgeAiPlatform _instance = MethodChannelEdgeAi();

  /// The default instance of [EdgeAiPlatform] to use.
  ///
  /// Defaults to [MethodChannelEdgeAi].
  static EdgeAiPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [EdgeAiPlatform] when
  /// they register themselves.
  static set instance(EdgeAiPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Checks whether the on-device generative AI model is available.
  Future<EdgeAiAvailability> checkAvailability() {
    throw UnimplementedError('checkAvailability() has not been implemented.');
  }

  /// Triggers the on-device model download (if one is needed) and streams
  /// progress updates until it completes or fails.
  Stream<EdgeAiDownloadProgress> downloadModel() {
    throw UnimplementedError('downloadModel() has not been implemented.');
  }

  /// Sends [prompt] to the on-device model and streams its generated text.
  ///
  /// Each event is the full response text generated so far, not just the
  /// newly-added chunk.
  Stream<String> generateContent(
    String prompt, {
    EdgeAiGenerationOptions? options,
  }) {
    throw UnimplementedError('generateContent() has not been implemented.');
  }
}
