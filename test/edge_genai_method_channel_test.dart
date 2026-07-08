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
    mockChannel('generateContent', 'a generated response');
  });

  tearDown(() {
    mockChannel('checkAvailability', null);
    mockChannel('generateContent', null);
  });

  test('checkAvailability', () async {
    expect(
      await platform.checkAvailability(),
      EdgeGenaiAvailability.available,
    );
  });

  test('generateContent', () async {
    expect(
      await platform.generateContent('a prompt'),
      'a generated response',
    );
  });

  test('downloadModel', () async {
    const channelName =
        'dev.flutter.pigeon.edge_genai.EdgeGenaiDownloadEventApi.downloadProgress';
    final progress = EdgeGenaiDownloadProgress(
      status: EdgeGenaiDownloadStatus.completed,
    );

    messenger.setMockMessageHandler(channelName, (ByteData? message) async {
      final call = pigeonMethodCodec.decodeMethodCall(message);
      if (call.method == 'listen') {
        final envelope = pigeonMethodCodec.encodeSuccessEnvelope(progress);
        await messenger.handlePlatformMessage(channelName, envelope, (_) {});
      }
      return null;
    });

    await expectLater(platform.downloadModel(), emits(progress));

    messenger.setMockMessageHandler(channelName, null);
  });
}
