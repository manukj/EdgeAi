import 'package:edge_genai/edge_genai.dart';
import 'package:edge_genai/edge_genai_method_channel.dart';
import 'package:edge_genai/edge_genai_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEdgeGenaiPlatform
    with MockPlatformInterfaceMixin
    implements EdgeGenaiPlatform {
  @override
  Future<EdgeGenaiAvailability> checkAvailability() =>
      Future.value(EdgeGenaiAvailability.available);

  @override
  Stream<EdgeGenaiDownloadProgress> downloadModel() => Stream.value(
    EdgeGenaiDownloadProgress(status: EdgeGenaiDownloadStatus.completed),
  );

  @override
  Future<String> generateContent(String prompt) =>
      Future.value('a generated response');
}

void main() {
  final EdgeGenaiPlatform initialPlatform = EdgeGenaiPlatform.instance;

  test('$MethodChannelEdgeGenai is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelEdgeGenai>());
  });

  test('checkAvailability', () async {
    EdgeGenai edgeGenaiPlugin = EdgeGenai();
    MockEdgeGenaiPlatform fakePlatform = MockEdgeGenaiPlatform();
    EdgeGenaiPlatform.instance = fakePlatform;

    expect(
      await edgeGenaiPlugin.checkAvailability(),
      EdgeGenaiAvailability.available,
    );
  });

  test('downloadModel', () async {
    EdgeGenai edgeGenaiPlugin = EdgeGenai();
    MockEdgeGenaiPlatform fakePlatform = MockEdgeGenaiPlatform();
    EdgeGenaiPlatform.instance = fakePlatform;

    await expectLater(
      edgeGenaiPlugin.downloadModel(),
      emits(EdgeGenaiDownloadProgress(status: EdgeGenaiDownloadStatus.completed)),
    );
  });

  test('generateContent', () async {
    EdgeGenai edgeGenaiPlugin = EdgeGenai();
    MockEdgeGenaiPlatform fakePlatform = MockEdgeGenaiPlatform();
    EdgeGenaiPlatform.instance = fakePlatform;

    expect(
      await edgeGenaiPlugin.generateContent('a prompt'),
      'a generated response',
    );
  });
}
