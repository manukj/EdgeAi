import 'dart:async';

import 'package:edge_genai/edge_genai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  EdgeGenaiAvailability? _availability;
  EdgeGenaiDownloadProgress? _downloadProgress;
  final _edgeGenaiPlugin = EdgeGenai();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    EdgeGenaiAvailability availability;
    try {
      availability = await _edgeGenaiPlugin.checkAvailability();
    } on PlatformException {
      availability = EdgeGenaiAvailability.unavailable;
    }

    if (!mounted) return;

    setState(() {
      _availability = availability;
    });
  }

  void _downloadModel() {
    _edgeGenaiPlugin.downloadModel().listen(
      (progress) {
        if (!mounted) return;
        setState(() => _downloadProgress = progress);
      },
      onError: (Object error) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $error')));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canDownload = _availability == EdgeGenaiAvailability.downloadable;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'On-device model availability: ${_availability?.name ?? 'Checking...'}',
              ),
              if (_downloadProgress != null)
                Text(
                  'Download status: ${_downloadProgress!.status.name}'
                  '${_downloadProgress!.bytesDownloaded != null ? ' (${_downloadProgress!.bytesDownloaded} bytes)' : ''}',
                ),
              if (canDownload)
                ElevatedButton(
                  onPressed: _downloadModel,
                  child: const Text('Download model'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
