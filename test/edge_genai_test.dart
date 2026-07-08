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
}
