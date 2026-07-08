import 'dart:async';

import 'package:edge_ai/edge_ai.dart';
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
  EdgeAiAvailability? _availability;
  EdgeAiDownloadProgress? _downloadProgress;
  String? _generatedContent;
  bool _isGenerating = false;
  final _edgeGenaiPlugin = EdgeAi();
  final _promptController = TextEditingController(
    text: 'Write a 3 sentence story about a magical dog.',
  );

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> initPlatformState() async {
    EdgeAiAvailability availability;
    try {
      availability = await _edgeGenaiPlugin.checkAvailability();
    } on PlatformException {
      availability = EdgeAiAvailability.unavailable;
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

  void _generateContent() {
    setState(() {
      _isGenerating = true;
      _generatedContent = null;
    });

    _edgeGenaiPlugin.generateContent(_promptController.text).listen(
      (chunk) {
        if (!mounted) return;
        setState(() => _generatedContent = chunk);
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _isGenerating = false;
          _generatedContent = 'Failed to generate content: $error';
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _isGenerating = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canDownload = _availability == EdgeAiAvailability.downloadable;
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
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _promptController,
                  decoration: const InputDecoration(labelText: 'Prompt'),
                ),
              ),
              ElevatedButton(
                onPressed: _isGenerating ? null : _generateContent,
                child: Text(_isGenerating ? 'Generating...' : 'Generate'),
              ),
              if (_generatedContent != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(_generatedContent!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
