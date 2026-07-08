import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut:
        'android/src/main/kotlin/com/example/edge_genai/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.example.edge_genai'),
    swiftOut: 'ios/Classes/Messages.g.swift',
    dartPackageName: 'edge_genai',
  ),
)

/// The availability of the on-device generative AI model.
enum EdgeGenaiAvailability {
  /// The model is available and ready to use.
  available,

  /// The device supports the model, but it still needs to download (for
  /// example, Android's Gemini Nano feature is downloadable/downloading).
  downloadable,

  /// The device supports the model, but the user hasn't enabled the
  /// OS-level AI feature yet (for example, Apple Intelligence is turned
  /// off).
  notYetReady,

  /// The device or OS version doesn't support the on-device model.
  unavailable,
}

@HostApi()
abstract class EdgeGenaiHostApi {
  @async
  EdgeGenaiAvailability checkAvailability();
}
