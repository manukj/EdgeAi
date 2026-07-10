import Flutter

/// There's nothing for the app to download on iOS — Apple Intelligence is
/// enabled system-wide in Settings — so this immediately reports completion.
class DefaultDownloadProgressStreamHandler: DownloadProgressStreamHandler {
  override func onListen(
    withArguments arguments: Any?, sink: PigeonEventSink<EdgeAiDownloadProgress>
  ) {
    sink.success(EdgeAiDownloadProgress(status: .completed, bytesDownloaded: nil))
    sink.endOfStream()
  }
}
