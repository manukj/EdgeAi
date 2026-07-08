import 'package:edge_genai/edge_genai_method_channel.dart';
import 'package:edge_genai/src/messages.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger = TestDefaultBinaryMessengerBinding
      .instance
      .defaultBinaryMessenger;
  MethodChannelEdgeGenai platform = MethodChannelEdgeGenai();

  void mockChannel(String method, Object? response) {
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.edge_genai.EdgeGenaiHostApi.$method',
      (ByteData? message) async {
        return EdgeGenaiHostApi.pigeonChannelCodec.encodeMessage(<Object?>[
          response,
        ]);
      },
    );
  }

  setUp(() {
    mockChannel('checkAvailability', EdgeGenaiAvailability.available);
  });

  tearDown(() {
    mockChannel('checkAvailability', null);
  });

  test('checkAvailability', () async {
    expect(
      await platform.checkAvailability(),
      EdgeGenaiAvailability.available,
    );
  });
}
