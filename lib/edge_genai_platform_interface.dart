import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'edge_genai_availability.dart';
import 'edge_genai_download_progress.dart';
import 'edge_genai_generation_options.dart';
import 'edge_genai_method_channel.dart';

abstract class EdgeGenaiPlatform extends PlatformInterface {
  /// Constructs a EdgeGenaiPlatform.
  EdgeGenaiPlatform() : super(token: _token);

  static final Object _token = Object();

  static EdgeGenaiPlatform _instance = MethodChannelEdgeGenai();

  /// The default instance of [EdgeGenaiPlatform] to use.
  ///
  /// Defaults to [MethodChannelEdgeGenai].
  static EdgeGenaiPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [EdgeGenaiPlatform] when
  /// they register themselves.
  static set instance(EdgeGenaiPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Checks whether the on-device generative AI model is available.
  Future<EdgeGenaiAvailability> checkAvailability() {
    throw UnimplementedError('checkAvailability() has not been implemented.');
  }

  /// Triggers the on-device model download (if one is needed) and streams
  /// progress updates until it completes or fails.
  Stream<EdgeGenaiDownloadProgress> downloadModel() {
    throw UnimplementedError('downloadModel() has not been implemented.');
  }

  /// Sends [prompt] to the on-device model and streams its generated text.
  ///
  /// Each event is the full response text generated so far, not just the
  /// newly-added chunk.
  Stream<String> generateContent(
    String prompt, {
    EdgeGenaiGenerationOptions? options,
  }) {
    throw UnimplementedError('generateContent() has not been implemented.');
  }
}
