import 'package:edge_ai/edge_ai.dart';
import 'package:edge_ai/edge_ai_method_channel.dart';
import 'package:edge_ai/edge_ai_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEdgeAiPlatform
    with MockPlatformInterfaceMixin
    implements EdgeAiPlatform {
  @override
  Future<EdgeAiAvailability> checkAvailability() =>
      Future.value(EdgeAiAvailability.available);

  @override
  Stream<EdgeAiDownloadProgress> downloadModel() => Stream.value(
    EdgeAiDownloadProgress(status: EdgeAiDownloadStatus.completed),
  );

  @override
  Stream<String> generateContent(String prompt, {EdgeAiGenerationOptions? options}) =>
      Stream.value('a generated response');
}

void main() {
  final EdgeAiPlatform initialPlatform = EdgeAiPlatform.instance;

  test('$MethodChannelEdgeAi is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelEdgeAi>());
  });

  test('checkAvailability', () async {
    EdgeAi edgeGenaiPlugin = EdgeAi();
    MockEdgeAiPlatform fakePlatform = MockEdgeAiPlatform();
    EdgeAiPlatform.instance = fakePlatform;

    expect(
      await edgeGenaiPlugin.checkAvailability(),
      EdgeAiAvailability.available,
    );
  });

  test('downloadModel', () async {
    EdgeAi edgeGenaiPlugin = EdgeAi();
    MockEdgeAiPlatform fakePlatform = MockEdgeAiPlatform();
    EdgeAiPlatform.instance = fakePlatform;

    await expectLater(
      edgeGenaiPlugin.downloadModel(),
      emits(EdgeAiDownloadProgress(status: EdgeAiDownloadStatus.completed)),
    );
  });

  test('generateContent', () async {
    EdgeAi edgeGenaiPlugin = EdgeAi();
    MockEdgeAiPlatform fakePlatform = MockEdgeAiPlatform();
    EdgeAiPlatform.instance = fakePlatform;

    await expectLater(
      edgeGenaiPlugin.generateContent('a prompt'),
      emits('a generated response'),
    );
  });
}
