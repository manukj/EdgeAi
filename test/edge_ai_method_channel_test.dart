import 'package:edge_ai/edge_ai_method_channel.dart';
import 'package:edge_ai/src/messages.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger = TestDefaultBinaryMessengerBinding
      .instance
      .defaultBinaryMessenger;
  MethodChannelEdgeAi platform = MethodChannelEdgeAi();

  void mockChannel(String method, Object? response) {
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.edge_ai.EdgeAiHostApi.$method',
      (ByteData? message) async {
        return EdgeAiHostApi.pigeonChannelCodec.encodeMessage(<Object?>[
          response,
        ]);
      },
    );
  }

  setUp(() {
    mockChannel('checkAvailability', EdgeAiAvailability.available);
  });

  tearDown(() {
    mockChannel('checkAvailability', null);
  });

  test('checkAvailability', () async {
    expect(
      await platform.checkAvailability(),
      EdgeAiAvailability.available,
    );
  });

  test('downloadModel', () async {
    const channelName =
        'dev.flutter.pigeon.edge_ai.EdgeAiEventApi.downloadProgress';
    final progress = EdgeAiDownloadProgress(
      status: EdgeAiDownloadStatus.completed,
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

  test('generateContent', () async {
    const hostChannel =
        'dev.flutter.pigeon.edge_ai.EdgeAiHostApi.startGenerateContent';
    const eventChannel =
        'dev.flutter.pigeon.edge_ai.EdgeAiEventApi.generateContentChunk';

    messenger.setMockMessageHandler(hostChannel, (ByteData? message) async {
      return EdgeAiHostApi.pigeonChannelCodec.encodeMessage(<Object?>[
        null,
      ]);
    });
    messenger.setMockMessageHandler(eventChannel, (ByteData? message) async {
      final call = pigeonMethodCodec.decodeMethodCall(message);
      if (call.method == 'listen') {
        final envelope = pigeonMethodCodec.encodeSuccessEnvelope(
          'a generated response',
        );
        await messenger.handlePlatformMessage(eventChannel, envelope, (_) {});
      }
      return null;
    });

    await expectLater(
      platform.generateContent('a prompt'),
      emits('a generated response'),
    );

    messenger.setMockMessageHandler(hostChannel, null);
    messenger.setMockMessageHandler(eventChannel, null);
  });
}
